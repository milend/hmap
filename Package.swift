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
      ]
    ),
    Target(
      name: "HeaderMapFrontendTests",
      dependencies: [
        "HeaderMapTesting",
      ]
    )
  ],
  dependencies: [
    .Package(
      url: "git@github.com:kylef/Commander.git",
      "0.6.0"
    ),
  ],
  swiftLanguageVersions: [3]
)
