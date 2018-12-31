// swift-tools-version:4.1

import PackageDescription

let package = Package(
  name: "hmap",
  products: [
    .executable(name: "hmap", targets: ["hmap"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/kylef/Commander.git",
      from: "0.8.0"
    ),
  ],
  targets: [
    .target(
      name: "hmap",
      dependencies: [
        "HeaderMapCore",
        "HeaderMapFrontend",
        "Commander",
      ]
    ),
    .target(
      name: "HeaderMapCore"
    ),
    .target(
      name: "HeaderMapFrontend",
      dependencies: [
        "HeaderMapCore",
      ]
    ),
    .testTarget(
      name: "HeaderMapTesting",
      path: "Sources/HeaderMapTesting"
    ),
    .testTarget(
      name: "HeaderMapCoreTests",
      dependencies: [
        "HeaderMapTesting",
        "HeaderMapCore",
      ]
    ),
    .testTarget(
      name: "HeaderMapFrontendTests",
      dependencies: [
        "HeaderMapTesting",
        "HeaderMapFrontend",
      ]
    )
  ],
  swiftLanguageVersions: [4]
)
