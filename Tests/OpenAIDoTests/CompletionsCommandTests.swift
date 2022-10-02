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
      Completions.Create(model: "foobar", prompt: "ABC")
    } returning: {
      Completion(
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
      Completions.Create(model: "foobar", prompt: "ABC", n: 2)
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
  
  func testToJSON() async throws {
    var cmd: CompletionsCommand = try parse("completions", "--model-id", "foobar", "-n", "2", "--to-json", "--pretty", "ABC")
    
    XCTAssertEqual(cmd.modelId, "foobar")
    XCTAssertEqual(cmd.n, 2)
    XCTAssertEqual(cmd.prompt, "ABC")
    XCTAssertEqual(cmd.toJson.enabled, true)
    
    let now = Date()
    
    try await XCTAssertExpectOpenAICall {
      Completions.Create(model: "foobar", prompt: "ABC", n: 2)
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
      {
        "choices" : [
          {
            "finish_reason" : "finished",
            "index" : 0,
            "text" : "DEF"
          },
          {
            "finish_reason" : "length",
            "index" : 1,
            "text" : "XYZ"
          }
        ],
        "created" : \(Int(now.timeIntervalSince1970)),
        "id" : "success",
        "model" : "foobar",
        "usage" : {
          "completion_tokens" : 2,
          "prompt_tokens" : 1,
          "total_tokens" : 3
        }
      }
      
      """)
    }
  }
  
  func testAllArguments() async throws {
    var cmd: CompletionsCommand = try parse(
      "completions",
      "--model-id", "foobar",
      "--suffix", "foo",
      "--max-tokens", "100",
      "--temperature", "0.5",
      "--top-p", "0.6",
      "-n", "2",
      "--logprobs", "1",
      "--echo",
      "--stop", "bar",
      "--presence-penalty", "2.0",
      "--frequency-penalty", "-2.0",
      "--best-of", "3",
      "--logit-bias", "50256:-100",
      "--user", "jblogs",
      "ABC"
    )
    
    XCTAssertEqual(cmd.modelId, "foobar")
    XCTAssertEqual(cmd.prompt, "ABC")
    
    let now = Date()
    
    //    try await cmd.run()
    try await XCTAssertExpectOpenAICall {
      Completions.Create(
        model: "foobar",
        prompt: "ABC",
        suffix: "foo",
        maxTokens: 100,
        temperature: 0.5,
        topP: 0.6,
        n: 2,
//        stream: false,
        logprobs: 1,
        echo: true,
        stop: ["bar"],
        presencePenalty: 2.0,
        frequencyPenalty: -2.0,
        bestOf: 3,
        logitBias: [50256: -100],
        user: "jblogs"
      )
    } returning: {
      Completion(
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
}
