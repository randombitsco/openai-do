import XCTest
@testable import OpenAIDoLib

class OpenAIDoTestCase: XCTestCase {
  
  /// Override this to provide a custom API key.
  var apiKey = "XYZ"
  
  var printed: String!
  var _print: (CustomStringConvertible) -> Void = { _ in }
  var _findApiKey: () -> String? = { nil }
  
  override func setUp() {
    super.setUp()
    
    printed = ""
    self._print = Format.print
    Format.print = { self.printed.append(String(describing: $0)) }
    
    _findApiKey = ClientConfig.findApiKey
    ClientConfig.findApiKey = { self.apiKey }
  }
  
  override func tearDown() {
    printed = ""
    Format.print = self._print
    
    ClientConfig.findApiKey = _findApiKey
  }
}
