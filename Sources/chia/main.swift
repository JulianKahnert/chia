// swiftlint:disable line_length

import ArgumentParser
import chiaLib
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Logging
import TerminalLog
import Files

struct ChiaOptions: ParsableArguments {
    @Flag(name: .long, help: "Returns a project language for a given root folder. All checks will be skipped.")
    var languageDetection = false
    
    @Flag(name: [.customLong("xcode"), .customShort("x")], help: "Returns output Xcode formatted.")
    var xcodeOutput = false

    @Option(name: [.customLong("config"), .customShort("c")], help: "Path to the Config file (local or remote), e.g. 'https://PATH/TO/.chia.yml'")
    var configPath: String?
}

// parse command line arguments
let options = ChiaOptions.parseOrExit()

do {
    // bootstrap logging
    LoggingSystem.bootstrap { input in
        return TerminalLog(xcodeOutput: options.xcodeOutput)
    }

    let logger = Logger(label: "chia-cli")
    
    // setup chia
    var chia = Chia(logger: logger)

    // try to get a config path from the CLI - use default config otherwise
    if let configPath = options.configPath {

        guard let url = URL(localOrRemotePath: configPath) else {
                logger.error("Could not find a config at:\n\(configPath)")
                exit(1)
        }
        try chia.setConfig(from: url)
    } else {

        // no url is provided - use the default one
        try chia.setConfig(from: nil)
    }

    if options.languageDetection {
        if let detectedLanguage = chia.detectProjectLanguage() {
            logger.info("Language: \(detectedLanguage)")
        } else {
            logger.warning("No language detected.")
        }
    } else {
        try chia.runChecks()
    }
} catch {
    let logger = Logger(label: "chia-cli")
    logger.error("\(error.localizedDescription)")
    exit(1)
}
exit(0)
