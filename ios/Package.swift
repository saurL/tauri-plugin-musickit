// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Copyright 2019-2023 Tauri Programme within The Commons Conservancy
// SPDX-License-Identifier: Apache-2.0
// SPDX-License-Identifier: MIT

import PackageDescription

let package = Package(
  name: "tauri-plugin-musickit",
  platforms: [
    .iOS(.v15)
  ],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "tauri-plugin-musickit",
      type: .static,
      targets: ["tauri-plugin-musickit"])
  ],
  dependencies: [
    .package(name: "Tauri", path: "../.tauri/tauri-api")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "tauri-plugin-musickit",
      dependencies: [
        .byName(name: "Tauri")
      ],
      path: "Sources",
      linkerSettings: [
        .linkedFramework("MusicKit")
      ]
    )
  ]
)
