import Foundation

enum ObjectType {
  case integer
  case string
  case double
  case bool
  case null
  case custom(key: String, code: StructComponents)

  // MARK: Special types
  case uuid
}
