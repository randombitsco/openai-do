import Foundation
import ArgumentParser
import OpenAIBits

// MARK: moderations

struct ModerationsCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "moderations",
    abstract: "Commands relating to moderations.",
    subcommands: [
      ModerationsCreateCommand.self,
    ]
  )
}

// MARK: create

struct ModerationsCreateCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "create",
    abstract: "Checks if the model classifies a prompt as violating OpenAI's content policy."
  )
  
  @Argument(help: "The input text to classify.")
  var input: String
  
  @Flag(help: "Specify either the 'latest' or 'stable' classifier model, which updates less frequently. Accuracy may be slightly lower than 'latest'. Defaults to 'latest'.")
  var model: Moderations.Model?
  
  @OptionGroup var client: ClientConfig
  
  var format: FormatConfig { client.format }

  mutating func run() async throws {
    let client = client.new()
    let format = format.new()
    
    let response = try await client.call(Moderations.Create(
      input: .string(input),
      model: model ?? .latest
    ))
    
    format.print(title: "Moderations")
    format.print(moderation: response)
  }
}

extension Moderations.Model: EnumerableFlag {
  public static var allCases: [Moderations.Model] {
    [.latest, .stable]
  }
}