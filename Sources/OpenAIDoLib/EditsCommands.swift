import ArgumentParser
import Foundation
import OpenAIBits

// MARK: edits

struct EditsCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "edits",
    abstract: "Commands relating to edits.",
    subcommands: [
      EditsCreateCommand.self,
    ]
  )
}

// MARK: create

struct EditsCreateCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "create",
    abstract: "Given a prompt and an instruction, the model will return an edited version of the prompt."
  )
  
  enum EditModel: String, ModelAlias {
    case davinci
    case codex
    
    var modelId: Model.ID {
      switch self {
      case .davinci: return .text_davinci_edit_001
      case .codex: return .code_davinci_edit_001
      }
    }
  }
  
  @OptionGroup var model: ModelConfig<EditModel>
  
  struct Help: InputHelp {
    static var inputValueHelp: String {
      "The input text to use as a starting point for the edit. (Defaults to '')"
    }
    
    static var inputFileHelp: String {
      "The path to a file containing the input text. Provide either this or --input, not both."
    }
  }
  
  @OptionGroup var input: InputOptions<Help>
  
  @Option(help: """
  The instruction that tells the model how to edit the prompt.
  """)
  var instruction: String
  
  @Option(name: .short, help: """
  How many edits to generate for the input and instruction. (Defaults to 1)
  """)
  var n: Int?
  
  @Option(help: """
  What sampling temperature to use. Higher values means the model will take more risks. Try 0.9 for more creative applications, and 0 (argmax sampling) for ones with a well-defined answer. (Defaults to 1)
  
  We generally recommend altering this or --top-p but not both.
  """)
  var temperature: Percentage?
  
  @Option(name: .customLong("top-p"), help: """
  An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top-p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.
  
  We generally recommend altering this or --temperature but not both. (Defaults to 1)
  """)
  var topP: Percentage?
  
  @OptionGroup var client: ClientConfig
  
  var format: FormatConfig { client.format }
  
  mutating func run() async throws {
    let client = client.new()
    let format = format.new()
    
    let edits = Edits.Create(
      model: try model.findModelId(),
      input: try input.getOptionalValue(),
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
