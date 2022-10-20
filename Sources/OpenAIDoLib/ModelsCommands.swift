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
  
  @Option(help: "A text value the model name must contains.")
  var contains: String?
  
  @OptionGroup var config: Config
  
  mutating func run() async throws {
    let client = config.client()
    let format = config.format()
    
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
    
    Print(verbose: config.verbose) {
      Title { "Available Models" }
      for model in models.sorted(by: { $0.id.value < $1.id.value }) {
        Bullet { model.id as! Printable }
      }
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
//    let format = config.format()
    
    let model = try await client.call(Models.Detail(id: modelId))
    
//    format.print(title: "Model Detail")
//    format.print(id: model)
//    format.print(model: model)
    
    Print(verbose: config.verbose) {
      Title { "Model Detail" }
      ID(of: model)
      model.details
    }
  }
}

extension Model {
  var details: any Printable {
    Block {
      WhenVerbose { Label("Created") { created } }
      WhenVerbose { Label("Owned By") { ownedBy } }
      Label("Is Fine-Tune") { isFineTune }
//      WhenVerbose { Label("Root Model") { root } }
//      WhenVerbose { Label("Parent Model") { parent } }
//    print(label: "Supports Code", value: model.supportsCode.yesNo)
//    print(label: "Supports Edit", value: model.supportsEdit.yesNo)
//    print(label: "Supports Embedding", value: model.supportsEmbedding.yesNo)
//
      Label("Permissions") { "" }
      Indented(by: 2) {
        
      }
//    print(label: "Permissions", value: "")
//    indented(by: 2).print(list: model.permission, with: Format.print(permission:))
    }
  }
}
