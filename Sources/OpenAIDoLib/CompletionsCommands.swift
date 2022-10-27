import ArgumentParser
import Foundation
import OpenAIBits
import Parsing

// MARK: completions

struct CompletionsCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "completions",
    abstract: "Commands relating to completions.",
    subcommands: [
      CompletionsCreateCommand.self,
    ]
  )
}

// MARK: create

struct CompletionsCreateCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "create",
    abstract: "Creates a completion for the provided prompt and parameters."
  )
  
  enum CompletionModel: String, ModelAlias {
    case ada
    case babbage
    case curie
    case davinci
    case codex
    
    var modelId: Model.ID {
      switch self {
      case .ada: return .text_ada_001
      case .babbage: return .text_babbage_001
      case .curie: return .text_curie_001
      case .davinci: return .text_davinci_002
      case .codex: return .code_davinci_001
      }
    }    
  }
  
  @OptionGroup var model: ModelConfig<CompletionModel>
    
  struct Help: InputHelp {
    static var inputValueHelp: String {
        """
        The input prompt to generate completions for. (Defaults to '<|endoftext|>')

        Note that '<|endoftext|>' is the document separator that the model sees during training, so if a prompt is not specified the model will generate as if from the beginning of a new document.
        """
    }
    
    static var inputFileHelp: String {
      "The path to a file containing the input prompt to create generations for. Provide either this or --input, not both."
    }
  }
  
  @OptionGroup var input: InputOptions<Help>

//  @Option(help: """
//  The ID of the model to prompt. You can use `\(COMMAND_NAME) models list` to see all of your available models.
//  """)
//  var modelId: Model.ID
  
  @Option(help: "The suffix that comes after a completion of inserted text.")
  var suffix: String?
  
  @Option(help: """
  The maximum number of tokens to generate in the completion. (Defaults to 16)
  
  The token count of your prompt plus `max-tokens` cannot exceed the model's context length. Most models have a context length of 2048 tokens (except for the newest models, which support 4096).
  """)
  var maxTokens: Int?
  
  @Option(help: """
  What sampling temperature to use. Higher values means the model will take more risks. Try 0.9 for more creative applications, and 0 (argmax sampling) for ones with a well-defined answer.  (Defaults to 1)
  
  We generally recommend altering this or `top-p` but not both.
  """)
  var temperature: Percentage?
  
  @Option(name: .customLong("top-p"), help: """
  An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top-p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. (Defaults to 1)
  
  We generally recommend altering this or `temperature` but not both.
  """)
  var topP: Percentage?
  
  @Option(name: .short, help: """
  How many completions to generate for each prompt. (Defaults to 1)
          
  Note: Because this parameter generates many completions, it can quickly consume your token quota. Use carefully and ensure that you have reasonable settings for `max-tokens` and stop.
  """)
  var n: Int?

