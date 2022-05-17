import Foundation

public struct Property {
  public init(isOptional: Bool = false, isArray: Bool = false, type: ObjectType) {
    self.isOptional = isOptional
    self.isArray = isArray
    self.type = type
  }

  public var isOptional: Bool
  public let isArray: Bool
  public let type: ObjectType
}

public struct PropertyMeta {
  public init(originalKey: String, transformedKey: String, isKeyTransformed: Bool, property: Property) {
    self.originalKey = originalKey
    self.transformedKey = transformedKey
    self.isKeyTransformed = isKeyTransformed
    self.property = property
  }

  public let originalKey: String
  public let transformedKey: String
  public let isKeyTransformed: Bool
  public let property: Property
}

public struct StructComponents {
  public init(name: String, properties: [PropertyMeta]) {
    self.name = name
    self.properties = properties
  }

  public let name: String
  public let properties: [PropertyMeta]
}
