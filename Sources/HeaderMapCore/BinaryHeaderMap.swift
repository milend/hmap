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

protocol Packable {
  static var packedSize: Int { get }
}

/**
 This implements v1 of the Clang header map format. For reference, see the
 following files in the Clang source tree:
 - HeaderMap.h
 - HeaderMap.cpp
 - HeaderMapTypes.h
 */
struct BinaryHeaderMap {
  static let StringEncoding: String.Encoding = .utf8
  
  struct DataHeader: Packable {
    typealias MagicType = Magic
    typealias VersionType = Version
    typealias ReservedType = Reserved
    typealias StringSectionOffsetType = UInt32
    typealias StringCountType = UInt32
    typealias BucketCountType = UInt32
    typealias MaxValueLengthType = UInt32
    
    let magic: MagicType
    let version: VersionType
    let reserved: ReservedType
    let stringSectionOffset: StringSectionOffsetType
    let stringCount: StringCountType
    let bucketCount: BucketCountType // Must be power of 2
    let maxValueLength: MaxValueLengthType
    
    static var packedSize: Int {
      return
        MemoryLayout<Magic.RawValue>.size +
          MemoryLayout<Version.RawValue>.size +
          MemoryLayout<Reserved.RawValue>.size +
          MemoryLayout<UInt32>.size +
          MemoryLayout<UInt32>.size +
          MemoryLayout<UInt32>.size +
          MemoryLayout<UInt32>.size;
    }
    
    static func headerPlusBucketsSize(
      bucketCount: DataHeader.BucketCountType) -> Int {
      let bucketsSectionSize = Int(bucketCount) * BinaryHeaderMap.Bucket.packedSize
      return packedSize + bucketsSectionSize
    }
  }
  
  enum Magic: UInt32 {
    case hmap = 0x68_6D_61_70 // 'hmap'
  }
  
  enum Version: UInt16 {
    case version1 = 1
  }
  
  enum Reserved: UInt16 {
    case none = 0
  }
  
  struct Bucket: Packable {
    typealias OffsetType = StringSectionOffset
    
    let key: OffsetType
    let prefix: OffsetType
    let suffix: OffsetType
    
    // MARK: Packable
    
    static var packedSize: Int {
      return OffsetType.packedSize * 3;
    }
  }
  
  struct StringSectionOffset: Packable {
    typealias OffsetType = UInt32
    
    /** Indicates an invalid offset */
    static let Reserved = OffsetType(0)

    let offset: OffsetType
    
    init?(offset: OffsetType) {
      if offset == StringSectionOffset.Reserved {
        // The first byte is reserved and means 'empty'.
        return nil
      }
      
      self.offset = offset
    }
    
    static var packedSize: Int {
      return MemoryLayout<OffsetType>.size;
    }
  }
  
  fileprivate let data: Data
  fileprivate let header: DataHeader
  fileprivate let byteSwap: Bool
  
  public init(data: Data) throws {
    let parseResult = try parseHeaderMap(data: data)
    self.data = data
    self.header = parseResult.dataHeader
    self.byteSwap = parseResult.byteSwap
  }
}

// MARK: - Private

enum ProbeAction<T> {
  case keepProbing
  case stop(value: T?)
}

func probeHashTable<T>(
  bucketCount: BinaryHeaderMap.DataHeader.BucketCountType,
  start: UInt32,
  _ body: (UInt32) -> ProbeAction<T>) -> T? {
  var probeAttempts = BinaryHeaderMap.DataHeader.BucketCountType(0)
  var nextUnboundedBucketIndex = start
  
  while (probeAttempts < bucketCount) {
    // Takes advantage of the fact that buckets are a power of 2
    let nextBucketIndex = nextUnboundedBucketIndex & (bucketCount - 1)
    
    switch body(nextBucketIndex) {
    case .keepProbing:
      break
    case .stop(let value):
      return value
    }
    
    nextUnboundedBucketIndex += 1
    probeAttempts += 1
  }
  
  return nil
}

extension BinaryHeaderMap {
  func getBucket(at index: UInt32) -> Bucket? {
    let offset =
      BinaryHeaderMap.DataHeader.packedSize + Int(index) * Bucket.packedSize
    return withBoundsCheckedBytes(at: offset, count: Bucket.packedSize) {
      (bytesPointer) in
      
      return BinaryHeaderMap.Bucket(bytes: bytesPointer, byteSwap: byteSwap)
    }
  }
  
  var bucketCount: UInt32 {
    return header.bucketCount
  }
  
