# What is this?

`hmap` is a command line tool to work with Clang header maps produced by Xcode.
It is written in Swift.

# How to Get

- [Homebrew](https://brew.sh): `brew install milend/taps/hmap`
- Grab a [release](https://github.com/milend/hmap/releases) from GitHub.
- Build from source. See instructions below.

# How to Use

To print the contents of a header map:

    hmap print ~/path/to/header_map.hmap

To convert the contents of a binary header map to JSON:

    hmap convert ~/header_map.hmap ~/header_map.json

`hmap` deduces file formats by looking at the file extensions of the paths.

You can also use the `convert` command to create a binary header map from JSON:

    hmap convert ~/header_map.json ~/header_map.hmap

You can discover all the commands and options by using `hmap --help`.

# Building from Source

## Xcode

Before building with Xcode, you must download all dependencies by running:

    swift package update

Then generate an Xcode project by running:

    swift package generate-xcodeproj

If you would like to run the included tests, you must *manually* add the test
data files for the test targets as the Swift Package Manager does not yet have
such functionality (tracked by [SR-2866](https://bugs.swift.org/browse/SR-2866)).

- Open the generated Xcode project
- Find the `HeaderMapCoreTests` group in the file hierarchy
- Right-click on it and select "Add files to hmap..."
- Select "TestFile" folder from the file picker
  - Make sure you have selected the "Create groups" option
  - Make sure you have included the files in the `HeaderMapCoreTests` target
- Select the `hmap` project in the file hierarchy
- Select the `HeaderMapCoreTests` target
- Go to "Build Phases"
- Click on the "+" button and then select "New Copy Bundle Resources Phase"
- Click on the "+" in the new phase and select the test files from the previous steps

## Swift Package Manager

If you would like to build from the command line, run:

    swift build

To produce a release build suitable for distribution, run:

    swift build -c release -Xswiftc -static-stdlib
