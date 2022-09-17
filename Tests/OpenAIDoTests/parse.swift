import ArgumentParser
import OpenAIDoLib
import XCTest

/// Expects to parse the provided arguments, resulting in a ``ParsableCommand`` of type ``A``.
func parse<A>(_ type: A.Type, _ arguments: [String], file: StaticString = #filePath, line: UInt = #line) throws -> A where A: ParsableCommand {
  var result: A?
  XCTAssertNoThrow(result = try OpenAIDo.parseAsRoot(arguments) as? A, file: file, line: line)
  return try XCTUnwrap(result, file: file, line: line)
}

/// Expects to fail while parse the provided arguments, resulting in an exception.
func parseFail<A>(_ type: A.Type, _ arguments: [String], file: StaticString = #filePath, line: UInt = #line) {
  XCTAssertThrowsError(try OpenAIDo.parseAsRoot(arguments) as? A, file: file, line: line)
}