  func getString(at offset: StringSectionOffset) -> String? {
    let begin = Int(header.stringSectionOffset + offset.offset)
    let preambleSize = DataHeader.headerPlusBucketsSize(
      bucketCount: header.bucketCount)
    guard preambleSize <= begin, begin < data.count  else { return nil }
    
    let nullByteIndex = data.withUnsafeBytes {
      (bytes: UnsafeRawBufferPointer) -> Int? in
      
      for i in begin..<bytes.count {
        if bytes[i] == 0x0 {
          return i
        }
      }
      
      return nil
    }
    
    return nullByteIndex.flatMap { (nullIndex) in
      let stringData = data.subdata(in: begin..<nullIndex)
      return String(data: stringData, encoding: BinaryHeaderMap.StringEncoding)
    }
  }
  
  func withBoundsCheckedBytes<Result>(
    at offset: Int,
    count: Int,
    _ body: (UnsafePointer<UInt8>) throws -> Result?
    ) rethrows -> Result? {
    guard offset + count < data.count else {
      return nil
    }
    
    return try data.withUnsafeBytes { byteBuffer in
      let basePointer = byteBuffer.baseAddress?.bindMemory(to: UInt8.self, capacity: byteBuffer.count)
      let offsetPointer = basePointer?.advanced(by: offset)
      return try offsetPointer.flatMap { try body($0) }
    }
  }
}

// MARK: - Bucket

extension BinaryHeaderMap.Bucket {
  init?(bytes: UnsafePointer<UInt8>, byteSwap: Bool) {
    let decoder = ByteBufferDecoder(bytes: bytes, byteSwap: byteSwap)
    
    guard
      let keyOffset = BinaryHeaderMap.StringSectionOffset(
        offset: decoder.advance()),
      let prefixOffset = BinaryHeaderMap.StringSectionOffset(
        offset: decoder.advance()),
      let suffixOffset = BinaryHeaderMap.StringSectionOffset(
        offset: decoder.advance())
    else { return nil }
    
    
    self.init(
      key: keyOffset,
      prefix: prefixOffset,
      suffix: suffixOffset)
  }
}

// MARK: - Header

struct DataHeaderParseResult {
  let dataHeader: BinaryHeaderMap.DataHeader
  let byteSwap: Bool
}

func parseHeaderMap(data: Data) throws -> DataHeaderParseResult {
  if data.count < BinaryHeaderMap.DataHeader.packedSize {
    throw HeaderMapParseError.missingDataHeader
  }
  
  return try data.withUnsafeBytes { (headerRawBytes: UnsafeRawBufferPointer) in
    typealias H = BinaryHeaderMap.DataHeader
    
    guard let baseRawPointer = headerRawBytes.baseAddress else {
      throw HeaderMapParseError.missingDataHeader
    }
    
    let headerBytes = baseRawPointer.bindMemory(to: UInt8.self, capacity: headerRawBytes.count)
    let decoder = ByteBufferDecoder(bytes: headerBytes, byteSwap: false)
    
    let magicValue = decoder.advanceByteSwappable(
      expect: H.MagicType.hmap.rawValue
    )
    let versionValue: H.VersionType.RawValue = decoder.advance()
    let reseredValue: H.ReservedType.RawValue = decoder.advance()
    let stringSectionOffset: H.StringSectionOffsetType = decoder.advance()
    let stringCount: H.StringCountType = decoder.advance()
    let bucketCount: H.BucketCountType = decoder.advance()
    let maxValueLength: H.MaxValueLengthType = decoder.advance()
    
    guard let magic = H.MagicType(rawValue: magicValue) else {
      throw HeaderMapParseError.unknownFileMagic
    }
    
    let expectedVersion = BinaryHeaderMap.Version.version1
    guard versionValue == expectedVersion.rawValue else {
      throw HeaderMapParseError.invalidVersion(
        expected: expectedVersion.rawValue,
        found: versionValue)
    }
    
    let expectedReserved = BinaryHeaderMap.Reserved.none
    guard reseredValue == expectedReserved.rawValue else {
      throw HeaderMapParseError.reservedValueMismatch(
        expected: expectedReserved.rawValue,
        found: reseredValue)
    }
    
    guard bucketCount == 0 || bucketCount.isPowerOf2 else {
      throw HeaderMapParseError.bucketCountNotPowerOf2(found: bucketCount)
    }
    
    guard Int(stringSectionOffset) <= data.count else {
      throw HeaderMapParseError.outOfBoundsStringSectionOffset
    }
    
    let headerAndBucketsSectionSize = H.headerPlusBucketsSize(bucketCount: bucketCount)
    guard headerAndBucketsSectionSize <= data.count else {
      throw HeaderMapParseError.bucketsSectionOverflow
    }
    
    return DataHeaderParseResult(
      dataHeader: BinaryHeaderMap.DataHeader(
        magic: magic,
        version: expectedVersion,
        reserved: expectedReserved,
        stringSectionOffset: stringSectionOffset,
        stringCount: stringCount,
        bucketCount: bucketCount,
        maxValueLength: maxValueLength),
      byteSwap: decoder.byteSwap)
  }
}

