import ArgumentParser
import CustomDump
import OpenAIBits
import OpenAIBitsTestHelpers
@testable import OpenAIDoLib
import XCTest

final class CompletionsCommandTests: OpenAIDoTestCase {
  
  func testSimple() async throws {
    var cmd: CompletionsCreateCommand = try parse("completions", "create", "--model-id", "foobar", "ABC")
        
    XCTAssertEqual(cmd.config.findApiKey(), apiKey)
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
          .init(text: "DEF", index: 0, finishReason: .length)
        ],
        usage: .init(promptTokens: 2, completionTokens: 2, totalTokens: 4)
      )
    } whileDoing: {
      try await cmd.validate()
      try await cmd.run()

      XCTAssertNoDifference(printed, """
      Create Completions
      Model: foobar
      Text:
      \(Format.border("DEF".count))
      DEF
      \(Format.border("DEF".count))
      Finish Reason: length
      
      Tokens Used: Prompt: 2; Completion: 2; Total: 4
      
      """)
    }
  }
  
  func testBlankText() async throws {
    var cmd: CompletionsCreateCommand = try parse("completions", "create", "--model-id", "foobar", "ABC")
        
    XCTAssertEqual(cmd.config.findApiKey(), apiKey)
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
          .init(text: "", index: 0, finishReason: .stop)
        ],
        usage: .init(promptTokens: 2, completionTokens: 2, totalTokens: 4)
      )
    } whileDoing: {
      try await cmd.validate()
      try await cmd.run()

      XCTAssertNoDifference(printed, """
      Create Completions
      Model: foobar
      Text:
      \(Format.border("".count))
      
      \(Format.border("".count))
      Finish Reason: stop
      
      Tokens Used: Prompt: 2; Completion: 2; Total: 4
      
      """)
    }
  }
  
  func testTwoChoices() async throws {
    var cmd: CompletionsCreateCommand = try parse("completions", "create", "--model-id", "foobar", "-n", "2", "ABC")
    
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
          .init(text: "DEF", index: 0, finishReason: .stop),
          .init(text: "XYZ", index: 1, finishReason: .length),
        ],
        usage: .init(promptTokens: 1, completionTokens: 2, totalTokens: 3)
      )
    } whileDoing: {
      try await cmd.validate()
      try await cmd.run()
      
      XCTAssertNoDifference(printed, """
      Create Completions
      Model: foobar
      Choices:
      #1:
        Text:
        \(Format.border("DEF".count))
        DEF
        \(Format.border("DEF".count))
        Finish Reason: stop
      #2:
        Text:
        \(Format.border("XYZ".count))
        XYZ
        \(Format.border("XYZ".count))
        Finish Reason: length
      
      Tokens Used: Prompt: 1; Completion: 2; Total: 3

      """)
    }
  }
  
  func testToJSON() async throws {
    var cmd: CompletionsCreateCommand = try parse("completions", "create", "--model-id", "foobar", "-n", "2", "--to-json", "--pretty", "ABC")
    
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
          .init(text: "DEF", index: 0, finishReason: .stop),
          .init(text: "XYZ", index: 1, finishReason: .length),
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
            "finish_reason" : "stop",
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

  func testSingleLogitBias() async throws {
    var cmd: CompletionsCreateCommand = try parse("completions", "create", "--model-id", "foobar", "--logit-bias", "1234:10", "ABC")
    
    XCTAssertEqual(cmd.modelId, "foobar")
    XCTAssertEqual(cmd.logitBias, "1234:10")
    XCTAssertEqual(cmd.prompt, "ABC")
    
    let now = Date()
    
    try await XCTAssertExpectOpenAICall {
      Completions.Create(model: "foobar", prompt: "ABC", logitBias: [1234:10])
    } returning: {
      .init(
        id: "success", created: now, model: "foobar",
        choices: [
          .init(text: "DEF", index: 0, finishReason: .stop),
        ],
        usage: .init(promptTokens: 1, completionTokens: 2, totalTokens: 3)
      )
    } whileDoing: {
      try await cmd.validate()
      try await cmd.run()
      
      XCTAssertNoDifference(printed, """
      Create Completions
      Model: foobar
      Text:
      \(Format.border("DEF".count))
      DEF
      \(Format.border("DEF".count))
      Finish Reason: stop
      
      Tokens Used: Prompt: 1; Completion: 2; Total: 3

      """)
    }
  }

  func testMultipleLogitBiases() async throws {
    var cmd: CompletionsCreateCommand = try parse("completions", "create", "--model-id", "foobar", "--logit-bias", "1234:10,5678:20", "ABC")
    
    XCTAssertEqual(cmd.modelId, "foobar")
    XCTAssertEqual(cmd.logitBias, "1234:10,5678:20")
    XCTAssertEqual(cmd.prompt, "ABC")
    
    let now = Date()
    
    try await XCTAssertExpectOpenAICall {
      Completions.Create(model: "foobar", prompt: "ABC", logitBias: [1234:10, 5678:20])
    } returning: {
      .init(
        id: "success", created: now, model: "foobar",
        choices: [
          .init(text: "DEF", index: 0, finishReason: .stop),
        ],
        usage: .init(promptTokens: 1, completionTokens: 2, totalTokens: 3)
      )
    } whileDoing: {
      try await cmd.validate()
      try await cmd.run()
      
      XCTAssertNoDifference(printed, """
      Create Completions
      Model: foobar
      Text:
      \(Format.border("DEF".count))
      DEF
      \(Format.border("DEF".count))
      Finish Reason: stop
      
      Tokens Used: Prompt: 1; Completion: 2; Total: 3

      """)
    }
  }
  
  func testMultiLineText() async throws {
    var cmd: CompletionsCreateCommand = try parse(
      "completions",
      "create",
      "--model-id", "foobar",
      "ABC"
    )
    
    XCTAssertEqual(cmd.modelId, "foobar")
    XCTAssertEqual(cmd.prompt, "ABC")
    
    let now = Date()
    
    try await XCTAssertExpectOpenAICall {
      Completions.Create(model: "foobar", prompt: "ABC")
    } returning: {
      .init(
        id: "success", created: now, model: "foobar",
        choices: [
          .init(text: "DEF\nGHI", index: 0, finishReason: .stop)
        ],
        usage: .init(promptTokens: 1, completionTokens: 2, totalTokens: 3)
      )
    } whileDoing: {
      try await cmd.validate()
      try await cmd.run()
      
      XCTAssertNoDifference(printed, """
      Create Completions
      Model: foobar
      Text:
      \(Format.border("DEF".count))
      DEF
      GHI
      \(Format.border("DEF".count))
      Finish Reason: stop
      
      Tokens Used: Prompt: 1; Completion: 2; Total: 3

      """)
    }
  }
  
  func testMultipleMultiLineText() async throws {
    var cmd: CompletionsCreateCommand = try parse(
      "completions",
      "create",
      "--model-id", "foobar",
      "-n", "2",
      "ABC"
    )
    
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
          .init(text: "DEF", index: 0, finishReason: .stop),
          .init(text: "DEFGHIJKLMNOPQRSTUVWXYZ", index: 1, finishReason: .length)
        ],
        usage: .init(promptTokens: 1, completionTokens: 5, totalTokens: 6)
      )
    } whileDoing: {
      try await cmd.validate()
      try await cmd.run()
      
      XCTAssertNoDifference(printed, """
      Create Completions
      Model: foobar
      Choices:
      #1:
        Text:
        \(Format.border("DEF".count))
        DEF
        \(Format.border("DEF".count))
        Finish Reason: stop
      #2:
        Text:
        \(Format.border("DEFGHIJKLMNOPQRSTUVWXYZ".count))
        DEFGHIJKLMNOPQRSTUVWXYZ
        \(Format.border("DEFGHIJKLMNOPQRSTUVWXYZ".count))
        Finish Reason: length
      
      Tokens Used: Prompt: 1; Completion: 5; Total: 6

      """)
    }
  }
  
  func testAllArguments() async throws {
    var cmd: CompletionsCreateCommand = try parse(
      "completions",
      "create",
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
    
    try await XCTAssertExpectOpenAICall {
      Completions.Create(
        model: "foobar",
        prompt: "ABC",
        suffix: "foo",
        maxTokens: 100,
        temperature: 0.5,
        topP: 0.6,
        n: 2,
        logprobs: 1,
        echo: true,
        stop: .init("bar"),
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
          .init(text: "DEF", index: 0, finishReason: .length)
        ],
        usage: .init(promptTokens: 2, completionTokens: 2, totalTokens: 4)
      )
    } whileDoing: {
      try await cmd.validate()
      try await cmd.run()
      
      XCTAssertNoDifference(printed, """
      Create Completions
      Model: foobar
      Text:
      \(Format.border("DEF".count))
      DEF
      \(Format.border("DEF".count))
      Finish Reason: length
      
      Tokens Used: Prompt: 2; Completion: 2; Total: 4
      
      """)
    }
  }
  
  func testVerbose() async throws {
    var cmd: CompletionsCreateCommand = try parse("completions", "create", "--model-id", "foobar", "--verbose", "ABC", "--logprobs", "2")
        
    XCTAssertEqual(cmd.config.findApiKey(), apiKey)
    XCTAssertEqual(cmd.config.verbose, true)
    XCTAssertEqual(cmd.modelId, "foobar")
    XCTAssertEqual(cmd.prompt, "ABC")
    
    let now = Date()
    
    //    try await cmd.run()
    try await XCTAssertExpectOpenAICall {
      Completions.Create(model: "foobar", prompt: "ABC", logprobs: 2)
    } returning: {
      Completion(
        id: "success", created: now, model: "foobar",
        choices: [
          .init(
            text: "DEF", index: 0,
            logprobs: Logprobs(
                tokens: ["a", "b", "c"],
                tokenLogprobs: [-1.0, -2.0, -3.0],
                topLogprobs: [["d": -4, "e": -5, "f": -6], ["g": -7, "h": -8, "i": -9], ["j": -10, "k": -11, "l": -12]],
                textOffset: [1, 2, 3]
            ),
            finishReason: .length
          )
        ],
        usage: .init(promptTokens: 2, completionTokens: 2, totalTokens: 4)
      )
    } whileDoing: {
      try await cmd.validate()
      try await cmd.run()

      XCTAssertNoDifference(printed, """
      Create Completions
      ID: success
      Created: \(now.description)
      Model: foobar
      Text:
      \(Format.border("DEF".count))
      DEF
      \(Format.border("DEF".count))
      Finish Reason: length
      Logprobs:
      #1:
        Token: "a"
        Token Logprobs: -1.0
        Top Logprobs: "d": -4.0, "e": -5.0, "f": -6.0
        Text Offset: 1
      #2:
        Token: "b"
        Token Logprobs: -2.0
        Top Logprobs: "g": -7.0, "h": -8.0, "i": -9.0
        Text Offset: 2
      #3:
        Token: "c"
        Token Logprobs: -3.0
        Top Logprobs: "j": -10.0, "k": -11.0, "l": -12.0
        Text Offset: 3
      
      Tokens Used: Prompt: 2; Completion: 2; Total: 4
      
      """)
    }
  }
}
