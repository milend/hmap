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
import HeaderMapTesting

class HeaderMapTests: XCTestCase {
  func testHeaderMapASCIIKeyMatching() throws {
    let entries = [
      HeaderMap.Entry(
        key: "Foo/Foo.h",
        prefix: "/Users/Foo/Source",
        suffix: "Foo.h"),
    ]
    
    let hmap = try HeaderMap(entries: entries)
    
    let fooEntryExactCase = hmap["Foo/Foo.h"]
    XCTAssertNotNil(fooEntryExactCase)
    XCTAssertEqual(fooEntryExactCase, entries.first)
    
    let fooEntryLowercase = hmap["foo/foo.h"]
    XCTAssertNotNil(fooEntryLowercase)
    XCTAssertEqual(fooEntryLowercase, entries.first)
  }
  
  func testHeaderMapUnicodeKeyMatching() throws {
    let lowercaseAUmlaut = "\u{00E4}"
    let uppercaseAUmlaut = "\u{00C4}"
    let entries = [
      HeaderMap.Entry(
        key: uppercaseAUmlaut,
        prefix: "/Users/Foo/Source",
        suffix: uppercaseAUmlaut),
    ]
    
    let hmap = try HeaderMap(entries: entries)
    
    let fooEntryExactCase = hmap[uppercaseAUmlaut]
    XCTAssertNotNil(fooEntryExactCase)
    XCTAssertEqual(fooEntryExactCase, entries.first)
    
    // By definition, lowercasing is ASCII-only
    let fooEntryLowercase = hmap[lowercaseAUmlaut]
    XCTAssertNil(fooEntryLowercase)
  }
  
  func testHeaderMap8BitKeyMatching() throws {
    let eAcute = "\u{E9}"
    let combinedEAcute = "\u{65}\u{301}"
    XCTAssertEqual(eAcute, combinedEAcute)
    
    let entries = [
      HeaderMap.Entry(key: eAcute, prefix: "", suffix: ""),
    ]
    
    let hmap = try HeaderMap(entries: entries)
    
    // By definition, key comparison is not Unicode-aware
    XCTAssertNotNil(hmap[eAcute])
    XCTAssertNil(hmap[combinedEAcute])
  }
  
  func testRealmHeaderMap() throws {
    let hmapData = try loadFile(named: "Realm", extension: "hmap").unwrap()
    let headerMap = try HeaderMap(data: hmapData)
    
    let jsonData = try loadFile(named: "Realm", extension: "json").unwrap()
    let jsonHeaderMap = try JSONHeaderMap(jsonData: jsonData)
    
    let entries = Set<HeaderMap.Entry>(headerMap.makeEntryList())
    let jsonEntries = Set<HeaderMap.Entry>(jsonHeaderMap.makeHeaderMapEntries())
    XCTAssertEqual(entries, jsonEntries)
  }
  
  func testHeaderMapBinaryFormat() throws {
    let entries = Set<HeaderMap.Entry>([
      HeaderMap.Entry(key: "A", prefix: "B", suffix: "C"),
      HeaderMap.Entry(key: "D", prefix: "E", suffix: "F"),
      HeaderMap.Entry(key: "G", prefix: "H", suffix: "I"),
    ])
    
    let hmapBinaryData = try HeaderMap.makeBinary(withEntries: Array(entries))
    let hmap = try HeaderMap(data: hmapBinaryData)
    let hmapEntries = Set<HeaderMap.Entry>(hmap.makeEntryList())
    XCTAssertEqual(entries, hmapEntries)
  }
  
  func testHeaderMapJSONFormat() throws {
    let entries = [
      "A": JSONHeaderMap.Entry(prefix: "B", suffix: "C"),
      "D": JSONHeaderMap.Entry(prefix: "E", suffix: "F"),
    ]
    
    let jsonData = try JSONHeaderMap(entries: entries).makeJSONData()
    let decodedEntries = try JSONHeaderMap(jsonData: jsonData).entries
    XCTAssertEqual(entries, decodedEntries)
  }
  
  func testHeaderMapFormatConversions() throws {
    let entries = [
      "A": JSONHeaderMap.Entry(prefix: "B", suffix: "C"),
      "D": JSONHeaderMap.Entry(prefix: "E", suffix: "F"),
      ]
    
    let jsonHeaderMap = JSONHeaderMap(entries: entries)
    let hmapEntries = jsonHeaderMap.makeHeaderMapEntries()
    let hmap = try HeaderMap(entries: hmapEntries)
    let decodedEntries = hmap.makeJSONHeaderMap().entries
    XCTAssertEqual(entries, decodedEntries)
  }
  
  func testEmptyHeaderMap() throws {
    let hmapBinaryData = try HeaderMap.makeBinary(withEntries: [])
    XCTAssertNotNil(hmapBinaryData)
    let hmap = try HeaderMap(data: hmapBinaryData)
    let hmapEntries = Set<HeaderMap.Entry>(hmap.makeEntryList())
    XCTAssertEqual(Set(), hmapEntries)
  }
}

