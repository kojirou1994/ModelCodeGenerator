import Foundation
import ModelCodeGenerator
import ArgumentParser
import JSON

struct JSONSchema: ParsableCommand {

  @OptionGroup
  var writerOptions: CodeWriterOptions

  @Argument
  var inputs: [String]

  func run() throws {

    // MARK: advanced options
    let preferUnsignedInteger: Bool = true

    for input in inputs {
      let inputURL = URL(fileURLWithPath: input)
      let inputFilename = inputURL.deletingPathExtension().lastPathComponent
      let outputURL = inputURL
        .deletingLastPathComponent()
        .appendingPathComponent(inputFilename)
        .appendingPathExtension("swift")

      let json = try JSON.read(path: input)
      let root = json.root
      if let scheme = root["$schema"]?.string {
        print("scheme: \(scheme)")
      }

      precondition(root["type"]!.string! == "object")

      func parseNormalType(_ value: JSONValue, rootObjectName: String) throws -> PropertyType {
        let type = value["type"]!.string!
        switch type {
        case "array":
          let array = value["items"]!
          precondition(array.isObject)
          let type = try parseNormalType(array, rootObjectName: rootObjectName)
          return .init(isArray: true, type: type.type)
        case "object":
          return try .init(type: .customObject(ModelStructInfo(name: rootObjectName, properties: parseObjectProperties(value))))
        case "integer":
          if preferUnsignedInteger, value["minimum"]?.int == 0 {
            return .init(type: .forcedName("UInt"))
          }
          return .init(type: .integer)
        case "string":
          return .init(type: .string)
        case "boolean":
          return .init(type: .bool)
        default:
          fatalError("\(type) not supported")
        }
      }

      func parseObjectProperties(_ value: JSONValue) throws -> [PropertyInfo] {
//        let additionalProperties = value["additionalProperties"]?.bool
        let object = value["properties"]!.object!
        let requiredProperties = value["required"]?.array!.map(\.string!) ?? []
        return try object.map { (key, value) in
          var property = try parseNormalType(value, rootObjectName: key.string!.uppercased())
          property.isOptional = !requiredProperties.contains(key.string!)
          return .init(originalName: key.string!, property: property)
        }
      }

      let meta = try ModelStructInfo(name: writerOptions.rootName, properties: parseObjectProperties(root))

      let code = writerOptions.writer.generateCode(from: meta)
      try code.write(to: outputURL, atomically: true, encoding: .utf8)
    }
  }
}
