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

class ByteBufferDecoder {
  private let bytes: UnsafePointer<UInt8>
  private var offset: Int
  
  private(set) var byteSwap: Bool
  
  init(bytes: UnsafePointer<UInt8>, byteSwap: Bool) {
    self.bytes = bytes
    self.offset = 0
    self.byteSwap = byteSwap
  }
  
  func advance<T: ByteSwappable & Equatable>() -> T {
    return advance {
      // Needs temporary `result` due to Swift's type inference
      let result: T = castBytes()
      return result.byte(swapped: byteSwap)
    }
  }
  
  func advanceByteSwappable<T: ByteSwappable & Equatable>(expect expectedValue: T) -> T {
    return advance {
      let memoryValue: T = castBytes()
      
      let swappedValue = expectedValue.byte(swapped: true)
      if memoryValue == expectedValue || memoryValue == swappedValue {
        byteSwap = (memoryValue == swappedValue)
        return expectedValue
      }
      
      return memoryValue
    }
  }
  
  fileprivate func castBytes<T>() -> T {
    return bytes.advanced(by: offset).withMemoryRebound(to: T.self, capacity: 1) {
      return $0.pointee
    }
  }
  
  private func advance<T>(_ body: () -> T) -> T {
    let value = body()
    offset += MemoryLayout<T>.size
    return value
  }
}

class ByteBufferEncoder {
  private(set) var bytes = Data()
  
  func encode<T>(_ value: T) {
    var mutableValue = value
    withUnsafeBytes(of: &mutableValue) { (pointer) in
      let valueBytes = Array(pointer[0..<pointer.count])
      bytes.append(contentsOf: valueBytes)
    }
  }
  
  func append(_ data: Data) {
    bytes.append(data)
  }
}
