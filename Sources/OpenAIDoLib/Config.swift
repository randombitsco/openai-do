import ArgumentParser
import Foundation
import OpenAIBits


struct Config: ParsableArguments {
  /// A `func` value which attempts to find an OpenAI API Key from the environment.
  /// By default, it pulls it from the `"OPENAI_API_KEY"` from the process environment.
  /// It is used if no `apiKey` is provided directly into the ``Config``.
  /// Override this provide an alternate default.
  static var findApiKey: () -> String? = {
    ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
  }
  
  /// A `func` value which attempts to find an OpenAI API Key from the environment.
  /// By default, it pulls it from the `"OPENAI_ORG_KEY"` from the process environment.
  /// It is used if no `orgKey` is provided directly into the ``Config``.
  /// Override this provide an alternate default.
  static var findOrgKey: () -> String? = {
    ProcessInfo.processInfo.environment["OPENAI_ORG_KEY"]
  }
  
  @Option(help: "The OpenAI API Key. If not provided, uses the 'OPENAI_API_KEY' environment variable.")
  var apiKey: String?
  
  @Option(help: "The OpenAI Organisation key. If not provided, uses the 'OPENAI_ORG_KEY' environment variable.")
  var orgKey: String?
  
  @Flag(help: "Output more details.")
  var verbose: Bool = false
  
  @Flag(help: "Output debugging information.")
  var debug: Bool = false
  
  func findApiKey() -> String? {
    apiKey ?? Config.findApiKey()
  }
  
  func findOrgKey() -> String? {
    orgKey ?? Config.findOrgKey()
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
