import ArgumentParser
import XCTest
@testable import OpenAIDoLib

// MARK: ModelsListCommand

final class ModelsListCommandTests: XCTestCase {
  override func setUpWithError() throws {
    Config.findApiKey = { "XYZ" }
  }
  
  func testList() throws {
    let cmd = try parse(ModelsListCommand.self, [
      "models", "list"
    ])

    XCTAssertEqual(cmd.edits, false)
    XCTAssertEqual(cmd.code, false)
    XCTAssertEqual(cmd.embeddings, false)
    XCTAssertEqual(cmd.fineTuned, false)
    XCTAssertNil(cmd.includes)
    
    XCTAssertNil(cmd.config.apiKey)
    XCTAssertEqual(cmd.config.findApiKey(), "XYZ")
  }
  
  func testListWithApiKey() throws {
    let cmd = try parse(ModelsListCommand.self, [
      "models", "list", "--api-key", "ABC"
    ])

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
    parseFail(ModelsListCommand.self, [
      "models", "list"
    ])
  }

  func testListFilters() throws {
    let cmd = try parse(ModelsListCommand.self, [
      "models", "list", "--edits", "--code", "--embeddings", "--fine-tuned"
    ])

    XCTAssertEqual(cmd.edits, true)
    XCTAssertEqual(cmd.code, true)
    XCTAssertEqual(cmd.embeddings, true)
    XCTAssertEqual(cmd.fineTuned, true)
    XCTAssertNil(cmd.includes)
  }

  func testListIncludes() throws {
    let cmd = try parse(ModelsListCommand.self, [
      "models", "list", "--includes", "foobar"
    ])

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
    let cmd = try parse(ModelsDetailCommand.self, [
        "models", "detail", "--model-id", "foobar"
      ]
    )

    XCTAssertEqual(cmd.modelId, .init("foobar"))
  }
}
