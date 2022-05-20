import ArgumentParser
import ModelCodeGenerator

extension AccessControl: ExpressibleByArgument {}
extension VariableNameStrategy: ExpressibleByArgument {}
extension ObjectNameStrategy: ExpressibleByArgument {}

struct CodeWriterOptions: ParsableArguments {

  @Option
  var rootName: String = "Model"

  @Flag
  var sortedProperty: Bool = false

//  @Flag
//  var nestedObject: Bool = true

  @Flag
  var variable: Bool = false

//  @Option
//  var indentation: Indentation

  @Option
  var accessControl: AccessControl = .internal

  @Flag
  var alwaysCodingKeys: Bool = false

  @Option
  var conformingProtocols: [String] = ["Codable"]

  @Option
  var variableNameStrategy: VariableNameStrategy = .camelFromSnakeCase

  @Option
  var objectNameStrategy: ObjectNameStrategy = .camelFromSnakeCase

  var writer: StructCodeWriter {
    .init(options: .init(rootName: rootName, sortedProperty: sortedProperty, nestedObject: true, variable: variable, indentation: .spaces(width: 2), accessControl: accessControl, alwaysCodingKeys: alwaysCodingKeys, conformingProtocols: conformingProtocols, variableNameStrategy: variableNameStrategy, objectNameStrategy: objectNameStrategy))
  }
}
