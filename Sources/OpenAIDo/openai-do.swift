import ArgumentParser
import Foundation
import OpenAIBits

let COMMAND_NAME = "openai-do"

struct AppError: Error, CustomStringConvertible {
  let description: String
  
  init(_ description: String) {
    self.description = description
  }
}

@main
struct OpenAIDo: AsyncParsableCommand {
  
  static var configuration = CommandConfiguration(
    commandName: COMMAND_NAME,
    abstract: "A utility for working with OpenAI APIs.",
    version: "0.9.0",
    
    subcommands: [
      ModelsCommand.self,
      CompletionsCommand.self,
      EditsCommand.self,
      EmbeddingsCommand.self,
      FilesCommand.self,
      FineTunesCommand.self,
      ModerationsCommand.self,
      TokensCommand.self,
    ]
  )
}
