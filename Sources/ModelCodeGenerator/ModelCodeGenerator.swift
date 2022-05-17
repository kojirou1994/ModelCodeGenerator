import Foundation

public struct ModelCodeGenerator {
  public init(options: GeneratorOptions) {
    self.options = options
  }

  public var options: GeneratorOptions

  public func generateCode(from string: String) throws -> String {
    try generateCode(from: Data(string.utf8))
  }

  public func generateCode(from data: Data) throws -> String {
    try autoreleasepool {
      let json = try JSONSerialization.jsonObject(with: data, options: [])
      let meta = try parseStruct(name: options.rootName, value: json)

      return try generateCode(from: meta)
    }
  }

  public func generateCode(from meta: StructComponents) throws -> String {
    writeStructCode(level: 0, meta: meta)
  }
}

extension ModelCodeGenerator {
  public struct GeneratorOptions {
    public init(sortedProperty: Bool, variableNameStrategy: ModelCodeGenerator.GeneratorOptions.VariableNameStrategy, rootName: String, nestedObject: Bool, variable: Bool, indentation: Indentation, accessControl: AccessControl, alwaysCodingKeys: Bool, conformingProtocols: [String]) {
      self.sortedProperty = sortedProperty
      self.variableNameStrategy = variableNameStrategy
      self.rootName = rootName
      self.nestedObject = nestedObject
      self.variable = variable
      self.indentation = indentation
      self.accessControl = accessControl
      self.alwaysCodingKeys = alwaysCodingKeys
      self.conformingProtocols = conformingProtocols
    }

    public enum VariableNameStrategy {
      case keepOriginal
      case convertFromSnakeCase
    }

    public var rootName: String
    public var sortedProperty: Bool
    public var variableNameStrategy: VariableNameStrategy
    public var nestedObject: Bool
    public var variable: Bool
    public var indentation: Indentation
    public var accessControl: AccessControl
    public var alwaysCodingKeys: Bool
    public var conformingProtocols: [String]
    public var detectUUID: Bool = true

    var accessControlPrefix: String {
      accessControl.rawValue + " "
    }
  }
}

enum ModelCodeGeneratorError: Error {
  case emptyArray
  case wrongRootType
}

extension ModelCodeGenerator {

  func parseStruct(name: String, value: Any) throws -> StructComponents {
    var properties = [PropertyMeta]()

    func parse(dictionary: [String: Any]) throws {
      let propertyKeys = options.sortedProperty ? dictionary.keys.sorted() : Array(dictionary.keys)
      try propertyKeys.forEach { originalKey in
        var transformedKey = variableName(for: originalKey)
        while properties.contains(where: {$0.transformedKey == transformedKey}) {
          transformedKey.append("_")
        }

        let value = dictionary[originalKey].unsafelyUnwrapped

        properties.append(.init(originalKey: originalKey,
                                transformedKey: transformedKey,
                                isKeyTransformed: originalKey != transformedKey,
                                property: try parseProperty(value, for: originalKey)))
      }
    }

    if let dic = value as? [String: Any] {
      try parse(dictionary: dic)
    } else if let array = value as? [Any] {
      if let firstElement = array.first {
        return try parseStruct(name: name, value: firstElement)
      } else {
        throw ModelCodeGeneratorError.emptyArray
      }
    } else {
      assertionFailure("Unsuppoorted format: \(value)")
      throw ModelCodeGeneratorError.wrongRootType
    }

    return .init(name: name, properties: properties)

  }

  func parseProperty(_ value: Any, for key: String) throws -> Property {
    switch value {
    case let string as NSString:
      if options.detectUUID, UUID(uuidString: string as String) != nil {
        return .init(type: .uuid)
      }
      return .init(type: .string)
    case let number as NSNumber:
      if number.isCFBoolean {
        return .init(type: .bool)
      } else {
        switch number {
        case _ as Int:
          return .init(type: .integer)
        case _ as Double :
          return .init(type: .double)
        default:
          assertionFailure("The number is not int or float: \(number)")
          return .init(type: .double)
        }
      }
    case _ as NSNull:
      return .init(type: .null)
    case let arr as NSArray:
      if arr.count == 0 {
        return .init(isArray: true, type: .string)
      } else {
        return try .init(isArray: true, type: parseProperty(arr[0], for: key).type)
      }
    default:
      assert(value is NSDictionary)
      return try .init(type: .custom(key: key, code: parseStruct(name: key, value: value)))
    }
  }

  private func propertyName(for type: ObjectType) -> String {
    switch type {
    case .bool:
      return "Bool"
    case .double:
      return "Double"
    case .integer:
      return "Int"
    case .null:
      return "NSNull"
    case .string:
      return "String"
    case .uuid:
      return "UUID"
    case .forcedName(let name):
      return name
    case .custom(let key, _):
      return nestedObjectName(for: key)
    }
  }

  private func variableName(for string: String) -> String {

    var result = string.filter { !$0.isSymbol || $0 == "_" }

    if options.variableNameStrategy == .convertFromSnakeCase {
      result = result.lowerCamelcased()
    }
    if result.isEmpty || result.allSatisfy({$0.isSymbol}) {
      result = "fixInvalidJSONKey"
    }
    if result.first!.isNumber {
      result = "_" + result
    }
    return result
  }

  private func nestedObjectName(for key: String) -> String {
    var structName: String
    switch options.variableNameStrategy {
    case .keepOriginal:
      structName = key.firstUppercased
    case .convertFromSnakeCase:
      structName = key.upperCamelcased()
    }
    if structName == key {
      structName = "_" + structName
    }
    return structName
  }

  private func writeStructCode(level: Int, meta: StructComponents) -> String {

    var result = ""

    func writeIndent(count: Int = level) {
      result.append(String(repeating: options.indentation.string, count: count))
    }
    func writeAccessControl() {
      result.append(options.accessControlPrefix)
    }
    func writeNewLine() {
      result.append("\n")
    }

    writeIndent()
    writeAccessControl()
    result.append("struct \(meta.name): \(Set(options.conformingProtocols).sorted().joined(separator: ", ")) {\n")

    meta.properties.forEach { property in

      writeIndent(count: level + 1)
      writeAccessControl()
      result.append(options.variable ? "var" : "let")
      result.append(" ")
      result.append(property.transformedKey)
      result.append(": ")
      if property.property.isArray {
        result.append("[")
      }
      result.append(propertyName(for: property.property.type))
      if property.property.isArray {
        result.append("]")
      }
      if property.property.isOptional {
        result.append("?")
      }

      writeNewLine()

      if case .custom(_, let nestedMeta) = property.property.type {
        let fixedNestedMeta = StructComponents(name: propertyName(for: property.property.type), properties: nestedMeta.properties)
        result.append(writeStructCode(level: level + 1, meta: fixedNestedMeta))
      }
    }

    let needGenCodingKeys = meta.properties.contains { $0.isKeyTransformed }

    if (needGenCodingKeys || options.alwaysCodingKeys) && !meta.properties.isEmpty {
      writeIndent(count: level + 1)
      result.append("private enum CodingKeys: String, CodingKey {")
      writeNewLine()
      meta.properties.forEach { property in
        writeIndent(count: level + 2)
        // TODO: original key escaped
        result.append("case \(property.transformedKey)")
        if property.isKeyTransformed {
          result.append(" = \"\(property.originalKey)\"")
        }
        writeNewLine()
      }
      writeIndent(count: level + 1)
      result.append("}")
      writeNewLine()
    }

    writeIndent()
    result.append("}")
    writeNewLine()
    return result
  }
}
