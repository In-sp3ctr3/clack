// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "Clack",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .library(name: "ClackCore", targets: ["ClackCore"]),
    .executable(name: "Clack", targets: ["Clack"]),
    .executable(name: "ClackCoreChecks", targets: ["ClackCoreChecks"])
  ],
  targets: [
    .target(
      name: "ClackCore",
      path: "Sources/ClackCore"
    ),
    .executableTarget(
      name: "Clack",
      dependencies: ["ClackCore"],
      path: "Sources/Clack"
    ),
    .executableTarget(
      name: "ClackCoreChecks",
      dependencies: ["ClackCore"],
      path: "Tests/ClackCoreChecks"
    )
  ]
)
