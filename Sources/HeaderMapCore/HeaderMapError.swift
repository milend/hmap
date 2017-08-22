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

public enum HeaderMapError: LocalizedError {
  case unencodableString
}

public enum HeaderMapParseError: LocalizedError {
  case missingDataHeader
  case unknownFileMagic
  case invalidVersion(expected: UInt16, found: UInt16)
  case reservedValueMismatch(expected: UInt16, found: UInt16)
  case outOfBoundsStringSectionOffset
  case bucketCountNotPowerOf2(found: UInt32)
  case bucketsSectionOverflow
  case invalidStringSectionOffset
}

public enum HeaderMapCreateError: LocalizedError {
  case invalidStringSectionOffset
  case stringWithoutOffsetInTable
  case hashTableFull
  case unhashableKey
}

extension HeaderMapError {
  public var errorDescription: String? {
    switch self {
    case .unencodableString:
      return "String cannot be encoded"
    }
  }
}

extension HeaderMapParseError {
  public var errorDescription: String? {
    switch self {
    case .missingDataHeader:
      return "File is missing a header section"
    case .unknownFileMagic:
      return "File magic is unknown"
    case .invalidVersion(let expected, let found):
      return "Found invalid version \(found), expected \(expected)"
    case .reservedValueMismatch(let expected, let found):
      return "Found invalid reserved value \(found), expected \(expected)"
    case .outOfBoundsStringSectionOffset:
      return "String offset is out of bounds"
    case .bucketCountNotPowerOf2(let buckets):
      return "Bucket count is not a power of 2, found \(buckets) buckets"
    case .bucketsSectionOverflow:
      return "Bucket section overflows"
    case .invalidStringSectionOffset:
      return "The string section offset is invalid"
    }
  }
}

extension HeaderMapCreateError {
  public var errorDescription: String? {
    switch self {
    case .invalidStringSectionOffset:
      return "The string section offset is invalid"
    case .stringWithoutOffsetInTable:
      return "String not present in string section"
    case .hashTableFull:
      return "Header map is full"
    case .unhashableKey:
      return "Key cannot be hashed"
    }
  }
}
