import Foundation

public struct JSONModelParser {
  public init(options: Options) {
    self.options = options
  }

  public var options: Options

  public func parseModel(from string: String) throws -> ModelStructInfo {
    try parseModel(from: Data(string.utf8))
  }

  public func parseModel(from data: Data) throws -> ModelStructInfo {
    try autoreleasepool {
      let json = try JSONSerialization.jsonObject(with: data, options: [])
      return try parseStruct(name: "", value: json)
    }
  }

}

extension JSONModelParser {
  public struct Options {
    public init(detectUUID: Bool = true) {
      self.detectUUID = detectUUID
    }

    public var detectUUID: Bool = true
  }
}

enum ModelCodeGeneratorError: Error {
  case emptyArray
  case wrongRootType
}

extension JSONModelParser {

  func parseStruct(name: String, value: Any) throws -> ModelStructInfo {
    var properties = [PropertyInfo]()

    func parse(dictionary: [String: Any]) throws {
      try dictionary.forEach { (originalKey, value) in
        properties.append(.init(originalName: originalKey,
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

  func parseProperty(_ value: Any, for key: String) throws -> PropertyType {
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
      return try .init(type: .customObject(parseStruct(name: key, value: value)))
    }
  }

}
