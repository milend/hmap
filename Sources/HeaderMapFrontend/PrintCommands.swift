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

public struct PrintCommandOutput {
  public let text: String
}

public struct FilePrintCommand: ToolCommand {
  public typealias InputType = Input
  public typealias OutputType = PrintCommandOutput
  
  public struct Input {
    public let headerMapFile: URL
    public let argumentPath: String
    public init(headerMapFile: URL, argumentPath: String) {
      self.headerMapFile = headerMapFile
      self.argumentPath = argumentPath
    }
  }
  
  public static func perform(input: Input) throws -> PrintCommandOutput {
    guard let headerMapData = try? Data(contentsOf: input.headerMapFile) else {
      throw PrintCommandError.cannotOpenFile(path: input.argumentPath)
    }
    
    return try MemoryPrintCommand.perform(
      input: MemoryPrintCommand.Input(headerMap: headerMapData)
    )
  }
}

public struct MemoryPrintCommand: ToolCommand {
  public typealias InputType = Input
  public typealias OutputType = PrintCommandOutput
  
  public struct Input {
    public let headerMap: Data
    public init(headerMap: Data) {
      self.headerMap = headerMap
    }
  }
  
  public static func perform(input: Input) throws -> PrintCommandOutput {
    let headerMap = try HeaderMap(data: input.headerMap)
    let entries = headerMap.makeEntryList().sorted { return $0.key < $1.key }
    
    let textLines = entries.flatMap { (entry) -> String? in
      return "\(entry.key) -> \(entry.prefix)\(entry.suffix)"
    }
    
    let output = textLines.joined(separator: "\n")
    return PrintCommandOutput(text: output)
  }
}