// TODO: Add support for streaming responses
//  @Option(help: "Whether to stream back partial progress. If set, tokens will be sent as data-only server-sent events as they become available, with the stream terminated by a 'data: [DONE]' message. (Defaults to false)")
//  var stream: Bool?
  
  @Option(help: """
  Include the log probabilities on the `logprobs` most likely tokens, as well the chosen tokens. For example, if `logprobs` is 5, the API will return a list of the 5 most likely tokens. The API will always return the `logprob` of the sampled token, so there may be up to `logprobs+1` elements in the response. (Defaults to nothing)
  
  The maximum value for `logprobs` is 5.
  """)
  var logprobs: Int?
  
  @Flag(help: "Echo back the prompt in addition to the completion. (Defaults to false)")
  var echo: Bool = false
  
  @Option(help: """
  A sequence where the API will stop generating further tokens. The returned text will not contain the stop sequence.
  """)
  var stop: Completions.Stop?
  
  @Option(parsing: .unconditional, help: """
  Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics. (Defaults to 0)
  """)
  var presencePenalty: Penalty?

  @Option(parsing: .unconditional, help: "Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim. (Defaults to 0)")
  var frequencyPenalty: Penalty?
  
  @Option(help: """
  Generates `best-of` completions server-side and returns the \"best\" (the one with the highest log probability per token). Results cannot be streamed. (Defaults to 1)
  
  When used with `n`, `best-of` controls the number of candidate completions and `n` specifies how many to return – `best-of` must be greater than `n`.
  
  Note: Because this parameter generates many completions, it can quickly consume your token quota. Use carefully and ensure that you have reasonable settings for `max-tokens` and `stop`.
  """)
  var bestOf: Int?
  
  @Option(help: """
  Modify the likelihood of specified tokens appearing in the completion.
          
  Accepts a comma-separated "<token>:<bias>" values that maps tokens (specified by their token ID in the GPT tokenizer) to an associated bias value from -100 to 100. You can use this tokenizer tool (which works for both GPT-2 and GPT-3) to convert text to token IDs. Mathematically, the bias is added to the logits generated by the model prior to sampling. The exact effect will vary per model, but values between -1 and 1 should decrease or increase likelihood of selection; values like -100 or 100 should result in a ban or exclusive selection of the relevant token.

  As an example, you can pass "50256:-10" to prevent the '<|endoftext|>' token from being generated.
  """)
  var logitBias: String?
  
  @Option(help: """
  A unique identifier representing your end-user, which will help OpenAI to monitor and detect abuse.
  """)
  var user: String?
  
  @OptionGroup var toJson: ToJSONFrom<Completion>
  
  @OptionGroup var client: ClientConfig
  
  var format: FormatConfig { client.format }
  
  /// Parses the logit bias string into a dictionary of token IDs to biases.
  /// - Returns: A dictionary of token IDs to biases, or `nil` if none provided.
  /// - Throws: `ValidationError` if the logit bias string is invalid.
  func parseLogitBias() throws -> [Token: Decimal]? {
    guard let logitBias = logitBias else {
      return nil
    }
    
    do {
      return try logitBiasParser.parse(logitBias)
    } catch {
      throw ValidationError("Unable to parse the logit-bias: \(error)")
    }
  }
  
  mutating func validate() async throws {
    _ = try parseLogitBias()
  }
  
  mutating func run() async throws {
    let client = client.new()
    let format = format.new()
    
    let prompt = try input.getOptionalValue()
    
    let completions = Completions.Create(
      model: try model.findModelId(),
      prompt: prompt == nil ? nil : .string(prompt!),
      suffix: suffix,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      n: n,
// TODO: Implement streaming.
//      stream: stream,
      logprobs: logprobs,
      echo: echo ? true : nil,
      stop: stop,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      bestOf: bestOf,
      logitBias: try parseLogitBias(),
      user: user
    )
    
    let result = try await client.call(completions)
    
    if toJson.enabled {
      format.print(text: try toJson.encode(value: result))
    } else {
      format.print(title: "Create Completions")
      format.print(completion: result)
    }
  }
}

// MARK: logitBias Parsing

extension Token {
  static let parser = Parse(Token.init(_:)) {
    Int.parser(of: Substring.self)
  }
}

extension Decimal {
  static func parser(of: Substring.Type = Substring.self) -> AnyParser<Substring, Decimal>
  {
    Parse(Decimal.init(_:)) {
      Double.parser(of: Substring.self)
    }
    .eraseToAnyParser()
  }
}

let tokenBiasParser = Parse {
  Token.parser
  ":"
  Decimal.parser(of: Substring.self)
}

let logitBiasParser = Many(1...) {
  tokenBiasParser
} separator: {
  ","
}
.map { (tokenBiasPairs: [(Token, Decimal)]) -> [Token: Decimal] in
  tokenBiasPairs.reduce(into: [Token: Decimal]()) { partialResult, tokenBiasPair in
    partialResult[tokenBiasPair.0] = tokenBiasPair.1
  }
}
