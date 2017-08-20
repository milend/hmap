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

extension String {
  func clangLowercasedBytes() throws -> Data {
    guard let charBytes = data(using: BinaryHeaderMap.StringEncoding) else {
      throw HeaderMapError.unencodableString
    }
    
    let lowercasedBytes = charBytes.map { $0.asciiLowercased() }
    return Data(bytes: lowercasedBytes)
  }
  
  func clangLowercased() throws -> String? {
    return try String(data: clangLowercasedBytes(), encoding: BinaryHeaderMap.StringEncoding)
  }
  
  var headerMapHash: UInt32? {
    guard
      let characterBytes = try? clangLowercasedBytes()
    else { return nil }
    
    return characterBytes.withUnsafeBytes {
      (charBlockPointer: UnsafePointer<UInt8>) -> UInt32 in
      
      var result = UInt32(0)
      for i in 0 ..< characterBytes.count {
        let charPointer = charBlockPointer.advanced(by: i)
        result += UInt32(charPointer.pointee) * 13
      }
      return result
    }
  }
}

fileprivate extension UInt8 {
  func asciiLowercased() -> UInt8 {
    let isUppercase = (65 <= self && self <= 90)
    return self + (isUppercase ? 32 : 0)
  }
}
