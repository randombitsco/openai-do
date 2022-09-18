import Foundation
import ArgumentParser
import OpenAIBits

// MARK: moderations

struct ModerationsCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "moderations",
    abstract: "Checks if the model classifies a prompt as violating OpenAI's content policy."
  )
  
  @Argument(help: "The input text to classify.")
  var input: String
  
  @Flag(help: "Uses the stable classifier model, which updates less frequently. Accuracy may be slightly lower than 'latest'.")
  var stable: Bool = false
  
  @OptionGroup var config: Config

  mutating func run() async throws {
    let client = config.client()
    let format = config.format()
    
    let response = try await client.call(Moderations(
      input: .string(input),
      model: stable == true ? .stable : .latest
    ))
    
    format.print(title: "Moderations")
    print(moderationsResponse: response, format: format)
  }
}
