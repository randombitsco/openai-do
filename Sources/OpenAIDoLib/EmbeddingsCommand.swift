import ArgumentParser
import Foundation
import OpenAIBits

/// MARK: embeddings

struct EmbeddingsCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "embeddings",
    abstract: "Creates an embedding vector representing the input text, saving the results into a JSON file."
  )
  
  @Option(help: """
  The model ID to use creating the embeddings. Should be a 'text-similarity',  'text-search', or 'code-search'
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
  var output: String

  @Argument(help: """
  Input text to get embeddings for. The input must not exceed 2048 tokens in length.

  Unless you are embedding code, we suggest replacing newlines (`\n`) in your input with a single space, as we have observed inferior results when newlines are present.
  """)
  var input: String
  
  @OptionGroup var config: Config

  mutating func run() async throws {
    let client = config.client()
    let format = config.format()

    let result = try await client.call(Embeddings.Create(
      model: modelId, 
      input: .string(input),
      user: user
    ))

    let outputURL = URL(fileURLWithPath: output)
    let jsonData = try JSONEncoder().encode(result.data)
    try jsonData.write(to: outputURL)

    format.print(title: "Embeddings")
    format.print(usage: result.usage)
    format.print(label: "JSON File Saved:", value: output)
  }
}
