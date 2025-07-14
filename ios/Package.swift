// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MusicKitPlugin",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MusicKitPluginStatic",
            type: .static,
            targets: ["MusicKitPlugin"]
        )
    ],
    dependencies: [
        .package(path: "../../../.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/tauri-2.6.0/mobile/ios-api")
    ],
    targets: [
        .target(
            name: "MusicKitPlugin",
            dependencies: [
                .product(name: "Tauri", package: "ios-api")
            ],
            path: "Sources"
        )
    ]
)
