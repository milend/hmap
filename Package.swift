// swift-tools-version:3.1

import PackageDescription

let package = Package(
  name: "hmap",
  targets: [
    Target(
      name: "hmap",
      dependencies: [
        "HeaderMapCore",
        "HeaderMapFrontend",
      ]
    ),
    Target(
      name: "HeaderMapCore"
    ),
    Target(
      name: "HeaderMapFrontend",
      dependencies: [
        "HeaderMapCore",
      ]
    ),
    Target(
      name: "HeaderMapTesting"
    ),
    Target(
      name: "HeaderMapCoreTests",
      dependencies: [
        "HeaderMapTesting",
        "HeaderMapCore",
      ]
    ),
    Target(
      name: "HeaderMapFrontendTests",
      dependencies: [
        "HeaderMapTesting",
        "HeaderMapFrontend",
      ]
    )
  ],
  dependencies: [
    .Package(
      url: "https://github.com/kylef/Commander.git",
      "0.8.0"
    ),
  ],
  swiftLanguageVersions: [3]
)
