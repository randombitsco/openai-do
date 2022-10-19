import ArgumentParser
import XCTest
@testable import OpenAIDoLib

// MARK: ModelsListCommand

final class ModelsListCommandTests: OpenAIDoTestCase {
  func testList() throws {
    let cmd: ModelsListCommand = try parse("models", "list")

    XCTAssertEqual(cmd.edits, false)
    XCTAssertEqual(cmd.code, false)
    XCTAssertEqual(cmd.embeddings, false)
    XCTAssertEqual(cmd.fineTuned, false)
    XCTAssertNil(cmd.contains)
    
    XCTAssertNil(cmd.config.apiKey)
    XCTAssertEqual(cmd.config.findApiKey(), "XYZ")
  }
  
  func testListWithApiKey() throws {
    let cmd: ModelsListCommand = try parse(
      "models", "list", "--api-key", "ABC"
    )

    XCTAssertEqual(cmd.edits, false)
    XCTAssertEqual(cmd.code, false)
    XCTAssertEqual(cmd.embeddings, false)
    XCTAssertEqual(cmd.fineTuned, false)
    XCTAssertNil(cmd.contains)
    
    XCTAssertEqual(cmd.config.apiKey, "ABC")
    XCTAssertEqual(cmd.config.findApiKey(), "ABC")
  }
  
  func testListWithNoApiKey() throws {
    Config.findApiKey = { nil }
    parseFail("models", "list", as: ModelsListCommand.self)
  }

  func testListFilters() throws {
    let cmd: ModelsListCommand = try parse(
      "models", "list", "--edits", "--code", "--embeddings", "--fine-tuned"
    )

    XCTAssertEqual(cmd.edits, true)
    XCTAssertEqual(cmd.code, true)
    XCTAssertEqual(cmd.embeddings, true)
    XCTAssertEqual(cmd.fineTuned, true)
    XCTAssertNil(cmd.contains)
  }

  func testListIncludes() throws {
    let cmd: ModelsListCommand = try parse(
      "models", "list", "--contains", "foobar"
    )

    XCTAssertEqual(cmd.edits, false)
    XCTAssertEqual(cmd.code, false)
    XCTAssertEqual(cmd.embeddings, false)
    XCTAssertEqual(cmd.fineTuned, false)
    XCTAssertEqual(cmd.contains, "foobar")
  }

}

// MARK: ModelsDetailCommand

final class ModelsDetailCommandTests: XCTestCase {
  override func setUpWithError() throws {
    Config.findApiKey = { "XYZ" }
  }

  func testDetail() throws {
    let cmd: ModelsDetailCommand = try parse(
      "models", "detail", "--model-id", "foobar"
    )

    XCTAssertEqual(cmd.modelId, .init("foobar"))
  }
}
