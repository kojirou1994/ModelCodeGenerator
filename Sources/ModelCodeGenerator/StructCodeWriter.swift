import KwiftUtility

public struct StructCodeWriter {
  public init(options: StructCodeWriter.Options) {
    self.options = options
  }

  public let options: Options
}

let internalKeywords: Set = [
  "true", "false",
]

extension StructCodeWriter {
  public struct Options {
    public init(rootName: String, sortedProperty: Bool, nestedObject: Bool, variable: Bool, indentation: Indentation, accessControl: AccessControl, alwaysCodingKeys: Bool, conformingProtocols: [String], variableNameStrategy: VariableNameStrategy, objectNameStrategy: ObjectNameStrategy, dropObjectPluralSuffix: Bool) {
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
      self.dropObjectPluralSuffix = dropObjectPluralSuffix
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
    public var dropObjectPluralSuffix: Bool

    var accessControlPrefix: String {
      accessControl.rawValue + " "
    }
  }
}

extension StructCodeWriter {

  public func generateCode(from meta: ModelStructInfo) -> String {
    writeCode(level: 0, meta: meta, name: options.rootName)
  }

  private func writeCode(level: Int, meta: ModelStructInfo, name: String) -> String {

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
    func writePropertyName(_ name: String) {
      let w = internalKeywords.contains(name)
      if w {
      result.append("`")
      }
      result.append(name)
      if w {
      result.append("`")
      }
    }

    writeIndent()
    writeAccessControl()
    switch meta {
    case .struct: result.append("struct")
    case .enum:   result.append("enum")
    }

    var allProtocols = [String]()
    switch meta {
    case .enum(rawValueType: let type, _):
      allProtocols.append(type)
    default: break
    }
    allProtocols.append(contentsOf: options.conformingProtocols)
    result.append(" \(name)")
    if !allProtocols.isEmpty {
      result.append(": ")
      result.append(allProtocols.joined(separator: ", "))
      result.append(" {")
      writeNewLine()
    }

    switch meta {
    case .struct(let properties):
      let properties = options.sortedProperty ? properties.sorted(by: { $0.originalName < $1.originalName }) : properties
      var allCodingKeys = [(swiftName: String, originalName: String)]()
      var allNestedTypeNames = [String]()

      properties.forEach { property in

        let swiftName = options.variableNameStrategy.genSwiftName(fromJSONName: property.originalName)
        allCodingKeys.append((swiftName, property.originalName))

        writeIndent(count: level + 1)
        writeAccessControl()
        result.append(options.variable ? "var" : "let")
        result.append(" ")
        writePropertyName(swiftName)
        result.append(": ")
        if property.property.isArray {
          result.append("[")
        }
        result.append(propertyName(for: property.property, key: swiftName))
        if property.property.isArray {
          result.append("]")
        }
        if property.property.isOptional {
          result.append("?")
        }

        writeNewLine()

        let nestedTypeName = propertyName(for: property.property, key: swiftName)
        switch property.property.type {
        case .customObject(let nestedMeta):
          if allNestedTypeNames.contains(nestedTypeName) {
            fatalError("duplicated nested object name: \(nestedTypeName)!")
          }
          allNestedTypeNames.append(nestedTypeName)
          result.append(writeCode(level: level+1, meta: nestedMeta, name: nestedTypeName))
        case .stringEnum(let rawValues):
          result.append(writeCode(level: level+1, meta: .enum(rawValueType: "String", rawValues: rawValues), name: nestedTypeName))
        default: break
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
          result.append("case \(key.swiftName)")
          if key.0 != key.1 {
            result.append(" = \"\(key.originalName)\"")
          }
          writeNewLine()
        }
        writeIndent(count: level + 1)
        result.append("}")
        writeNewLine()
      }
    case .enum(_, let rawValues):
      rawValues.forEach { rawValue in
        let swiftName = options.variableNameStrategy.genSwiftName(fromJSONName: rawValue)
        writeIndent(count: level + 1)
        result.append("case ")
        writePropertyName(swiftName)
        if swiftName != rawValue {
          result.append(" = ")
          result.append("\"\(rawValue)\"")
        }
        writeNewLine()
      }
    }

    writeIndent()
    result.append("}")
    writeNewLine()
    return result
  }

  private func propertyName(for type: PropertyType, key: String) -> String {
    switch type.type {
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
    case .customObject, .stringEnum:
      return options.genSwiftName(fromJSONKey: key, isArray: type.isArray)
    }
  }
}

public enum VariableNameStrategy: String {
  case original
  case camelFromSnakeCase

  func genSwiftName(fromJSONName string: String) -> String {

    let cleaned = string.filter { !$0.isSymbol || $0 == "_" }

    if self == .camelFromSnakeCase {
      return SnakeCaseConvert.convertFromSnakeCase(cleaned)
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
}

extension StructCodeWriter.Options {
  func genSwiftName(fromJSONKey string: String, isArray: Bool) -> String {
    var structName: String
    switch objectNameStrategy {
    case .uppercase:
      structName = string.uppercased()
    case .camelFromSnakeCase:
      structName = SnakeCaseConvert.convertFromSnakeCase(string).firstUppercased()
    }
    if structName == string {
      structName = "_" + structName
    }
    if isArray, dropObjectPluralSuffix {
      let map = [
        "ties": "ty",
        "s": "",
      ]
      if let matched = map.first(where: { structName.hasSuffix($0.key) }) {
        structName.removeLast(matched.key.count)
        structName.append(matched.value)
      }
    }
    return structName
  }
}
