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

      func parseNormalType(_ value: JSONValue, rootObjectName: String, isRequired: Bool) throws -> PropertyType {
        let type = value["type"]!.string!
        var isRequired = isRequired
        let minLength = value["minLength"]?.uint ?? 0
        var baseType: PropertyType.BaseType = .null
        switch type {
        case "array":
          let array = value["items"]!
          precondition(array.isObject)
          let type = try parseNormalType(array, rootObjectName: rootObjectName, isRequired: isRequired)
          return .init(isOptional: !isRequired, isArray: true, type: type.type)
        case "object":
          baseType = try .customObject(ModelStructInfo.struct(properties: parseObjectProperties(value)))
        case "integer":
          if preferUnsignedInteger, value["minimum"]?.uint == 0 {
            baseType = .forcedName("UInt")
            break
          }
          baseType = .integer
        case "string":
          if let enums = value["enum"] {
            assert(enums.isArray)
            if let enumArray = enums.array {
              let values = enumArray.map(\.string!)
              baseType = .stringEnum(values)
              break
            }
          }
          baseType = .string
        case "boolean":
          baseType = .bool
        default:
          fatalError("\(type) not supported")
        }

        return .init(isOptional: !isRequired, type: baseType)
      }

      func parseObjectProperties(_ value: JSONValue) throws -> [PropertyInfo] {
//        let additionalProperties = value["additionalProperties"]?.bool
        let object = value["properties"]!.object!
        let requiredProperties = Set(value["required"]?.array!.map(\.string!) ?? [])
        return try object.map { (key, value) in
          let key = key.string!
          let property = try parseNormalType(value, rootObjectName: key, isRequired: requiredProperties.contains(key))
          return .init(originalName: key, property: property)
        }
      }

      let meta = try ModelStructInfo.struct(properties: parseObjectProperties(root))

      let code = writerOptions.writer.generateCode(from: meta)
      try code.write(to: outputURL, atomically: true, encoding: .utf8)
    }
  }
}
