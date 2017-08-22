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

func makeHeaderMapBinaryData(
  withEntries unsafeEntries: [HeaderMap.Entry]) throws -> Data {
  
  let safeEntries = sanitize(headerEntries: unsafeEntries)
  let allStrings = Set(safeEntries.flatMap { [$0.key, $0.prefix, $0.suffix] })
  let stringSection = try makeStringSection(allStrings: allStrings)
  let bucketSection = try makeBucketSection(
    forEntries: safeEntries,
    stringSection: stringSection)
  
  let maxValueLength = safeEntries.max(by: { lhs, rhs in
    return lhs.valueLength < rhs.valueLength
  }).map { $0.valueLength } ?? 0
  
  let headerSize = BinaryHeaderMap.DataHeader.packedSize
  let stringSectionOffset = headerSize + bucketSection.data.count
  
  let header = BinaryHeaderMap.DataHeader(
    magic: .hmap,
    version: .version1,
    reserved: .none,
    stringSectionOffset: UInt32(stringSectionOffset),
    stringCount: UInt32(stringSection.stringCount),
    bucketCount: UInt32(bucketSection.bucketCount),
    maxValueLength: UInt32(maxValueLength))
  
  let encoder = ByteBufferEncoder()
  encoder.encode(header.magic.rawValue)
  encoder.encode(header.version.rawValue)
  encoder.encode(header.reserved.rawValue)
  encoder.encode(header.stringSectionOffset)
  encoder.encode(header.stringCount)
  encoder.encode(header.bucketCount)
  encoder.encode(header.maxValueLength)
  encoder.append(bucketSection.data)
  encoder.append(stringSection.data)
  
  return encoder.bytes
}

fileprivate struct BucketSection {
  let data: Data
  let bucketCount: Int
}

fileprivate struct StringSection {
  let data: Data
  let stringCount: Int
  let offsets: [String: BinaryHeaderMap.StringSectionOffset]
}

fileprivate func makeStringSection(
  allStrings: Set<String>) throws -> StringSection {
  
  var buffer = Data()
  var offsets = Dictionary<String, BinaryHeaderMap.StringSectionOffset>()
  
  if !allStrings.isEmpty {
    buffer.append(UInt8(BinaryHeaderMap.StringSectionOffset.Reserved))
  }
  
  for string in allStrings {
    guard let stringBytes = string.data(using: BinaryHeaderMap.StringEncoding) else {
      throw HeaderMapError.unencodableString
    }
    
    let bufferCount = UInt32(buffer.count)
    guard
      let offset = BinaryHeaderMap.StringSectionOffset(offset: bufferCount)
    else {
      throw HeaderMapCreateError.invalidStringSectionOffset
    }
    
    offsets[string] = offset
    buffer.append(stringBytes)
    buffer.append(0x0) // NUL character
  }
  
  return StringSection(
    data: buffer,
    stringCount: allStrings.count,
    offsets: offsets)
}

fileprivate func isBucketSlotEmpty(
  bytePointer: UnsafeMutablePointer<UInt8>,
  index: UInt32) -> Bool {
  
  let slotOffset = Int(index) * BinaryHeaderMap.Bucket.packedSize
  let slotPointer = bytePointer.advanced(by: slotOffset)
  return slotPointer.withMemoryRebound(
    to: BinaryHeaderMap.StringSectionOffset.OffsetType.self,
    capacity: 1) {
    return $0.pointee == BinaryHeaderMap.StringSectionOffset.Reserved
  }
}

fileprivate func writeTo<T>(bytePointer: UnsafeMutablePointer<UInt8>, value: T) {
  var mutableValue = value
  withUnsafeBytes(of: &mutableValue) { (pointer) in
    let valueBytes = Array(pointer[0..<pointer.count])
    for (index, byte) in valueBytes.enumerated() {
      bytePointer.advanced(by: index).pointee = byte
    }
  }
}

fileprivate func makeBucketSection(
  forEntries entries: [HeaderMap.Entry],
  stringSection: StringSection) throws -> BucketSection {
  
  let bucketCount = numberOfBuckets(forEntryCount: entries.count)
  var bytes = Data(count: bucketCount * BinaryHeaderMap.Bucket.packedSize)
  try bytes.withUnsafeMutableBytes {
    (bytePointer: UnsafeMutablePointer<UInt8>) in
    
    try entries.forEach { (entry) in
      guard let keyHash = entry.key.headerMapHash else {
        throw HeaderMapCreateError.unhashableKey
      }
      
      guard
        let keyOffset = stringSection.offsets[entry.key],
        let prefixOffset = stringSection.offsets[entry.prefix],
        let suffixOffset = stringSection.offsets[entry.suffix]
      else {
        throw HeaderMapCreateError.stringWithoutOffsetInTable
      }
      
      let maybeEmptySlotIndex: UInt32? = probeHashTable(
        bucketCount: UInt32(bucketCount),
        start: keyHash) { (probeIndex) in
        if isBucketSlotEmpty(bytePointer: bytePointer, index: probeIndex) {
          return .stop(value: probeIndex)
        }
        
        return .keepProbing
      }
      
      guard let emptySlotIndex = maybeEmptySlotIndex else {
        throw HeaderMapCreateError.hashTableFull
      }
      
      let slotPointer = bytePointer.advanced(
        by: Int(emptySlotIndex) * BinaryHeaderMap.Bucket.packedSize)
      let fieldSize = MemoryLayout<BinaryHeaderMap.Bucket.OffsetType>.size
      
      writeTo(
        bytePointer: slotPointer,
        value: keyOffset.offset)
      writeTo(
        bytePointer: slotPointer.advanced(by: fieldSize),
        value: prefixOffset.offset)
      writeTo(
        bytePointer: slotPointer.advanced(by: 2 * fieldSize),
        value: suffixOffset.offset)
    }
  }
  
  return BucketSection(data: bytes, bucketCount: bucketCount)
}

fileprivate func numberOfBuckets(forEntryCount entryCount: Int) -> Int {
  let minimumSlots = Int(ceil(Double(entryCount) * (1.0 / 0.7)))
  var bucketCount = 1
  while bucketCount < minimumSlots {
    bucketCount <<= 1
  }
  
  return bucketCount
}

func sanitize(headerEntries entries: [HeaderMap.Entry]) -> [HeaderMap.Entry] {
  var allKeys = Set<String>()
  return entries.flatMap { (entry) in
    guard !allKeys.contains(entry.key) else { return nil }
    allKeys.insert(entry.key)
    return entry
  }
}

fileprivate extension HeaderMap.Entry {
  var valueLength: Int {
    return prefix.lengthOfBytes(using: BinaryHeaderMap.StringEncoding) +
      suffix.lengthOfBytes(using: BinaryHeaderMap.StringEncoding)
  }
}
