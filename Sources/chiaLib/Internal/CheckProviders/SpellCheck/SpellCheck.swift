//
//  SpellCheck.swift
//  
//
//  Created by Julian Kahnert on 03.02.20.
//

import Files
import Progress
import ShellOut
import SwiftSyntax

struct SpellCheck: CheckProvider {

    static let languages: [Language] = [.generic]
    static let dependencies: [String] = []

    static func run(with config: ChiaConfig, at projectRoot: Folder) throws -> [CheckResult] {

        let supportedExtensions = Set(["swift", "md"])
        let ignoredPaths = config.spellCheckConfig?.ignoredPaths ?? []
        let ignoredWords = config.spellCheckConfig?.ignoredWords ?? []

        let spellChecker = createSpellChecker(with: ignoredWords)

        // get files from (including) the last commit until now
        var latestFiles: [String]?  // nil if all files should be used
        if config.spellCheckConfig?.onlyLatestFiles ?? true {
            let terminalOut = try? shellOut(to: "git", arguments: ["diff", "--name-only HEAD~1"])
            latestFiles = terminalOut?.split(separator: "\n").map { String($0) }
        }

        // swiftlint:disable trailing_closure
        let files = projectRoot.files.recursive
            .filter { supportedExtensions.contains($0.extension?.lowercased() ?? "") }
            .filter { file in
                guard let latestFiles = latestFiles else { return true }
                return latestFiles.contains(where: { file.path.contains($0) })
            }
            .filter { file in
                !ignoredPaths.contains(where: { file.path.contains($0) })
            }
        // swiftlint:enable trailing_closure

        var bar = ProgressBar(count: files.count, configuration: [ProgressString(string: "SpellChecker:"), ProgressBarLine(barLength: 50), ProgressPercent()])
        return files.flatMap { file -> [CheckResult] in
            bar.next()
            return analyse(file: file, with: spellChecker)
        }
    }

    private static func analyse(file: File, with spellChecker: SpellChecker) -> [CheckResult] {
        let fileExtension = file.extension?.lowercased()
        switch fileExtension ?? "" {
        case "swift":

            let syntaxTree: SourceFileSyntax
            do {
                syntaxTree = try SyntaxParser.parse(file.url)
            } catch {
                return [CheckResult(severity: .warning, message: "Could not parse SwiftSyntax.", metadata: ["error": .string(error.localizedDescription)])]
            }

            return syntaxTree.tokens.flatMap { $0.leadingTrivia.compactMap({ $0.comment }) }
                .compactMap { spellChecker.findMisspelled(in: $0) }
                .map { .warning(msg: "Misspelled: '\($0)' in '\(file.path)'") }

        case "md":
            guard let fileContent = try? String(contentsOf: file.url) else { return [] }
            let contentWithoutCode = fileContent.components(separatedBy: "```")
                .enumerated()
                .reduce(into: "") { (resultString, tuple) in
                    guard (tuple.offset % 2) == 0 else { return }
                    resultString += tuple.element
                }
            return contentWithoutCode.split(separator: "\n")
                .compactMap { spellChecker.findMisspelled(in: String($0)) }
                .map { .warning(msg: "Misspelled: '\($0)' in '\(file.path)'") }

        default:
            if let fileExtension = fileExtension,
                !fileExtension.isEmpty {
                return [.warning(msg: "No parser found for filetype '\(fileExtension)'")]
            } else {
                return []
            }
        }
    }
}

fileprivate extension TriviaPiece {
    var comment: String? {
        switch self {
        case .spaces,
             .tabs,
             .verticalTabs,
             .formfeeds,
             .newlines,
             .carriageReturns,
             .carriageReturnLineFeeds,
             .garbageText:
            return nil
        case .lineComment(let comment),
             .blockComment(let comment),
             .docLineComment(let comment),
             .docBlockComment(let comment):
            return comment
        }
    }
}
