import XCTest
@testable import OpenAIDoLib

class OpenAIDoTestCase: XCTestCase {
  
  var printed: String!
  var _print: (CustomStringConvertible) -> Void = { _ in }
  var _findApiKey: () -> String? = { nil }
  
  override func setUp() {
    super.setUp()
    
    printed = ""
    self._print = Format.print
    Format.print = { self.printed.append(String(describing: $0)) }
    
    _findApiKey = Config.findApiKey
    Config.findApiKey = { "XYZ" }
  }
  
  override func tearDown() {
    printed = ""
    Format.print = self._print
    
    Config.findApiKey = _findApiKey
  }
}
