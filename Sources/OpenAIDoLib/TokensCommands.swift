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
    
    let format = Format.default
    
    format.print(title: "Token Count")
    format.println()
    format.print(label: "Count", value: count)
  }
}

// MARK: encode

struct TokensEncodeCommand: AsyncParsableCommand {
  enum JsonStyle: EnumerableFlag {
    case compact, pretty
  }
  
  static var configuration = CommandConfiguration(
    commandName: "encode",
    abstract: "Encodes the input text into an estimate of the tokens array used by GPT-2/3.",
    discussion: """
    This uses OpenAI's published GPT-2/3 token encoder, but is performed locally. Exact tokens when calling `completions` or `edits` may differ.
    """
  )
  
  @Argument(help: "The text to encode into tokens.")
  var text: String
  
  /// Options for outputing in JSON format.
  @OptionGroup var toJson: ToJSONFrom<[Int]>

  @Flag(help: "Output more details.")
  var verbose: Bool = false
  
  var format: Format {
    verbose ? .verbose : .default
  }
  
  mutating func run() async throws {
    let encoder = try TokenEncoder()
    let tokens = try encoder.encode(text: text)

    if toJson.enabled {
      format.print(text: try toJson.encode(value: tokens))
    } else {
      format.print(title: "Token Encoding")
      format.println()
      format.print(label: "Tokens", value: tokens)
      format.print(label: "Count", value: tokens.count, verbose: true)
    }
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
  
  @OptionGroup var fromJson: FromJSONTo<[Int]>
  
  @OptionGroup var toJson: ToJSONFrom<String>
  
  @Flag(help: "Output more details.")
  var verbose: Bool = false
  
  var format: Format {
    verbose ? .verbose : .default
  }
    
  mutating func validate() throws {
    try fromJson.validate {
      input
    } example: {
      "tokens decode --from-json '[15496 11 995 0]'"
    } ifDisabled: {
      guard !input.isEmpty else {
        throw ValidationError {
          "Specify at least one integer value to decode."
        } example: {
          "tokens decode 15496 11 995 0"
        }
      }
    }
    
    try toJson.validate()
  }
  
  mutating func run() async throws {
    let tokens = try fromJson.decode {
      guard let text = input.first else {
        throw ValidationError {
          "Expected a single text value, but got \(input.count)."
        } example: {
          "tokens decode --from-json '[15496, 11, 995, 0]'"
        }
      }
      return text
    } otherwise: {
      try input.map({ text in
        guard let int = Int(text, radix: 10) else {
          throw ValidationError {
            "Expected an integer, got \"\(text)\"."
          } example: {
            "tokens decode 15496 11 995 0"
          }
        }
        return int
      })
    }
    
    let encoder = try TokenEncoder()
    let text = try encoder.decode(tokens: tokens)
    
    if toJson.enabled {
      format.print(text: try toJson.encode(value: text))
    } else {
      format.print(title: "Token Decoding")
      format.println()
      format.print(label: "Text", value: text)
    }
  }
}
