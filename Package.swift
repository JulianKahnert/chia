// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "chia",
    platforms: [
        .macOS(.v10_12)
    ],
    products: [
        .library(name: "chiaLib", targets: ["chiaLib"]),
        .library(name: "TerminalLog", targets: ["TerminalLog"]),
        .executable(name: "chia", targets: ["chia"])
    ],
    dependencies: [
        .package(url: "https://github.com/johnsundell/shellout.git", from: "2.3.0"),
        .package(url: "https://github.com/JohnSundell/Files", from: "4.2.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.6"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.1"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "0.50700.0"),
        .package(url: "https://github.com/jkandzi/Progress.swift", from: "0.4.0")
    ],
    targets: [
        .target(
            name: "chiaLib",
            dependencies: [
                "ShellOut", "Files", "Yams", "Logging", "SwiftSyntax", "Progress"
            ]
        ),
        .target(
            name: "TerminalLog",
            dependencies: [
                "Logging"
            ]
        ),
        .target(
            name: "chia",
            dependencies: [
                "chiaLib",
                "TerminalLog",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "chiaTests",
            dependencies: ["chiaLib"]
        )
    ]
)
