import Foundation
import ModelCodeGenerator
import ArgumentParser

struct JSONFile: ParsableCommand {

  @OptionGroup
  var writerOptions: CodeWriterOptions

  @Argument
  var inputs: [String]

  func run() throws {

    for input in inputs {
      let inputURL = URL(fileURLWithPath: input)
      let inputFilename = inputURL.deletingPathExtension().lastPathComponent
      let outputURL = inputURL
        .deletingLastPathComponent()
        .appendingPathComponent(inputFilename)
        .appendingPathExtension("swift")

      let parser = JSONModelParser(options: .init())
      let info = try parser.parseModel(from: Data(contentsOf: inputURL))

      let code = writerOptions.writer.generateCode(from: info)
      try code.write(to: outputURL, atomically: true, encoding: .utf8)
    }
  }
}
