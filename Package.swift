// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "openai-do",
    platforms: [
      .macOS(.v12),
    ],
    products: [
        .executable(name: "openai-do", targets: ["OpenAIDo"])
    ],
    dependencies: [
        .package(url: "https://github.com/randombitsco/swift-openai-bits", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "OpenAIDo",
            dependencies: [
              .product(name: "OpenAIBits", package: "swift-openai-bits"),
              .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]),
    ]
)
