import ArgumentParser
import CustomDump
import XCTest
@testable import OpenAIDoLib

// MARK: TokensCountCommand

final class TokensCountCommandTests: OpenAIDoTestCase {
  func testCount() async throws {
    var cmd: TokensCountCommand = try parse(
      "tokens", "count", "Hello, world!"
    )
    
    XCTAssertEqual(cmd.text, "Hello, world!")
    
    try await cmd.run()
    
    XCTAssertNoDifference(printed, """
    Token Count
    ===========
    
    Count: 4
    
    """)
  }
  
  func testCountWithBadInputFails() throws {
    parseFail(
      "tokens", "count", "Hello,", "world!",
      as: TokensCountCommand.self
    )
  }
}

// MARK: TokensDecodeCommand

final class TokensDecodeCommandTests: OpenAIDoTestCase {
  func testDecodeIntegers() async throws {
    var cmd: TokensDecodeCommand = try parse(
      "tokens", "decode", "15496", "11", "995", "0"
    )

    XCTAssertEqual(cmd.input, ["15496", "11", "995", "0"])
    XCTAssertEqual(cmd.fromJson, false)

    XCTAssertEqual(try cmd.getTokens(), [15496, 11, 995, 0])
    
    try await cmd.run()
    
    XCTAssertNoDifference(printed, """
    Token Decoding
    ==============
    
    Text: Hello, world!
    
    """)
  }

  func testDecodeFromJSON() async throws {
    var cmd: TokensDecodeCommand = try parse(
      "tokens", "decode", "--from-json", "[15496, 11, 995, 0]"
    )

    XCTAssertEqual(cmd.input, ["[15496, 11, 995, 0]"])
    XCTAssertEqual(cmd.fromJson, true)

    XCTAssertEqual(try cmd.getTokens(), [15496, 11, 995, 0])
    
    try await cmd.run()
    
    XCTAssertNoDifference(printed, """
    Token Decoding
    ==============
    
    Text: Hello, world!
    
    """)
  }
}
