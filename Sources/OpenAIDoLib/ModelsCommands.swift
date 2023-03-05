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
  
  @Flag(name: [.long], help: "If set, only models compatible with \"embeddings create\" calls will be listed.")
  var embeddings: Bool = false
  
  @Flag(help: "If set, only fine-tuned models will be listed.")
  var fineTuned: Bool = false
  
  @Option(help: "A text value the model name must contains.")
  var contains: String?
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
  mutating func run() async throws {
    let client = client.new()
    let format = format.new()
    
    var models = try await client.call(Models.List()).data
    
    if edits {
      models = models.filter { $0.supportsEdit }
    }
    
    if code {
      models = models.filter { $0.supportsCode }
    }
    
    if embeddings {
      models = models.filter { $0.supportsEmbeddings }
    }
    
    if fineTuned {
      models = models.filter { $0.isFineTune }
    }
    
    if let includes = contains {
      models = models.filter { $0.id.value.contains(includes) }
    }
    
    format.print(title: "Available Models")
    
//    format.print(
//      list: models.sorted(by: { $0.id.value < $1.id.value }),
//      with: Format.print(model:)
//    )
    
    for model in models.sorted(by: { $0.id.value < $1.id.value }) {
      format.print(bullet: model.id)
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
  
  @OptionGroup var toJSON: ToJSONFrom<Model>
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
  mutating func run() async throws {
    let client = client.new()
    let format = format.new()
    
    let detail = try await client.call(Models.Detail(id: modelId))
    
    if toJSON.enabled {
      try format.print(text: toJSON.encode(value: detail))
    } else {
      format.print(title: "Model Detail")
      format.print(id: detail)
      format.print(model: detail)
    }
  }
}
