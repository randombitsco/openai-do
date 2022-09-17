import ArgumentParser
import Foundation
import OpenAIBits

// MARK: tokens

struct TokensCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "tokens",
    abstract: "Commands relating to tokens.",
    subcommands: [
      TokensCountCommand.self,
      TokensEncodeCommand.self,
      TokensDecodeCommand.self,
    ]
  )
}

// MARK: count

struct TokensCountCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "count",
    abstract: "Estimates the number of tokens a text input will be encoded into.",
    discussion: "This is performed locally, based on the published GPT-2/3 token encoder."
  )
  
  @Argument(help: "The text to estimate tokens for.")
  var text: String
  
  mutating func run() async throws {
    let encoder = try TokenEncoder()
    let count = try encoder.encode(text: text).count
    
    print(title: "Token Count", format: .default)
    print("")
    print(label: "Count", value: count, format: .default)
  }
}

// MARK: encode

struct TokensEncodeCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "encode",
    abstract: "Encodes the input text into an estimate of the tokens array used by GPT-2/3.",
    discussion: """
    This uses OpenAI's published GPT-2/3 token encoder, but is performed locally. Exact tokens when calling `completions` or `edits` may differ.
    """
  )
  
  @Argument(help: "The text to encode into tokens.")
  var text: String
  
  @Flag(help: "Output more details.")
  var verbose: Bool = false
  
  var format: Format {
    verbose ? .verbose : .default
  }
  
  mutating func run() async throws {
    let encoder = try TokenEncoder()
    let tokens = try encoder.encode(text: text)
    
    print(title: "Token Encoding", format: format)
    print("")
    print(label: "Tokens", value: tokens, format: format)
    print(label: "Count", value: tokens.count, verbose: true, format: format)
  }
}

// MARK: decode

struct TokensDecodeCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "decode",
    abstract: "Decodes the input token array into a text value.",
    discussion: """
    This uses OpenAI's published GPT-2/3 token encoder, but is performed locally. Exact text when calling `completions` or `edits` may differ.
    """
  )
  
  @Argument(help: """
  The tokens to decode into text. The default input is a space-separated list of integers:
  
    > \(COMMAND_NAME) tokens decode 15496 11 995 0
  
  Alternately, use `--from-json` to provide a JSON text value:
  
    > \(COMMAND_NAME) tokens decode --from-json '[15496, 11, 995, 0]'
  
  """)
  var input: [String]
  
  @Flag(help: """
  Indicates the input will be a JSON-encoded array of tokens.
  """)
  var fromJson: Bool = false
  
  @Flag(help: "Output more details.")
  var verbose: Bool = false
  
  var format: Format {
    verbose ? .verbose : .default
  }
  
  /// Parses the ``input`` into an integer array, if possible.
  func getTokens() throws -> [Int] {
    // Is it JSON?
    guard !fromJson else {
      guard input.count == 1, let json = input.first else {
        throw ValidationError("""
        Specify a single JSON-encoded text value.
        
          > \(COMMAND_NAME) tokens decode --from-json '[15496, 11, 995, 0]'
        
        """)
      }
      return try jsonDecode(json)
    }
    
    guard !input.isEmpty else {
      throw ValidationError("""
      Specify at least one integer value to decode.
      
        > \(COMMAND_NAME) tokens decode 15496 11 995 0
      
      """)
    }
    
    // It's integers.
    return try input.map({ text in
      guard let int = Int(text, radix: 10) else {
        throw ValidationError("""
        Expected an integer, got "\(text)".
        
          > \(COMMAND_NAME) tokens decode 15496 11 995 0
        
        """)
      }
      return int
    })
  }
  
  mutating func validate() throws {
    let _ = try getTokens()
  }
  
  mutating func run() async throws {
    let encoder = try TokenEncoder()
    let tokens = try getTokens()
    let text = try encoder.decode(tokens: tokens)
    
    print(title: "Token Decoding", format: format)
    print("")
    print(label: "Text", value: text, format: format)
  }
}
