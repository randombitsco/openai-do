import ArgumentParser
import Foundation
import OpenAIBits


struct Config: ParsableArguments {
  @Option(help: "The OpenAI API Key. If not provided, uses the 'OPENAI_API_KEY' environment variable.")
  var apiKey: String?
  
  @Option(help: "The OpenAI Organisation key. If not provided, uses the 'OPENAI_ORG_KEY' environment variable.")
  var orgKey: String?
  
  @Flag(help: "Output more details.")
  var verbose: Bool = false
  
  @Flag(help: "Output debugging information.")
  var debug: Bool = false
  
  func findApiKey() -> String? {
    apiKey ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
  }
  
  func findOrgKey() -> String? {
    orgKey ?? ProcessInfo.processInfo.environment["OPENAI_ORG_KEY"]
  }
  
  var log: Client.Logger? {
    guard debug else {
      return nil
    }
    return { print($0) }
  }
  
  func client() -> Client {
    Client(apiKey: findApiKey() ?? "NO API KEY PROVIDED", organization: findOrgKey(), log: log)
  }
  
  /// The default format, given the config.
  func format() -> Format {
    verbose ? .verbose : .default
  }
  
  mutating func validate() throws {
    guard findApiKey() != nil else {
      throw ValidationError("Please provide an OpenAI API Key either via `--api-key` or the 'OPENAI_API_KEY' environment variable.")
    }
  }
}
