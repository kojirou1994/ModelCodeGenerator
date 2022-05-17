import Foundation
import ModelCodeGenerator
import ArgumentParser

let gen = ModelCodeGenerator(
  options: .init(sortedProperty: true,
                 variableNameStrategy: .convertFromSnakeCase,
                 rootName: "Model", nestedObject: true, variable: true,
                 indentation: .spaces(width: 2), accessControl: .internal,
                 alwaysCodingKeys: true, conformingProtocols: ["Codable"]))

struct JSONFile: ParsableCommand {
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

      let code = try gen.generateCode(from: Data(contentsOf: inputURL))
      try code.write(to: outputURL, atomically: true, encoding: .utf8)
    }
  }
}
