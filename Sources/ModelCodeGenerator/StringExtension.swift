import Foundation

extension String {

  var firstUppercased: String {
    guard let firstC = first?.uppercased() else {
      return ""
    }
    return firstC + dropFirst()
  }

}
