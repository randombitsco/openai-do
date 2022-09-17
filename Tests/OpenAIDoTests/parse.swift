import ArgumentParser
import OpenAIDoLib
import XCTest

func parse<A>(_ type: A.Type, _ arguments: [String], file: StaticString = #filePath, line: UInt = #line) throws -> A where A: ParsableCommand {
  var result: A?
  XCTAssertNoThrow(result = try OpenAIDo.parseAsRoot(arguments) as? A, file: file, line: line)
  return try XCTUnwrap(result, file: file, line: line)
}

func parseFail<A>(_ type: A.Type, _ arguments: [String], file: StaticString = #filePath, line: UInt = #line) throws {
  XCTAssertThrowsError(try OpenAIDo.parseAsRoot(arguments) as? A, file: file, line: line)
}
