import ArgumentParser
import Foundation
import OpenAIBits

@usableFromInline
let COMMAND_NAME = "openai-do"

struct AppError: Error, CustomStringConvertible {
  let description: String
  
  init(_ description: String) {
    self.description = description
  }
}

public struct OpenAIDo: AsyncParsableCommand {
  
  public static var configuration = CommandConfiguration(
    commandName: COMMAND_NAME,
    abstract: "A utility for working with OpenAI APIs.",
    version: "0.9.0",
    
    subcommands: [
      ModelsCommand.self,
      ChatCommand.self,
      TextCommand.self,
      ImagesCommand.self,
      AudioCommand.self,
      EmbeddingsCommand.self,
      FilesCommand.self,
      FineTunesCommand.self,
      ModerationsCommand.self,
      TokensCommand.self,
    ]
  )
  
  public init() {}
}
