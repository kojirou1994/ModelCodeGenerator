// swift-tools-version: 5.6

import PackageDescription

let package = Package(
  name: "ModelCodeGenerator",
  products: [
    .library(name: "ModelCodeGenerator", targets: ["ModelCodeGenerator"]),
    .executable(name: "ModelCodeGeneratorCli", targets: ["ModelCodeGeneratorCli"]),
  ],
  dependencies: [
    .package(url: "https://github.com/kojirou1994/YYJSONEncoder.git", branch: "main"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "ModelCodeGenerator",
      dependencies: []),
    .executableTarget(
      name: "ModelCodeGeneratorCli",
      dependencies: [
        "ModelCodeGenerator",
        .product(name: "JSON", package: "YYJSONEncoder"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]),
    .testTarget(
      name: "ModelCodeGeneratorTests",
      dependencies: ["ModelCodeGenerator"]),
  ]
)
