//
//  StringExtension.swift
//  ObjectMapper
//
//  Created by 王宇 on 2017/6/24.
//

import Foundation

extension String {
    
    var firstLowercased: String {
        var tmp = self
        tmp.replaceSubrange(tmp.startIndex..<tmp.index(after: tmp.startIndex), with: tmp.substring(to: tmp.index(after: tmp.startIndex)).lowercased())
        return tmp
    }
    
    var firstUppercased: String {
        var tmp = self
        tmp.replaceSubrange(tmp.startIndex..<tmp.index(after: tmp.startIndex), with: tmp.substring(to: tmp.index(after: tmp.startIndex)).uppercased())
        return tmp
    }
    
    private func cammelcased() -> String {
        var result = ""
        var transform = false
        for cha in self.characters {
            if cha == "_" {
                transform = true
            } else if transform {
                result.append(String.init(cha).uppercased())
                transform = false
            } else {
                result.append(cha)
            }
        }
        return result
    }
    
    /// long_path -> longPath
    func lowerCamelcased() -> String {
        return cammelcased().firstLowercased
    }
    
    /// long_path -> LongPath
    func upperCamelcased() -> String {
        return cammelcased().firstUppercased
    }
    
    func addIndent() -> String {
        return self.components(separatedBy: "\n").map({ "    "+$0 }).joined(separator: "\n")
    }
}
