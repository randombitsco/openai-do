import ArgumentParser
import XCTest
@testable import OpenAIDoLib

// MARK: TokensCountCommand

final class TokensCountCommandTests: XCTestCase {
  func testCount() throws {
    let cmd = try parse(TokensCountCommand.self, [
      "tokens", "count", "Hello, world!"
    ])
    
    XCTAssertEqual(cmd.text, "Hello, world!")
  }
  
  func testCountWithBadInputFails() throws {
    parseFail(
      TokensCountCommand.self, [
        "tokens", "count", "Hello,", "world!"
      ]
    )
  }
}

// MARK: TokensDecodeCommand

final class TokensDecodeCommandTests: XCTestCase {
  func testDecodeIntegers() throws {
    let cmd = try parse(TokensDecodeCommand.self, [
      "tokens", "decode", "15496", "11", "995", "0"
    ])

    XCTAssertEqual(cmd.input, ["15496", "11", "995", "0"])
    XCTAssertEqual(cmd.fromJson, false)

    XCTAssertEqual(try cmd.getTokens(), [15496, 11, 995, 0])
  }

  func testDecodeFromJSON() throws {
    let cmd = try parse(TokensDecodeCommand.self, [
      "tokens", "decode", "--from-json", "[15496, 11, 995, 0]"
    ])

    XCTAssertEqual(cmd.input, ["[15496, 11, 995, 0]"])
    XCTAssertEqual(cmd.fromJson, true)

    XCTAssertEqual(try cmd.getTokens(), [15496, 11, 995, 0])
  }
}
