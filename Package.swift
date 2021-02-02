// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "ModelCodeGenerator",
  products: [
    .library(name: "ModelCodeGenerator", targets: ["ModelCodeGenerator"])
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "ModelCodeGenerator",
      dependencies: []),
    .target(
      name: "ModelCodeGeneratorCli",
      dependencies: ["ModelCodeGenerator"]),
    .testTarget(
      name: "ModelCodeGeneratorTests",
      dependencies: ["ModelCodeGenerator"]),
  ]
)
