// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MusicKitPlugin",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "MusicKitPlugin",
            type: .static,
            targets: ["MusicKitPlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/tauri-apps/tauri-plugin-api", branch: "v2")
    ],
    targets: [
        .target(
            name: "MusicKitPlugin",
            dependencies: [
                .product(name: "Tauri", package: "tauri-plugin-api"),
            ],
            path: "Sources"
        )
    ]
)
