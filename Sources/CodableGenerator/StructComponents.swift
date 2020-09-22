import Foundation

struct GeneratorOptions {
  /*
   sortedProperties
   convertToCamelCase
   */
}

indirect enum ObjectType {

  case integer
  case string
  case double
  case bool
  case null
  case custom(key: String, code: StructComponents)
  case array(type: ObjectType)

  init(key: String, value: Any) {
    switch value {
    case _ as String:
      self = .string
    case let number as NSNumber:
      if number.className == "__NSCFBoolean" {
        self = .bool
      } else {
        switch number {
        case _ as Int:
          self = .integer
        case _ as Double :
          self = .double
        default:
          print("The number is not int or float: \(number)")
          fatalError()
        }
      }
    case _ as NSNull:
      self = .null
    case let arr as [Any]:
      if arr.count == 0 {
        self = .array(type: .string)
      } else {
        let t = ObjectType(key: key, value: arr[0])
        self = .array(type: t)
      }
    default:
      let structName = key.upperCamelcased()
      var str = StructComponents(name: structName)
      str.parse(json: value)
      self = .custom(key: structName, code: str)
    }
  }

  var type: String {
    switch self {
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
    case .array(let type):
      return "[\(type.type)]"
    case .custom(let key, _):
      return key
    }
  }

  func generateCode(variable: String) -> String {
    var result = ""
    switch self {
    case .custom(key: _, code: let components):
      result.append("\n\(components.structCode.addIndent())\n")
    case .array(type: let element):
      switch element {
      case .custom(key: _, code: let components):
        result.append("\n\(components.structCode.addIndent())\n")
      default:
        break
      }
    default:
      break
    }
    return result + "\n    var \(variable): \(self.type)"
  }
}

struct StructComponents {

  var name: String
  var variables = [String: ObjectType]()
  var codingKeys = [String: String]()
  var protocols = Set<String>(arrayLiteral: "Codable")

  init(name: String) {
    self.name = name
  }

  mutating func parse(json: Any) {
    if let dic = json as? [String: Any] {
      //            print("It's a dictionary. ")
      dic.forEach({ (kv) in
        let key = kv.key
        let transformedKey = key.lowerCamelcased().replacingOccurrences(of: "-", with: "_")
        let value = kv.value
        self.variables[transformedKey] = ObjectType.init(key: key, value: value)
        self.codingKeys[transformedKey] = key
      })
    } else if let array = json as? [Any] {
      if array.count == 0 {

      } else {

      }
    } else {
      print("Unsuppoorted format: \(json)")
      dump(json)
      exit(1)
    }
  }

  private var codingKeysCode: String {
    if codingKeys.count == 0 {
      return ""
    } else {
      return """
      private enum CodingKeys: String, CodingKey {
      \(codingKeys.map {kv -> String in
        if kv.key == kv.value {
          return "    case \(kv.key)"
        } else {
          return "    case \(kv.key) = \"\(kv.value)\""
        }
      }.joined(separator: "\n"))
      }
      """
    }
  }
  let sorted = true
  private var variablesCode: String {
    let keys: [String]
    if sorted {
      keys = variables.keys.sorted()
    } else {
      keys = Array(variables.keys)
    }
    var code = ""
    for key in keys {
      code += variables[key]!.generateCode(variable: key)
    }
    return code
  }

  public var structCode: String {
    """
    public struct \(name): \(protocols.joined(separator: ", ")) {
    \(variablesCode)
    \(codingKeysCode)
    
    }
    """
  }


}
