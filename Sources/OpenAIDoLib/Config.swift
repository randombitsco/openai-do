import ArgumentParser
import Foundation
import OpenAIBits

struct Config: ParsableArguments {
  /// Attempts to find the OpenAI API Key from the `"OPENAI_API_KEY"` environment variable.
  static func findApiKeyInEnvironment() -> String? {
    ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
  }

  /// Attempts to find the OpenAI Org Key from the `"OPENAI_ORG_KEY"` environment variable.
  static func findOrgKeyInEnvironment() -> String? {
    ProcessInfo.processInfo.environment["OPENAI_ORG_KEY"]
  }
  
  /// A `func` value which attempts to find an OpenAI API Key from the environment.
  /// By default, it uses ``Config/findApiKeyInEnvironment()``.
  /// Override this provide an alternate default.
  static var findApiKey: () -> String? = Config.findApiKeyInEnvironment
  
  /// A `func` value which attempts to find an OpenAI Organization Key from the environment.
  /// By default, it uses ``Config/findOrgKeyInEnvironment()``.
  /// Override this provide an alternate default.
  static var findOrgKey: () -> String? = Config.findOrgKeyInEnvironment
  
  @Option(help: "The OpenAI API Key. If not provided, uses the 'OPENAI_API_KEY' environment variable.")
  var apiKey: String?
  
  @Option(help: "The OpenAI Organisation key. If not provided, uses the 'OPENAI_ORG_KEY' environment variable.")
  var orgKey: String?
  
  @Flag(help: "Output more details.")
  var verbose: Bool = false
  
  @Flag(help: "Output debugging information.")
  var debug: Bool = false
  
  /// Finds the specified OpenAI API Key. It will first check the ``apiKey`` `Option`, and if not provided it
  /// will try the static ``Config/findApiKey`` function, which by default will look for the `OPENAI_API_KEY`
  /// environment variable.
  ///
  /// - Returns The API Key, or `nil` if unavailable.
  func findApiKey() -> String? {
    apiKey ?? Config.findApiKey()
  }
  
  /// Finds the specified OpenAI Organization Key. It will first check the ``orgKey`` `Option`, and if not provided it
  /// will try the static ``Config/findOrgKey`` function, which by default will look for the `OPENAI_ORG_KEY`
  /// environment variable.
  ///
  /// - Returns The Org Key, or `nil` if unavailable.
  func findOrgKey() -> String? {
    orgKey ?? Config.findOrgKey()
  }
  
  /// Configures a ``Client/Logger`` function, which if in ``debug`` mode, will print, otherwise
  var log: Client.Logger? {
    guard debug else {
      return nil
    }
    return { format().print(log: $0) }
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
