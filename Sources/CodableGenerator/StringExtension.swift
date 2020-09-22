import Foundation

extension String {
    
    var firstLowercased: String {
        if isEmpty {
            return ""
        }
        return first!.lowercased() + dropFirst()
    }
    
    var firstUppercased: String {
        if isEmpty {
            return ""
        }
        return first!.uppercased() + dropFirst()
    }
    
    private func cammelcased() -> String {
        var result = ""
        var transform = false
        for cha in self {
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
        cammelcased().firstLowercased
    }
    
    /// long_path -> LongPath
    func upperCamelcased() -> String {
        cammelcased().firstUppercased
    }
    
    func addIndent() -> String {
        self.components(separatedBy: "\n").map({ "    "+$0 }).joined(separator: "\n")
    }
}
