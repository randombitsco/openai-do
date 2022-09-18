import ArgumentParser
import Foundation
import OpenAIBits

// MARK: models

struct ModelsCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "models",
    abstract: "Commands to list and describe the various models available.",
    subcommands: [
      ModelsListCommand.self,
      ModelsDetailCommand.self
    ]
  )
}

// MARK: list

struct ModelsListCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "list",
    abstract: """
    Lists the currently available models, and provides basic information about each one, such as the owner and availability.
    """
  )
  
  @Flag(help: "If set, only models compatible with `edits` calls will be listed.")
  var edits: Bool = false
  
  @Flag(help: "If set, only models compatible optimised for code generation will be listed.")
  var code: Bool = false
  
  @Flag(name: [.long], help: "If set, only models compatible with `embeddings` calls will be listed.")
  var embeddings: Bool = false
  
  @Flag(help: "If set, only fine-tuned models will be listed.")
  var fineTuned: Bool = false
  
  @Option(help: "A text value the model name must include.")
  var includes: String?
  
  @OptionGroup var config: Config
  
  mutating func run() async throws {
    let client = config.client()
    
    var models = try await client.call(Models.List()).data
    
    if edits {
      models = models.filter { $0.supportsEdit }
    }
    
    if code {
      models = models.filter { $0.supportsCode }
    }
    
    if embeddings {
      models = models.filter { $0.supportsEmbedding }
    }
    
    if fineTuned {
      models = models.filter { $0.isFineTune }
    }
    
    if let includes = includes {
      models = models.filter { $0.id.value.contains(includes) }
    }
    
    print("Models:")
    for model in models.sorted(by: { $0.id.value < $1.id.value }) {
      print("- \(model.id)")
    }
  }
}

// MARK: detail

struct ModelsDetailCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "detail",
    abstract: """
    Retrieves a model instance, providing basic information about the model such as the owner and permissioning.
    """
  )

  @Option(help: "The model ID.")
  var modelId: Model.ID
  
  @OptionGroup var config: Config  
  
  mutating func run() async throws {
    let client = config.client()
    let format = config.format()
    
    let detail = try await client.call(Models.Details(for: modelId))
    
    format.print(title: "Model Detail")
    format.print(model: detail)
  }
}
