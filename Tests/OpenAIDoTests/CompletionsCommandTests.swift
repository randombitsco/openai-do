import ArgumentParser
@testable import OpenAIDoLib
import XCTest

final class CompletionsCommandTests: XCTestCase {
  
  var printed: String!
  
  override func setUpWithError() throws {
    Config.findApiKey = { "XYZ" }
    Format.print = { self.printed.append(String(describing: $0)) }
    printed = ""
  }
  
  override func tearDownWithError() throws {
    Config.findApiKey = Config.findApiKeyInEnvironment
    printed = ""
  }

  func testSimple() async throws {
    let cmd: CompletionsCommand = try parse("completions", "--model-id", "foobar", "ABC")
    
    XCTAssertEqual(cmd.modelId, "foobar")
    XCTAssertEqual(cmd.prompt, "ABC")

//    try await cmd.run()
  }
}
