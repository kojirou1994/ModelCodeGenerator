public enum Indentation {
  case spaces(width: Int)
  case tab

  var string: String {
    switch self {
    case .spaces(width: let width):
      return .init(repeating: " ", count: width)
    default:
      return "\t"
    }
  }
}
