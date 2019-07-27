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

func addPrintCommand(to group: Group) {
  let fileArgument = Argument<[String]>(
    "file",
    description: "Path(s) to header map file"
  )
  
  group.command("print", fileArgument) { (files) in
    for file in files {
        if files.count > 1 {
            Swift.print(file + ":")
        }
        
        do {
            let url = file.expandedFileURL
            let output = try FilePrintCommand.perform(
                input: FilePrintCommand.Input(headerMapFile: url, argumentPath: file)
            )
            let text = output.text.isEmpty ? "Empty header map" : output.text
            Swift.print(text)
        } catch (let error) {
            Swift.print(error.localizedDescription)
            exit(ToolReturnCode.failure.rawValue)
        }
        
        if files.count > 1 {
            Swift.print("")
        }
    }
  }
}
