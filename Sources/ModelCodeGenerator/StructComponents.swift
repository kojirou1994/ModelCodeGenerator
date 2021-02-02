import Foundation

struct Property {
  init(isArray: Bool = false, type: ObjectType) {
    self.isArray = isArray
    self.type = type
  }

  let isArray: Bool
  let type: ObjectType
}

struct PropertyMeta {
  let originalKey: String
  let transformedKey: String
  let isKeyTransformed: Bool
  let property: Property
}

struct StructComponents {
  let name: String
  let properties: [PropertyMeta]

}
