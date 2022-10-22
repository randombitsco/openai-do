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

struct EmbeddingsCreateCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "create",
    abstract: "Creates an embedding vector representing the input text, saving the results into a JSON file."
  )
  
  @Option(help: """
  The model ID to use creating the embeddings. Should be a 'text-similarity', 'text-search', or 'code-search' model.
  """)
  var modelId: Model.ID

  @Option(help: """
  A unique identifier representing your end-user, which will help OpenAI to monitor and detect abuse.
  """)
  var user: String?

  @Option(
    help: "A filename to save the embedding into as a JSON file.",
    completion: .file(extensions: ["json"])
  )
  var outputFile: String

  @Argument(help: """
  Input text to get embeddings for. The input must not exceed 2048 tokens in length.

  Unless you are embedding code, we suggest replacing newlines (`\\n`) in your input with a single space, as we have observed inferior results when newlines are present.
  """)
  var input: String
  
  @OptionGroup var client: ClientConfig
  
  var format: FormatConfig { client.format }

  mutating func run() async throws {
    let client = client.new()
    let format = format.new()

    let result = try await client.call(Embeddings.Create(
      model: modelId, 
      input: .string(input),
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
