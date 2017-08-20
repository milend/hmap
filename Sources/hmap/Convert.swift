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

import Commander
import Foundation
import HeaderMapFrontend

func addConvertCommand(to group: Group) {
  let sourceFileArgument = Argument<String>(
    "source_file",
    description: "Path to the file to be converted"
  )
  let destFileArgument = Argument<String>(
    "dest_file",
    description: "Path to the converted file"
  )
  
  group.command("convert", sourceFileArgument, destFileArgument) {
    (from, to) in
    
    do {
      let fromUrl = URL(fileURLWithPath: from)
      let fromFile = try FileConvertCommand.Input.TypedFile(url: fromUrl)
      
      let toUrl = URL(fileURLWithPath: to)
      let toFile = try FileConvertCommand.Input.TypedFile(url: toUrl)
      
      let input = FileConvertCommand.Input(from: fromFile, to: toFile)
      try FileConvertCommand.perform(input: input)
    } catch (let error) {
      Swift.print(error.localizedDescription)
      exit(ToolReturnCode.failure.rawValue)
    }
  }
}
