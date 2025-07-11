// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MusicKitPlugin",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MusicKitPlugin",
            type: .static,
            targets: ["MusicKitPlugin"]
        )
    ],
    dependencies: [
        .package(name: "Tauri", path: "../.tauri/tauri-api")
    ],
    targets: [
        .target(
            name: "MusicKitPlugin",
            dependencies: [
                .byName(name: "Tauri")
            ],
            path: "Sources"
        )
    ]
) 