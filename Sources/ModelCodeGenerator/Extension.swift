import Foundation

extension NSNumber {
  @_transparent
  var isCFBoolean: Bool {
    CFGetTypeID(self) == CFBooleanGetTypeID()
  }
}
