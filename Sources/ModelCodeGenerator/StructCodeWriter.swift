public struct StructCodeWriter {
  public init(options: StructCodeWriter.Options) {
    self.options = options
  }

  public let options: Options
}

extension StructCodeWriter {
  public struct Options {
    public init(rootName: String, sortedProperty: Bool, nestedObject: Bool, variable: Bool, indentation: Indentation, accessControl: AccessControl, alwaysCodingKeys: Bool, conformingProtocols: [String], variableNameStrategy: VariableNameStrategy, objectNameStrategy: ObjectNameStrategy) {
      self.rootName = rootName
      self.sortedProperty = sortedProperty
      self.nestedObject = nestedObject
      self.variable = variable
      self.indentation = indentation
      self.accessControl = accessControl
      self.alwaysCodingKeys = alwaysCodingKeys
      self.conformingProtocols = conformingProtocols
      self.variableNameStrategy = variableNameStrategy
      self.objectNameStrategy = objectNameStrategy
    }


    public var rootName: String
    public var sortedProperty: Bool
    public var nestedObject: Bool
    public var variable: Bool
    public var indentation: Indentation
    public var accessControl: AccessControl
    public var alwaysCodingKeys: Bool
    public var conformingProtocols: [String]
    public var variableNameStrategy: VariableNameStrategy
    public var objectNameStrategy: ObjectNameStrategy

    var accessControlPrefix: String {
      accessControl.rawValue + " "
    }
  }
}

extension StructCodeWriter {

  public func generateCode(from meta: ModelStructInfo) -> String {
    writeStructCode(level: 0, meta: meta)
  }

  private func writeStructCode(level: Int, meta: ModelStructInfo) -> String {

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

    let properties = options.sortedProperty ? meta.properties.sorted(by: { $0.originalName < $1.originalName }) : meta.properties

    var allCodingKeys = [(String, String)]()
    var allNestedTypeNames = [String]()

    properties.forEach { property in

      let swiftName = options.variableNameStrategy.genSwiftName(fromJSONName: property.originalName)
      allCodingKeys.append((swiftName, property.originalName))

      writeIndent(count: level + 1)
      writeAccessControl()
      result.append(options.variable ? "var" : "let")
      result.append(" ")
      result.append(swiftName)
      result.append(": ")
      if property.property.isArray {
        result.append("[")
      }
      result.append(propertyName(for: property.property.type, key: swiftName))
      if property.property.isArray {
        result.append("]")
      }
      if property.property.isOptional {
        result.append("?")
      }

      writeNewLine()

      if case .customObject(let nestedMeta) = property.property.type {
        let fixedNestedMeta = ModelStructInfo(name: propertyName(for: property.property.type, key: swiftName), properties: nestedMeta.properties)
        if allNestedTypeNames.contains(fixedNestedMeta.name) {
          fatalError("duplicated nested object name: \(fixedNestedMeta.name)!")
        }
        allNestedTypeNames.append(fixedNestedMeta.name)
        result.append(writeStructCode(level: level + 1, meta: fixedNestedMeta))
      }
    }

    let needGenCodingKeys = allCodingKeys.contains(where: { $0.0 != $0.1 })

    if needGenCodingKeys || options.alwaysCodingKeys {
      writeIndent(count: level + 1)
      result.append("private enum CodingKeys: String, CodingKey {")
      writeNewLine()
      allCodingKeys.forEach { key in
        writeIndent(count: level + 2)
        // TODO: original key escaped
        result.append("case \(key.1)")
        if key.0 != key.1 {
          result.append(" = \"\(key.0)\"")
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

  private func propertyName(for type: PropertyType.BaseType, key: String) -> String {
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
    case .customObject:
      return options.objectNameStrategy.genSwiftName(fromJSONKey: key)
    }
  }
}

public enum VariableNameStrategy: String {
  case original
  case camelFromSnakeCase

  func genSwiftName(fromJSONName string: String) -> String {

    let cleaned = string.filter { !$0.isSymbol || $0 == "_" }

    if self == .camelFromSnakeCase {
      return cleaned.lowerCamelcased()
    }
    if cleaned.isEmpty || cleaned.allSatisfy({$0.isSymbol}) {
      return "fixInvalidJSONKey"
    }
    if cleaned.first!.isNumber {
      return "_" + cleaned
    }
    return cleaned
  }
}

public enum ObjectNameStrategy: String {
  case uppercase
  case camelFromSnakeCase

  func genSwiftName(fromJSONKey string: String) -> String {
    var structName: String
    switch self {
    case .uppercase:
      structName = string.uppercased()
    case .camelFromSnakeCase:
      structName = string.upperCamelcased()
    }
    if structName == string {
      structName = "_" + structName
    }
    return structName
  }
}
