//
//  SwiftLintCheck.swift
//  
//
//  Created by Julian Kahnert on 12.01.20.
//

import Files
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import ShellOut

struct SwiftLintCheck: CheckProvider {
    static let type: Language = .swift

    private static let configFilename = ".swiftlint.yml"
    static func run(with config: ChiaConfig, at projectRoot: Folder) throws {

        // validate if swiftlint exists
        try canFindDependency(binary: "swiftlint")

        // get config, if not already exists
        var customSwiftLintConfigUrl: URL?
        if let path = config.swiftLintConfig?.lintingRulesPath {

            // get local or remote config
            guard let url = URL(localOrRemotePath: path),
                let data = try? Data(contentsOf: url) else { throw CheckError.configNotFound }

            let swiftlintConfigUrl = projectRoot.url.appendingPathComponent(configFilename)
            try data.write(to: swiftlintConfigUrl)
            customSwiftLintConfigUrl = swiftlintConfigUrl
        }

        do {
            // cleanup config, if it was downloaded
            defer {
                if let customSwiftLintConfigUrl = customSwiftLintConfigUrl {
                    try? FileManager.default.removeItem(at: customSwiftLintConfigUrl)
                }
            }

            // run swiftlint
            try shellOut(to: "swiftlint", arguments: ["lint", "--quiet", "--reporter json"], at: projectRoot.path)
        } catch {
            throw CheckError.checkFailed(.init(folder: projectRoot, error: error))
        }
    }
}