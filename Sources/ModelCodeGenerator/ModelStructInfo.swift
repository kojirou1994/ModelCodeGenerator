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
    case custom(key: String, code: ModelStructInfo)

    // MARK: Special types
    case uuid
  }
}

public struct PropertyInfo {
  public init(originalName: String, swiftName: String, isKeyTransformed: Bool, property: PropertyType) {
    self.originalName = originalName
    self.swiftName = swiftName
    self.isKeyTransformed = isKeyTransformed
    self.property = property
  }

  public let originalName: String
  public let swiftName: String
  public let isKeyTransformed: Bool
  public let property: PropertyType
}

public struct ModelStructInfo {
  public init(name: String, properties: [PropertyInfo]) {
    self.name = name
    self.properties = properties
  }

  public let name: String
  public let properties: [PropertyInfo]
}
