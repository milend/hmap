// MIT License
//
// Copyright (c) 2017 Milen Dzhumerov
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation
import HeaderMapCore

// MARK: - Command Definitions

public struct MemoryConvertCommand {
  public struct Input {
    public let data: Data
    public let from: HeaderMapFileFormat
    public let to: HeaderMapFileFormat
    
    public init(data: Data,
                from: HeaderMapFileFormat,
                to: HeaderMapFileFormat) {
      self.data = data
      self.from = from
      self.to = to
    }
  }
  
  public struct Output {
    public let data: Data
  }
  
  public enum Error: LocalizedError {
    case sameFormat(format: HeaderMapFileFormat)
  }
}

public struct FileConvertCommand {
  public struct Input {
    public struct TypedFile {
      public let url: URL
      public let format: HeaderMapFileFormat
      
      public init(url: URL) throws {
        self.url = url
        self.format = try url.resolveHeaderMapFormat()
      }
    }
    
    public let from: TypedFile
    public let to: TypedFile
    
    public init(from: TypedFile, to: TypedFile) {
      self.from = from
      self.to = to
    }
  }
  
  public enum Error: LocalizedError {
    case unknownFormat(url: URL)
  }
}

// MARK: - Memory Convert

extension MemoryConvertCommand: ToolCommand {
  public typealias InputType = Input
  public typealias OutputType = Output
  
  public static func perform(input: Input) throws -> Output {
    switch (input.from, input.to) {
    case (.hmap, .json):
      let hmap = try HeaderMap(data: input.data)
      let jsonHmap = hmap.makeJSONHeaderMap()
      let jsonData = try jsonHmap.makeJSONData(prettyPrinted: true)
      return Output(data: jsonData)
      
    case (.json, .hmap):
      let jsonHmap = try JSONHeaderMap(jsonData: input.data)
      let hmapData = try HeaderMap.binaryDataFrom(jsonHeaderMap: jsonHmap)
      return Output(data: hmapData)
      
    case (.json, .json),
         (.hmap, .hmap):
      throw MemoryConvertCommand.Error.sameFormat(format: input.from)
    }
  }
}

// MARK: - File Convert

extension FileConvertCommand: ToolCommand {
  public typealias InputType = Input
  public typealias OutputType = Void
  
  public static func perform(input: Input) throws -> Void {
    let fromData = try Data(contentsOf: input.from.url)
    let outputData = try MemoryConvertCommand.perform(
      input: MemoryConvertCommand.Input(
        data: fromData, from: input.from.format, to: input.to.format)
    )
    
    try outputData.data.write(to: input.to.url, options: [.atomic])
  }
}

fileprivate extension URL {
  func resolveHeaderMapFormat() throws -> HeaderMapFileFormat {
    switch pathExtension {
    case "json":
      return .json
    case "hmap":
      return .hmap
    default:
      throw FileConvertCommand.Error.unknownFormat(url: self)
    }
  }
}

// MARK: - Error Descriptions

extension MemoryConvertCommand.Error {
  public var errorDescription: String? {
    switch self {
    case .sameFormat(_):
      return "Must specify different formats for conversion."
    }
  }
}

extension FileConvertCommand.Error {
  public var errorDescription: String? {
    switch self {
    case .unknownFormat(let url):
      return "The format of the file at path \(url.path) could not be determined."
    }
  }
}
