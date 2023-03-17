import ArgumentParser
import Foundation
import OpenAIBits
import Parsing

// MARK: text

struct ChatCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "chat",
    abstract: "Commands relating to chat.",
    subcommands: [
      ChatCompletionsCommand.self,
    ]
  )
}

// MARK: text completions

struct ChatCompletionsCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "completions",
    abstract: "Creates completions for the provided messages and parameters."
  )
  
  enum ChatModel: String, ModelAlias {
    case turbo = "turbo"
    case gpt4 = "gpt-4"
    
    var modelId: Model.ID {
      switch self {
      case .turbo: return "gpt-3.5-turbo"
      case .gpt4: return "gpt-4"
      }
    }    
  }
  
  @OptionGroup var model: ModelOptions<ChatModel>
    
  struct Help: InputHelp {
    static var inputValueOptionName: String { "messages" }
    static var inputFileOptionName: String { "messages-file" }
    
    static var inputValueHelp: String {
        """
        The messages to generate chat completions for, in 'chat format'.
        
        See: https://platform.openai.com/docs/guides/chat/introduction
        """
    }
    
    static var inputFileHelp: String {
      "The path to a file containing the messages list. Provide either this or --\(Self.inputValueOptionName), not both."
    }
  }
  
  @OptionGroup var messages: InputOptions<Help>
  
  enum MessagesFormat: String, ExpressibleByArgument {
    case json
    case yaml
  }
  
  @Option(help: """
  Indicates the format of the `messages` content. Either `yaml` or `json`.
  
  If `yaml`, the `messages` content should be a list of dictionaries, where each dictionary contains the key `system|user|assistant`, assigned the message content. For example:

  ```
  - system: You are a helpful assistant.
  - user: What answer to the ultimate question of life, the universe, and everything?
  - assistant: 42
  - user: What is the question?
  ```

  If `json`, the messages content should be an array of objects with a `role` and `content` field, matching what is returned by the API. For example:

  ```
  [
    {
      "role": "system",
      "content": "You are a helpful assistant."
    },
    {
      "role": "user",
      "content": "What answer to the ultimate question of life, the universe, and everything?"
    },
    {
      "role": "assistant",
      "content": "42"
    },
    {
      "role": "user",
      "content": "What is the question?"
    }
  ]
  ```
  
  """)
  var messagesFormat: MessagesFormat = .yaml
  
  @Option(help: """
  The maximum number of tokens to generate in the chat completion. The total length of input tokens and generated tokens is limited by the model's context length. (default: infinite)

  """)
  var maxTokens: Int?
  
  @Option(help: """
  What sampling temperature to use. Higher values means the model will take more risks. Try 0.9 for more creative applications, and 0 (argmax sampling) for ones with a well-defined answer. Generally, alter this or --top-p but not both. (default: 1)
  """)
  var temperature: Percentage?
  
  @Option(name: .customLong("top-p"), help: """
  An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top-p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered. Generally, alter this or --temperature but not both. (default: 1)
  """)
  var topP: Percentage?
  
  @Option(name: .short, help: """
  How many completions to generate for each prompt. Note: Because this parameter generates many completions, it can quickly consume your token quota. Use carefully and ensure that you have reasonable settings for --max-tokens and stop. (default: 1)
  """)
  var n: Int?

// TODO: Add support for streaming responses
//  @Option(help: "Whether to stream back partial progress. If set, tokens will be sent as data-only server-sent events as they become available, with the stream terminated by a 'data: [DONE]' message. (default: false)")
//  var stream: Bool?
    
  @Option(help: """
  A sequence where the API will stop generating further tokens. The returned text will not contain the stop sequence.
  """)
  var stop: Stop?
  
  @Option(parsing: .unconditional, help: """
  Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics. (default: 0)
  """)
  var presencePenalty: Penalty?

  @Option(parsing: .unconditional, help: "Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim. (default: 0)")
  var frequencyPenalty: Penalty?
  
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
  
  @OptionGroup var toJson: ToJSONFrom<ChatCompletion>
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
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
    
    let modelId: Model.ID = try model.findModelId()
    
    guard let chatModel = OpenAIBits.ChatModel(rawValue: modelId.value) else {
      throw AppError("Unsupported model for chat: \(modelId)")
    }
    
    format.print(log: "about to retrieve messages.getValue()")
    let messagesRaw = try messages.getValue()
    format.print(log: "messagesRaw: (messagesRaw)")
    let messages = try messagesFormat.decode(messagesRaw)
    
    let completions = Chat.Completions(
      model: chatModel,
      messages: messages,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      n: n,
// TODO: Implement streaming.
//      stream: stream,
      stop: stop,
      presencePenalty: presencePenalty,
      frequencyPenalty: frequencyPenalty,
      logitBias: try parseLogitBias(),
      user: user
    )
    
    let result = try await client.call(completions)
    
    if toJson.enabled {
      format.print(text: try toJson.encode(value: result))
    } else {
      format.print(title: "Text Completions")
      format.print(chatCompletion: result)
    }
  }
}

extension ChatCompletionsCommand.MessagesFormat {
  func decode(_ value: String) throws -> [ChatMessage] {
    switch self {
    case .json:
      do {
        let shortMessages: [ShortChatMessage] = try jsonDecode(value)
        return shortMessages.map { $0.asChatMessage() }
      } catch {
        return try jsonDecode(value)
      }
    case .yaml:
      do {
        let shortMessages: [ShortChatMessage] = try yamlDecode(value)
        return shortMessages.map { $0.asChatMessage() }
      } catch {
        return try yamlDecode(value)
      }
    }
  }
}

/// A utility enum for compact message creation.
enum ShortChatMessage: Hashable, Codable {
  case system(String)
  case user(String)
  case assistant(String)

  // Add encoding/decoding support, where it will decode something like:
  //
  // { "system": "Hello" }
  //
  // into a `ChatMessage.system("Hello")` value.

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .system(let message):
      try container.encode(["system": message])
    case .user(let message):
      try container.encode(["user": message])
    case .assistant(let message):
      try container.encode(["assistant": message])
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let value = try container.decode([String: String].self)
    if let message = value["system"] {
      self = .system(message)
    } else if let message = value["user"] {
      self = .user(message)
    } else if let message = value["assistant"] {
      self = .assistant(message)
    } else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid chat message: \(value)")
    }
  }

  func asChatMessage() -> OpenAIBits.ChatMessage {
    switch self {
    case .system(let message):
      return .init(role: .system, content: message)
    case .user(let message):
      return .init(role: .user, content: message)
    case .assistant(let message):
      return .init(role: .assistant, content: message)
    }
  }
}

