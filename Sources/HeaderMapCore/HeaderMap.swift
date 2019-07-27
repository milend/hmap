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

public struct HeaderMap {
  public struct Entry {
    public let key: String
    public let prefix: String
    public let suffix: String
    
    public init(key: String, prefix: String, suffix: String) {
      self.key = key
      self.prefix = prefix
      self.suffix = suffix
    }
  }
  
  public init(data: Data) throws {
    let binaryHeader = try BinaryHeaderMap(data: data)
    self.entries = try makeIndexedEntries(from: binaryHeader.makeEntries())
  }
  
  public init(entries: [Entry]) throws {
    self.entries = try makeIndexedEntries(from: entries)
  }
  
  fileprivate typealias EntryIndex = [Data: Entry]
  fileprivate let entries: EntryIndex
}

// MARK: - Private

fileprivate extension BinaryHeaderMap {
  func makeEntries() -> [HeaderMap.Entry] {
    return (0..<bucketCount).compactMap { (index) in
      return getBucket(at: index).flatMap { (bucket) in
        return makeEntry(forBucket: bucket)
      }
    }
  }
  
  func makeEntry(forBucket bucket: Bucket) -> HeaderMap.Entry? {
    guard
      let key = getString(at: bucket.key),
      let prefix = getString(at: bucket.prefix),
      let suffix = getString(at: bucket.suffix)
      else { return nil }
    
    return HeaderMap.Entry(
      key: key,
      prefix: prefix,
      suffix: suffix)
  }
}

fileprivate func makeIndexedEntries(from entries: [HeaderMap.Entry]) throws -> HeaderMap.EntryIndex {
  return try sanitize(headerEntries: entries).dictionaryMap { (entry) in
    let lowercasedBytes = try entry.key.clangLowercasedBytes()
    return (lowercasedBytes, entry)
  }
}

// MARK: - Public

extension HeaderMap {
  public subscript(key: String) -> HeaderMap.Entry? {
    guard let lowercasedBytes = try? key.clangLowercasedBytes() else {
      return nil
    }
    
    return entries[lowercasedBytes]
  }
  
  public func makeEntryList() -> [HeaderMap.Entry] {
    return entries.map { (_, entry) in
      return entry
    }
  }
}

extension HeaderMap {
  public static func makeBinary(withEntries entries: [Entry]) throws -> Data {
    return try makeHeaderMapBinaryData(withEntries: entries)
  }
}

extension HeaderMap.Entry: Hashable {
  public var hashValue: Int {
    return key.hashValue ^ prefix.hashValue ^ suffix.hashValue
  }
  
  public static func ==(lhs: HeaderMap.Entry, rhs: HeaderMap.Entry) -> Bool {
    return lhs.key == rhs.key &&
      lhs.prefix == rhs.prefix &&
      lhs.suffix == rhs.suffix
  }
}

