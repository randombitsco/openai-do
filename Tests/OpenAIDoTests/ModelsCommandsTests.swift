import ArgumentParser
import CustomDump
import OpenAIBits
import OpenAIBitsTestHelpers
@testable import OpenAIDoLib
import XCTest

// MARK: ModelsListCommand

final class ModelsListCommandTests: OpenAIDoTestCase {
  func testList() async throws {
    var cmd: ModelsListCommand = try parse("models", "list")

    XCTAssertEqual(cmd.edits, false)
    XCTAssertEqual(cmd.code, false)
    XCTAssertEqual(cmd.embeddings, false)
    XCTAssertEqual(cmd.fineTuned, false)
    XCTAssertNil(cmd.contains)

    XCTAssertNil(cmd.client.apiKey)
    XCTAssertEqual(cmd.client.findApiKey(), "XYZ")

    let now = Date()

    try await XCTAssertExpectOpenAICall {
      Models.List()
    } response: {
      ListOf<Model>(
        data: [
            .init(
            id: "model-1", created: now, ownedBy: "jblogs",
            permission: [.init(id: "mperm-1", created: now, organization: "*")],
            root: "model-0"
          ),
            .init(
            id: "model-2", created: now, ownedBy: "jblogs",
            permission: [.init(id: "mperm-2", created: now, allowFineTuning: true, organization: "*")],
            root: "model-0"
          ),
        ]
      )
    } doing: {
      try cmd.validate()
      try await cmd.run()

      XCTAssertNoDifference(printed, """
      Available Models
      ∙ model-1
      ∙ model-2
      
      """)
    }
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

    XCTAssertEqual(cmd.client.apiKey, "ABC")
    XCTAssertEqual(cmd.client.findApiKey(), "ABC")
  }

  func testListWithNoApiKey() throws {
    ClientConfig.findApiKey = { nil }
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

final class ModelsDetailCommandTests: OpenAIDoTestCase {

  func testDetail() async throws {
    var cmd: ModelsDetailCommand = try parse(
      "models", "detail", "--model-id", "foobar"
    )

    XCTAssertEqual(cmd.modelId, .init("foobar"))
    
    let now = Date()

    try await XCTAssertExpectOpenAICall {
      Models.Detail(id: "foobar")
    } response: {
      Model(
        id: "foobar", created: now, ownedBy: "jblogs",
        permission: [.init(id: "mperm-1", created: now, organization: "*")],
        root: "model-0"
      )
    } doing: {
      try cmd.validate()
      try await cmd.run()

      XCTAssertNoDifference(printed, """
      Model Detail
      ID: foobar
      Is Fine-Tune: no
      Supports Code: no
      Supports Edit: no
      Supports Embedding: no
      Permissions:
        ID: mperm-1
          Is Blocking: no
          Allow View: no
          Allow Logprobs: no
          Allow Fine-Tuning: no
      
      """)
    }

  }
  
  func testDetailVerbose() async throws {
    var cmd: ModelsDetailCommand = try parse(
      "models", "detail", "--model-id", "foobar", "--verbose"
    )

    XCTAssertEqual(cmd.modelId, .init("foobar"))
    XCTAssertTrue(cmd.client.format.verbose)
    
    let now = Date()

    try await XCTAssertExpectOpenAICall {
      Models.Detail(id: "foobar")
    } response: {
      Model(
        id: "foobar", created: now, ownedBy: "jblogs",
        permission: [.init(id: "mperm-1", created: now, allowLogprobs: true, organization: "*")],
        root: "model-0"
      )
    } doing: {
      try cmd.validate()
      try await cmd.run()

      XCTAssertNoDifference(printed, """
      Model Detail
      ID: foobar
      Created: \(now.description)
      Owned By: jblogs
      Root Model: model-0
      Is Fine-Tune: no
      Supports Code: no
      Supports Edit: no
      Supports Embedding: no
      Permissions:
        ID: mperm-1
          Created: \(now.description)
          Is Blocking: no
          Allow View: no
          Allow Logprobs: yes
          Allow Fine-Tuning: no
          Allow Sampling: no
          Allow Search Indices: no
          Organization: *
      
      """)
    }

  }
}
