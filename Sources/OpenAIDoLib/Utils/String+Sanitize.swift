import Foundation

// see for ressoning on charachrer sets https://superuser.com/a/358861
@usableFromInline
let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
  .union(.newlines)
  .union(.illegalCharacters)
  .union(.controlCharacters)

extension String {
  @inlinable
  func sanitized(replacement: String = "") -> String {
    components(separatedBy: invalidCharacters)
      .filter { !$0.isEmpty }
      .joined(separator: replacement)
  }

  @inlinable
  func whitespaceCondensed() -> String {
    components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")
  }
}
