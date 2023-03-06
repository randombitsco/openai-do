import ArgumentParser
import Foundation
import OpenAIBits

// MARK: embeddings

struct EmbeddingsCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "embeddings",
    abstract: "Commands relating to embeddings.",
    subcommands: [
      EmbeddingsCreateCommand.self,
    ]
  )
}

// MARK: create

enum EmbeddingsModel: String, ModelAlias {
  /// The `text-embedding-ada-002` model.
  case ada_v2 = "ada-v2"
  
  var modelId: OpenAIBits.Model.ID {
    switch self {
    case .ada_v2: return .text_embedding_ada_002
    }
  }
}

struct EmbeddingsCreateCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "create",
    abstract: "Creates an embedding vector representing the input text, saving the results into a JSON file."
  )
  
  @OptionGroup
  var model: ModelOptions<EmbeddingsModel>
  
  struct Help: InputHelp {
    static var inputValueHelp: String {
        """
        Input text to get embeddings for. The input must not exceed 2048 tokens in length.

        Unless you are embedding code, we suggest replacing newlines (`\\n`) in your input with a single space, as we have observed inferior results when newlines are present.
        """
    }
    
    static var inputFileHelp: String {
      "The path to a file containing the input text to get embeddings for. Provide either this or --input, not both."
    }
  }
  
  @OptionGroup var input: InputOptions<Help>

  @Option(help: """
  A unique identifier representing your end-user, which will help OpenAI to monitor and detect abuse.
  """)
  var user: String?

  @Option(
    help: "A filename to save the embedding into as a JSON file.",
    completion: .file(extensions: ["json"])
  )
  var outputFile: String
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }

  mutating func run() async throws {
    let client = client.new()
    let format = format.new()

    let result = try await client.call(Embeddings.Create(
      model: model.findModelId(), 
      input: .string(try input.getValue()),
      user: user
    ))

    let outputURL = URL(fileURLWithPath: outputFile)
    let jsonData = try JSONEncoder().encode(result.data)
    try jsonData.write(to: outputURL)

    format.print(title: "Embeddings")
    format.print(label: "Vector Size", value: result.data.map(\.embedding).map(\.count).reduce(0, +))
    format.print(usage: result.usage)
    format.println()
    format.print(label: "JSON File Saved", value: outputFile)
  }
}
