import CustomDump
import XCTest
import Yams

@testable import OpenAIDoLib

final class ShortChatMessageTests: XCTestCase {

    func testEncodeToJSON() throws {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.sortedKeys]
      
      let encoded = try encoder.encode(ShortChatMessage.system("System message."))
      
      XCTAssertNoDifference(
        #"{"system":"System message."}"#,
        String(decoding: encoded, as: UTF8.self)
      )
    }
  
  func testEncodeArrayToJSON() throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    
    let encoded = try encoder.encode([
      ShortChatMessage.system("System message."),
      ShortChatMessage.user("User message."),
      ShortChatMessage.assistant("Assistant message."),
    ])
    
    XCTAssertNoDifference(
      #"[{"system":"System message."},{"user":"User message."},{"assistant":"Assistant message."}]"#,
      String(decoding: encoded, as: UTF8.self)
    )
  }
  
  func testEncodeToYAML() throws {
    let encoder = YAMLEncoder()
    encoder.options = .init(sortKeys: true)
    
    let encoded = try encoder.encode(ShortChatMessage.system("System message."))
    
    XCTAssertNoDifference(
      #"""
      system: System message.
      
      """#,
      encoded
    )
  }

  func testEncodeArrayToYAML() throws {
    let encoder = YAMLEncoder()
    encoder.options = .init(sortKeys: true)
    
    let encoded = try encoder.encode([
      ShortChatMessage.system("System message."),
      ShortChatMessage.user("User message."),
      ShortChatMessage.assistant("Assistant message."),
    ])
    
    XCTAssertNoDifference(
      #"""
      - system: System message.
      - user: User message.
      - assistant: Assistant message.
      
      """#,
      encoded
    )
  }

  func testDecodeFromJSON() throws {
    let decoder = JSONDecoder()
    
    let decoded = try decoder.decode(ShortChatMessage.self, from: #"{"system":"System message."}"#.data(using: .utf8)!)
    
    XCTAssertEqual(decoded, .system("System message."))
  }

  func testDecodeArrayFromJSON() throws {
    let decoder = JSONDecoder()
    
    let decoded = try decoder.decode([ShortChatMessage].self, from: #"[{"system":"System message."},{"user":"User message."},{"assistant":"Assistant message."}]"#.data(using: .utf8)!)
    
    XCTAssertEqual(decoded, [
      .system("System message."),
      .user("User message."),
      .assistant("Assistant message."),
    ])
  }

  func testDecodeFromYAML() throws {
    let decoder = YAMLDecoder()
    
    let decoded = try decoder.decode(ShortChatMessage.self, from: #"""
      system: System message.
      
      """#.data(using: .utf8)!)
    
    XCTAssertEqual(decoded, .system("System message."))
  }

  func testDecodeArrayFromYAML() throws {
    let decoder = YAMLDecoder()
    
    let decoded = try decoder.decode([ShortChatMessage].self, from: #"""
      - system: System message.
      - user: User message.
      - assistant: Assistant message.
      
      """#.data(using: .utf8)!)
    
    XCTAssertEqual(decoded, [
      .system("System message."),
      .user("User message."),
      .assistant("Assistant message."),
    ])
  }

  func testDecodeInvalidValueFromYAML() throws {
    let decoder = YAMLDecoder()
    
    XCTAssertThrowsError(try decoder.decode(ShortChatMessage.self, from: #"""
      invalid: System message.
      
      """#.data(using: .utf8)!))
  }
}
