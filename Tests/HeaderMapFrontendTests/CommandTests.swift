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

import XCTest
import HeaderMapCore
import HeaderMapFrontend
import HeaderMapTesting

class CommandTests: XCTestCase {
  func testReadCommand() throws {
    let hmapData = try loadFile(named: "map", extension: "hmap").unwrap()
    let input = MemoryPrintCommand.Input(headerMap: hmapData)
    let output = try MemoryPrintCommand.perform(input: input)
    
    let printoutData = try loadFile(named: "map", extension: "txt").unwrap()
    let printoutText = try String(data: printoutData, encoding: .utf8).unwrap()
    XCTAssertEqual(output.text, printoutText)
  }
  
  func testConvertCommand() throws {
    let hmapData = try loadFile(named: "map", extension: "hmap").unwrap()
    let input = MemoryConvertCommand.Input(
      data: hmapData,
      from: .hmap,
      to: .json)
    
    let output = try MemoryConvertCommand.perform(input: input)
    let jsonFileData = try loadFile(named: "map", extension: "json").unwrap()
    
    let jsonHeaderFromFile = try JSONHeaderMap(jsonData: jsonFileData)
    let jsonHeaderFromCommand = try JSONHeaderMap(jsonData: output.data)

    XCTAssertEqual(jsonHeaderFromFile.entries, jsonHeaderFromCommand.entries)
  }
}
