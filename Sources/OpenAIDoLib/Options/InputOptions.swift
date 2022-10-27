import ArgumentParser
import Foundation

/// Provides support for getting user input from a prompt or a file.
struct InputOptions<Config: InputHelp>: ParsableArguments {
  /// The input as a `String`.
  @Option(name: [.customShort("i"), .customLong("input")], help: .init(Config.inputValueHelp))
  var value: String?
  
  /// The path to the input text file.
  @Option(name: [.customLong("input-file")], help: .init(Config.inputFileHelp), completion: .file())
  var file: String?
  
  func validate() throws {
    switch (value, file) {
    case (.none, .none):
      throw ValidationError("Provide either the --input or --input-file.")
    case (.some, .some):
      throw ValidationError("Provide either the --input or --input-file, not both.")
    default:
      break
    }
  }
  
  func getValue() throws -> String {
    switch (value, file) {
    case (.none, .none):
      throw ValidationError("Provide either the --input or --input-file.")
    case (.some, .some):
      throw ValidationError("Provide either the --input or --input-file, not both.")
    case (.some(let input), _):
      return input
    case (_, .some(let inputFile)):
      let inputUrl = URL(fileURLWithPath: inputFile)
      return try String(contentsOf: inputUrl, encoding: .utf8)
    }
  }
  
  func getOptionalValue() throws -> String? {
    switch (value, file) {
    case (.none, .none):
      return nil
    default:
      return try getValue()
    }
  }

}

protocol InputHelp: Decodable {
  static var inputValueHelp: String { get }
  static var inputFileHelp: String { get }
  
  init()
}

extension InputHelp {
  init(from decoder: Decoder) throws {
    self.init()
  }
}
