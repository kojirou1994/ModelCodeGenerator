import Foundation

public struct PropertyType {
  public init(isOptional: Bool = false, isArray: Bool = false, type: BaseType) {
    self.isOptional = isOptional
    self.isArray = isArray
    self.type = type
  }

  public var isOptional: Bool
  public let isArray: Bool
  public let type: BaseType

  public enum BaseType {
    case integer
    case string
    case double
    case bool
    case null
    case forcedName(String)
    case customObject(ModelStructInfo)
    case stringEnum([String])

    // MARK: Special types
    case uuid
  }
}

public struct PropertyInfo {
  public init(originalName: String, property: PropertyType) {
    self.originalName = originalName
    self.property = property
  }

  public let originalName: String
  public let property: PropertyType
}

public enum ModelStructInfo {
  case `struct`(properties: [PropertyInfo])
  case `enum`(rawValueType: String, rawValues: [String])
}
