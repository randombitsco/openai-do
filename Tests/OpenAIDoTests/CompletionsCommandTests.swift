import ArgumentParser
import CustomDump
import OpenAIBits
import OpenAIBitsTestHelpers
@testable import OpenAIDoLib
import XCTest

final class CompletionsCommandTests: OpenAIDoTestCase {
  
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
    var cmd: CompletionsCommand = try parse("completions", "--model-id", "foobar", "ABC")
    
    XCTAssertEqual(cmd.modelId, "foobar")
    XCTAssertEqual(cmd.prompt, "ABC")
    
    let now = Date()
    
    //    try await cmd.run()
    try await XCTAssertExpectOpenAICall {
      Completions(model: "foobar", prompt: "ABC")
    } returning: {
      Completions.Response(
        id: "success", created: now, model: "foobar",
        choices: [
          .init(text: "DEF", index: 0, finishReason: "length")
        ],
        usage: .init(promptTokens: 2, completionTokens: 2, totalTokens: 4)
      )
    } whileDoing: {
      try await cmd.validate()
      try await cmd.run()
      
      XCTAssertNoDifference(printed, """
      Completions
      ===========
      Model: foobar
      
      Choice #1:
      ----------
      Finish Reason: length
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      DEF
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      
      Tokens Used: Prompt: 2; Completion: 2; Total: 4
      
      """)
    }
  }
  
  func testTwoChoices() async throws {
    var cmd: CompletionsCommand = try parse("completions", "--model-id", "foobar", "-n", "2", "ABC")
    
    XCTAssertEqual(cmd.modelId, "foobar")
    XCTAssertEqual(cmd.n, 2)
    XCTAssertEqual(cmd.prompt, "ABC")
    
    let now = Date()
    
    try await XCTAssertExpectOpenAICall {
      Completions(model: "foobar", prompt: "ABC", n: 2)
    } returning: {
      .init(
        id: "success", created: now, model: "foobar",
        choices: [
          .init(text: "DEF", index: 0, finishReason: "finished"),
          .init(text: "XYZ", index: 1, finishReason: "length"),
        ],
        usage: .init(promptTokens: 1, completionTokens: 2, totalTokens: 3)
      )
    } whileDoing: {
      try await cmd.validate()
      try await cmd.run()
      
      XCTAssertNoDifference(printed, """
      Completions
      ===========
      Model: foobar
      
      Choice #1:
      ----------
      Finish Reason: finished
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      DEF
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      
      Choice #2:
      ----------
      Finish Reason: length
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      XYZ
      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      
      Tokens Used: Prompt: 1; Completion: 2; Total: 3

      """)
    }
  }
}
