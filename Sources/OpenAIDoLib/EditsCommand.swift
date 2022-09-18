import ArgumentParser
import Foundation
import OpenAIBits

// MARK: edits

struct EditsCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "edits",
    abstract: "Given a prompt and an instruction, the model will return an edited version of the prompt."
  )
  
  @Option(name: .long, help: """
  Either 'davinci', or 'codex', or the full ID of the model to prompt.
  
  Must be an 'edit' model (use `models list --edit`).
  """)
  var modelId: EditsModelID
  
  @Argument(help: """
  The input text to use as a starting point for the edit. (Defaults to '')
  """)
  var input: String?
  
  @Option(name: .shortAndLong, help: """
  The instruction that tells the model how to edit the prompt.
  """)
  var instruction: String
  
  @Option(name: .short, help: """
  How many edits to generate for the input and instruction. (Defaults to 1)
  """)
  var n: Int?
  
  @Option(help: """
  What sampling temperature to use. Higher values means the model will take more risks. Try 0.9 for more creative applications, and 0 (argmax sampling) for ones with a well-defined answer. (Defaults to 1)
  
  We generally recommend altering this or `top-p` but not both.
  """)
  var temperature: Percentage?
  
  @Option(name: .customLong("top-p"), help: """
  An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top-p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.
  
  We generally recommend altering this or `temperature` but not both. (Defaults to 1)
  """)
  var topP: Percentage?
  
  @OptionGroup var config: Config
  
  mutating func run() async throws {
    let client = config.client()
    let format = config.format()
    
    let edits = Edits(
      model: modelId.modelId,
      input: input,
      instruction: instruction,
      n: n,
      temperature: temperature,
      topP: topP
    )
    
    let result = try await client.call(edits)
    
    format.print(title: "Edits")
    for choice in result.choices {
      print("\(choice.index): \"\(choice.text)\"\n")
    }
    
    format.print(usage: result.usage)
  }
}

extension EditsCommand {
  /// Provides an alias for common "edit" models.
  enum EditsModelID: ExpressibleByArgument {
    case davinci
    case codex
    case id(String)

    init?(argument: String) {
      switch argument {
      case "davinci":
        self = .davinci
      case "codex":
        self = .codex
      default:
        self = .id(argument)
      }
    }
    
    var modelId: Model.ID {
      switch self {
      case .davinci:
        return "edits-davinci-002"
      case .codex:
        return "edits-davinci-codex-002"
      case .id(let id):
        return .init(id)
      }
    }
  }
  
}
