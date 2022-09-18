import ArgumentParser
import XCTest
@testable import OpenAIDoLib

// MARK: ModelsListCommand

final class ModelsListCommandTests: XCTestCase {
  override func setUpWithError() throws {
    Config.findApiKey = { "XYZ" }
  }
  
  func testList() throws {
    let cmd: ModelsListCommand = try parse("models", "list")

    XCTAssertEqual(cmd.edits, false)
    XCTAssertEqual(cmd.code, false)
    XCTAssertEqual(cmd.embeddings, false)
    XCTAssertEqual(cmd.fineTuned, false)
    XCTAssertNil(cmd.includes)
    
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
    XCTAssertNil(cmd.includes)
    
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
    XCTAssertNil(cmd.includes)
  }

  func testListIncludes() throws {
    let cmd: ModelsListCommand = try parse(
      "models", "list", "--includes", "foobar"
    )

    XCTAssertEqual(cmd.edits, false)
    XCTAssertEqual(cmd.code, false)
    XCTAssertEqual(cmd.embeddings, false)
    XCTAssertEqual(cmd.fineTuned, false)
    XCTAssertEqual(cmd.includes, "foobar")
  }

}

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
