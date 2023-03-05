import ArgumentParser
import CustomDump
import XCTest
@testable import OpenAIDoLib

// MARK: TokensCountCommand

final class TokensCountCommandTests: OpenAIDoTestCase {
  func testCount() async throws {
    var cmd: TokensCountCommand = try parse(
      "tokens", "count", "--input", "Hello, world!"
    )
    
    XCTAssertEqual(cmd.input.value, "Hello, world!")
    
    try await cmd.run()
    
    XCTAssertNoDifference(printed, """
    Token Count
    
    Count: 4
    
    """)
  }
  
  func testCountWithBadInputFails() throws {
    parseFail(
      "tokens", "count", "Hello,", "world!",
      as: TokensCountCommand.self
    )
  }
  
  func testCountWithNoInputFails() throws {
    parseFail(
      "tokens", "count", "--from-json",
      as: TokensCountCommand.self
    )
  }
}
// MARK: TokensEncodeCommand

final class TokensEncodeCommandTests: OpenAIDoTestCase {
  func testEncode() async throws {
    var cmd: TokensEncodeCommand = try parse(
      "tokens", "encode", "--input", "Hello, world!"
    )
    
    XCTAssertEqual(cmd.input.value, "Hello, world!")
    XCTAssertFalse(cmd.toJson.enabled)
    XCTAssertNil(cmd.toJson.style)
    XCTAssertFalse(cmd.format.verbose)

    try await cmd.run()
    
    XCTAssertNoDifference(printed, """
    Token Encoding
    
    Tokens: [15496, 11, 995, 0]
    
    """)
  }

  func testEncodeToJSON() async throws {
    var cmd: TokensEncodeCommand = try parse(
      "tokens", "encode", "--input", "Hello, world!", "--to-json"
    )

    XCTAssertEqual(cmd.input.value, "Hello, world!")
    XCTAssertTrue(cmd.toJson.enabled)
    XCTAssertNil(cmd.toJson.style)
    XCTAssertFalse(cmd.format.verbose)

    try await cmd.run()
    
    XCTAssertNoDifference(printed, """
    [15496,11,995,0]
    
    """)
  }
  
  func testEncodeToJSONVerbose() async throws {
    var cmd: TokensEncodeCommand = try parse(
      "tokens", "encode", "--input", "Hello, world!", "--to-json", "--pretty"
    )

    XCTAssertEqual(cmd.input.value, "Hello, world!")
    XCTAssertTrue(cmd.toJson.enabled)
    XCTAssertEqual(cmd.toJson.style, .pretty)
    XCTAssertFalse(cmd.format.verbose)

    try await cmd.run()
    
    XCTAssertNoDifference(printed, """
    [
      15496,
      11,
      995,
      0
    ]
    
    """)
  }
}

// MARK: TokensDecodeCommand

final class TokensDecodeCommandTests: OpenAIDoTestCase {
  func testDecodeIntegers() async throws {
    var cmd: TokensDecodeCommand = try parse(
      "tokens", "decode", "--input", "15496", "11", "995", "0"
    )

    XCTAssertEqual(cmd.input, ["15496", "11", "995", "0"])
    XCTAssertFalse(cmd.fromJson.enabled)
    XCTAssertFalse(cmd.toJson.enabled)

    try cmd.validate()
    
    try await cmd.run()
    
    XCTAssertNoDifference(printed, """
    Token Decoding
    
    Text:
    \(Format.border("Hello, world!".count))
    Hello, world!
    \(Format.border("Hello, world!".count))
    
    """)
  }

  func testDecodeFromJSON() async throws {
    var cmd: TokensDecodeCommand = try parse(
      "tokens", "decode", "--from-json", "-i", "[15496, 11, 995, 0]"
    )

    XCTAssertEqual(cmd.input, ["[15496, 11, 995, 0]"])
    XCTAssertTrue(cmd.fromJson.enabled)
    XCTAssertFalse(cmd.toJson.enabled)
    
    try cmd.validate()
    
    try await cmd.run()
    
    XCTAssertNoDifference(printed, """
    Token Decoding
    
    Text:
    \(Format.border("Hello, world!".count))
    Hello, world!
    \(Format.border("Hello, world!".count))
    
    """)
  }
  
  func testDecodeToJSON() async throws {
    var cmd: TokensDecodeCommand = try parse(
      "tokens", "decode", "--from-json", "-i", "[15496, 11, 995, 0]", "--to-json"
    )

    XCTAssertEqual(cmd.input, ["[15496, 11, 995, 0]"])
    XCTAssertTrue(cmd.fromJson.enabled)

    try cmd.validate()
    
    try await cmd.run()
    
    XCTAssertNoDifference(printed, """
    "Hello, world!"
    
    """)
  }
}
