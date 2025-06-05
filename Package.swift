// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ScrobblerContext",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "ScrobblerContext",
            targets: ["ScrobblerContext"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.7.1"),
        .package(url: "https://github.com/tfmart/ScrobbleKit", from: "2.0.0"),
        .package(url: "https://github.com/httpswift/swifter.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "ScrobblerContext",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "ScrobbleKit", package: "ScrobbleKit"),
                .product(name: "Swifter", package: "Swifter")
            ]),
    ]
)
