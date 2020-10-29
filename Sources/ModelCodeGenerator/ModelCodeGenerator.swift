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

  func generateCode(from meta: StructComponents) throws -> String {
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

    public var sortedProperty: Bool
    public var variableNameStrategy: VariableNameStrategy
    public var rootName: String
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

extension ModelCodeGenerator {

  func parseStruct(name: String, value: Any) throws -> StructComponents {
    var properties: [String: Property] = .init()
    if let dic = value as? [String: Any] {
      //            print("It's a dictionary. ")
      try dic.forEach({ (kv) in
        let key = kv.key
//        let transformedKey = key.lowerCamelcased().replacingOccurrences(of: "-", with: "_")
        let value = kv.value
        properties[key] = try parseProperty(value, for: key)
//        codingKeys[transformedKey] = key
      })
    } else if let array = value as? [Any] {
      if array.count == 0 {

      } else {

      }
    } else {
      dump(value)
      fatalError("Unsuppoorted format: \(value)")
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

  private func propertyName(for property: Property) -> String {
    func typeName(for type: ObjectType) -> String {
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
      case .custom(let key, _):
        return nestedObjectName(for: key)
      }
    }

    return property.isArray ? "[\(typeName(for: property.type))]" : typeName(for: property.type)
  }

  private func variableName(for string: String) -> String {
    switch options.variableNameStrategy {
    case .keepOriginal:
      return string
    case .convertFromSnakeCase:
      return string.lowerCamelcased()
    }
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

    let propertyKeys = options.sortedProperty ? meta.properties.keys.sorted() : Array(meta.properties.keys)

    var needGenCodingKeys = false

    propertyKeys.forEach { propertyKey in
      let property = meta.properties[propertyKey].unsafelyUnwrapped

      if !needGenCodingKeys, variableName(for: propertyKey) != propertyKey {
        needGenCodingKeys = true
      }

      writeIndent(count: level + 1)
      writeAccessControl()
      result.append(options.variable ? "var" : "let")
      result.append(" ")
      result.append(variableName(for: propertyKey))
      result.append(": ")
      result.append(propertyName(for: property))

      writeNewLine()

      if case .custom(_, let nestedMeta) = property.type {
        let fixedNestedMeta = StructComponents(name: propertyName(for: property), properties: nestedMeta.properties)
        result.append(writeStructCode(level: level + 1, meta: fixedNestedMeta))
      }
    }

    if (needGenCodingKeys || options.alwaysCodingKeys) && !propertyKeys.isEmpty {
      writeIndent(count: level + 1)
      result.append("private enum CodingKeys: String, CodingKey {")
      writeNewLine()
      propertyKeys.forEach { propertyKey in
        writeIndent(count: level + 2)
        result.append("case \(variableName(for: propertyKey)) = \"\(propertyKey)\"")
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
