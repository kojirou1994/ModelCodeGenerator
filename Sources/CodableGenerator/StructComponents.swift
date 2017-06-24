//
//  StructComponents.swift
//  ObjectMapper
//
//  Created by 王宇 on 2017/6/24.
//

import Foundation

indirect enum ObjectType {
    
    case integer
    case string
    case double
    case bool
    case null
    case custom(key: String, code: StructComponents)
    case array(type: ObjectType)
    
    init(key: String, value: Any) {
        if let _ = value as? String {
            self = .string
        } else if let _ = value as? Bool {
            self = .bool
        } else if let _ = value as? Int {
            self = .integer
        } else if let _ = value as? Double {
            self = .double
        } else if let _ = value as? NSNull {
            self = .null
        } else if let arr = value as? [Any], arr.count > 0 {
            let t = ObjectType(key: key, value: arr[0])
            self = .array(type: t)
        } else {
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
            result.append("\n\(components.code.addIndent())\n")
        case .array(type: let element):
            switch element {
            case .custom(key: _, code: let components):
                result.append("\n\(components.code.addIndent())\n")
            default:
                break
            }
        default:
            break
        }
        return result + "\n    var \(variable): \(self.type)\n"
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
                let transformedKey = key.lowerCamelcased()
                let value = kv.value
                self.variables[transformedKey] = ObjectType.init(key: key, value: value)
                self.codingKeys[transformedKey] = key
            })
        } else {
            print("JSON Array not supported!")
            exit(1)
        }
    }
    
    var code: String {
        let vars = variables.reduce("") { (result, kv) -> String in
            return result + kv.value.generateCode(variable: kv.key)
        }
        
        let keys: String
        if codingKeys.count == 0 {
            keys = ""
        } else {
            keys = """
                private enum CodingKeys: String, CodingKey {
                \(codingKeys.map {kv -> String in
                if kv.key == kv.value {
                return "    case \(kv.key)"
                } else {
                return "    case \(kv.key) = \"\(kv.value)\""
                }
                }.joined(separator: "\n"))
                }
                """.addIndent()
        }
        
        return """
        struct \(name): \(protocols.joined(separator: ", ")) {
        \(vars)
        \(keys)
        
        }
        """
    }
    
    
}
