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

public struct JSONHeaderMap {
  public struct Entry {
    public let prefix: String
    public let suffix: String
    
    public init(prefix: String, suffix: String) {
      self.prefix = prefix
      self.suffix = suffix
    }
  }
  
  public let entries: [String: Entry]
  
  public init(entries: [String: Entry]) {
    self.entries = entries
  }
}

// MARK: - Error

enum JSONHeaderMapError: LocalizedError {
  case invalidTopLevelObject
  case invalidEntryObject
  case missingPrefix
  case missingSuffix
}

extension JSONHeaderMapError {
  public var errorDescription: String? {
    switch self {
    case .invalidTopLevelObject:
      return "The top level object in the JSON is invalid."
    case .invalidEntryObject:
      return "The entry object in the JSON is invalid."
    case .missingPrefix:
      return "An entry object does not have a value for the 'prefix' key."
    case .missingSuffix:
      return "An entry object does not have a value for the 'suffix' key."
    }
  }
}

// MARK: - Decode

extension JSONHeaderMap.Entry {
  init(json: Any) throws {
    guard let dict = json as? [String: String] else {
      throw JSONHeaderMapError.invalidEntryObject
    }
    
    guard let prefix = dict[JSONHeaderMapEntryKey.prefix.rawValue] else {
      throw JSONHeaderMapError.missingPrefix
    }
    
    guard let suffix = dict[JSONHeaderMapEntryKey.suffix.rawValue] else {
      throw JSONHeaderMapError.missingSuffix
    }
    
    self.prefix = prefix
    self.suffix = suffix
  }
}

public extension JSONHeaderMap {
  public init(json: Any) throws {
    guard let dict = json as? [String: Any] else {
      throw JSONHeaderMapError.invalidTopLevelObject
    }
    
    self.entries = try dict.dictionaryMap { (key, jsonValue) in
      let entry = try Entry(json: jsonValue)
      return (key, entry)
    }
  }
  
  public init(jsonData: Data) throws {
    let jsonObj = try JSONSerialization.jsonObject(with: jsonData, options: [])
    try self.init(json: jsonObj)
  }
}

// MARK: - Encode

extension JSONHeaderMap.Entry {
  var jsonValue: Any {
    return [
      JSONHeaderMapEntryKey.prefix.rawValue: prefix,
      JSONHeaderMapEntryKey.suffix.rawValue: suffix,
    ]
  }
}

extension JSONHeaderMap {
  public var jsonValue: Any {
    return entries.dictionaryMap { (key, entry) in
      return (key, entry.jsonValue)
    }
  }
  
  public func makeJSONData(prettyPrinted: Bool = true) throws -> Data {
    let opts = prettyPrinted ? JSONSerialization.WritingOptions.prettyPrinted : []
    return try JSONSerialization.data(withJSONObject: jsonValue, options: opts)
  }
}

// MARK: - Keys

enum JSONHeaderMapEntryKey: String {
  case prefix = "prefix"
  case suffix = "suffix"
}

// MARK: - Conversion

public extension HeaderMap.Entry {
  public var jsonEntry: JSONHeaderMap.Entry {
    return JSONHeaderMap.Entry(
      prefix: prefix,
      suffix: suffix
    )
  }
}

extension JSONHeaderMap.Entry: Hashable {
  public var hashValue: Int {
    return prefix.hashValue ^ suffix.hashValue
  }
  
  public static func ==(lhs: JSONHeaderMap.Entry, rhs: JSONHeaderMap.Entry) -> Bool {
    return lhs.prefix == rhs.prefix && lhs.suffix == rhs.suffix
  }
}

public extension HeaderMap {
  public func makeJSONHeaderMap() -> JSONHeaderMap {
    let jsonEntries = makeEntryList().dictionaryMap { (entry) in
      return (entry.key, entry.jsonEntry)
    }
    return JSONHeaderMap(entries: jsonEntries)
  }
  
  public static func binaryDataFrom(jsonHeaderMap: JSONHeaderMap) throws -> Data {
    let hmapEntries = jsonHeaderMap.entries.map { (key, jsonEntry) in
      return HeaderMap.Entry(
        key: key,
        prefix: jsonEntry.prefix,
        suffix: jsonEntry.suffix)
    }
    
    return try HeaderMap.makeBinary(withEntries: hmapEntries)
  }
}

public extension JSONHeaderMap {
  public func makeHeaderMapEntries() -> [HeaderMap.Entry] {
    return entries.map { (key, value) in
      return HeaderMap.Entry(key: key, prefix: value.prefix, suffix: value.suffix)
    }
  }
}
