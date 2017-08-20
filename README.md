# What is this?

`hmap` is a command line tool to work with Clang header maps produced by Xcode.
It is written in Swift.

# How to Get

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

The easiest way to build `hmap` is to use the provided Xcode project.

## Swift Package Manager

If you would like to build from the command line, run:

    swift build

To produce a release build suitable for distribution, run:

    swift build -c release -Xswiftc -static-stdlib

# Contributing

To generate an Xcode project, run:

    swift package generate-xcodeproj

You must manually add the test files for the test targets as the Swift Package
Manager does not yet have such functionality (tracked by
[SR-2866](https://bugs.swift.org/browse/SR-2866)).

If you end up adding new dependencies, remember to run:

    swift package update
