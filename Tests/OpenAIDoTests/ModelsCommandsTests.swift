import ArgumentParser
import XCTest
@testable import OpenAIDoLib

// MARK: ModelsListCommand

final class ModelsListCommandTests: XCTestCase {
  func testList() throws {
    let cmd = try parse(ModelsListCommand.self, [
      "models", "list"
    ])

    XCTAssertEqual(cmd.edits, false)
    XCTAssertEqual(cmd.code, false)
    XCTAssertEqual(cmd.embeddings, false)
    XCTAssertEqual(cmd.fineTuned, false)
    XCTAssertIsNil(cmd.includes)
  }

  func testListFilters() throws {
    let cmd = try parse(ModelsListCommand.self, [
      "models", "list", "--edits", "--code", "--embeddings", "--fine-tuned"
    ])

    XCTAssertEqual(cmd.edits, true)
    XCTAssertEqual(cmd.code, true)
    XCTAssertEqual(cmd.embeddings, true)
    XCTAssertEqual(cmd.fineTuned, true)
    XCTAssertIsNil(cmd.includes)
  }

  func testListIncludes() throws {
    let cmd = try parse(ModelsListCommand.self, [
      "models", "list", "--includes", "foobar"
    ])

    XCTAssertEqual(cmd.edits, false)
    XCTAssertEqual(cmd.code, false)
    XCTAssertEqual(cmd.embeddings, false)
    XCTAssertEqual(cmd.fineTuned, false)
    XCTAssertEquals(cmd.includes, "foobar")
  }

}

final class ModelsDetailCommandTests: XCTestCase {  
  func testCountWithBadInputFails() throws {
    let cmd = parse(
      ModelsDetailCommand.self, [
        "models", "detail", "--model-id,", "foobar"
      ]
    )

    XCTAssertEqual(cmd.modelId, .init("foobar"))
  }
}
