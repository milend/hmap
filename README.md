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

## Swift Package Manager

If you would like to build from the command line, run:

    swift build

To produce a release build suitable for distribution, run:

    swift build -c release -Xswiftc -static-stdlib

To verify that all tests pass, run:

    swift test