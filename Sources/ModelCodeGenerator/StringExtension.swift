import Foundation

extension String {

  var firstLowercased: String {
    guard let firstC = first?.lowercased() else {
      return ""
    }
    return firstC + dropFirst()
  }

  var firstUppercased: String {
    guard let firstC = first?.uppercased() else {
      return ""
    }
    return firstC + dropFirst()
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
}
