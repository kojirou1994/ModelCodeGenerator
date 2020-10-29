import Foundation
import ModelCodeGenerator

guard CommandLine.arguments.count > 1 else {
  print("No input!")
  print("usage: ModelCodeGeneratorCli json-file ...")
  exit(1)
}

let gen = ModelCodeGenerator(
  options: .init(sortedProperty: true,
                 variableNameStrategy: .convertFromSnakeCase,
                 rootName: "Model", nestedObject: true, variable: true,
                 indentation: .spaces(width: 2), accessControl: .internal,
                 alwaysCodingKeys: true, conformingProtocols: ["Codable"]))

for input in CommandLine.arguments.dropFirst() {
  let inputURL = URL(fileURLWithPath: input)
  let inputFilename = inputURL.deletingPathExtension().lastPathComponent
  let outputURL = inputURL
    .deletingLastPathComponent()
    .appendingPathComponent(inputFilename)
    .appendingPathExtension("swift")

  let code = try gen.generateCode(from: Data(contentsOf: inputURL))
  try code.write(to: outputURL, atomically: true, encoding: .utf8)
}
