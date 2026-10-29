// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "magic_device",
  platforms: [
    .macOS("10.15")
  ],
  products: [
    .library(name: "magic-device", targets: ["magic_device"])
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "magic_device",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ]
    )
  ]
)
