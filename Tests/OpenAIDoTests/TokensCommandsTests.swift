import ArgumentParser
import XCTest
@testable import OpenAIDoLib

// MARK: TokensCountCommand

final class TokensCountCommandTests: XCTestCase {
  func testCount() throws {
    let count = try parse(TokensCountCommand.self, [
      "tokens", "count", "Hello, world!"
    ])
    
    XCTAssertEqual(count.text, "Hello, world!")
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
    let decode = try parse(TokensDecodeCommand.self, [
      "tokens", "decode", "15496", "11", "995", "0"
    ])

    XCTAssertEqual(decode.input, ["15496", "11", "995", "0"])
    XCTAssertEqual(decode.fromJson, false)

    XCTAssertEqual(try decode.getTokens(), [15496, 11, 995, 0])
  }

  func testDecodeFromJSON() throws {
    let decode = try parse(TokensDecodeCommand.self, [
      "tokens", "decode", "--from-json", #"["15496", "11", "995", "0"]"#
    ])

    XCTAssertEqual(decode.input, ["15496", "11", "995", "0"])
    XCTAssertEqual(decode.fromJson, true)

    XCTAssertEqual(try decode.getTokens(), [15496, 11, 995, 0])
  }
}
