public enum AccessControl: String, CaseIterable, Identifiable {
  case `public`
//  case `private`
  case `internal`
  case `fileprivate`

  public var id: Self { self }
}
