import ArgumentParser
import Foundation
import OpenAIBits

/// Describes common configuration values for commands dealing with the API.
struct ClientOptions: ParsableArguments {
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
  static var findApiKey: () -> String? = ClientOptions.findApiKeyInEnvironment
  
  /// A `func` value which attempts to find an OpenAI Organization Key from the environment.
  /// By default, it uses ``Config/findOrgKeyInEnvironment()``.
  /// Override this provide an alternate default.
  static var findOrgKey: () -> String? = ClientOptions.findOrgKeyInEnvironment
  
  @Option(help: "The OpenAI API Key. If not provided, uses the 'OPENAI_API_KEY' environment variable.")
  var apiKey: String?
  
  @Option(help: "The OpenAI Organisation Key. If not provided, uses the 'OPENAI_ORG_KEY' environment variable.")
  var orgKey: String?
  
  @OptionGroup var format: FormatOptions
  
  /// Finds the specified OpenAI API Key. It will first check the ``apiKey`` `Option`, and if not provided it will try the static ``Config/findApiKey`` function, which by default will look for the `OPENAI_API_KEY` environment variable.
  ///
  /// - Returns The API Key, or `nil` if unavailable.
  func findApiKey() -> String? {
    apiKey ?? ClientOptions.findApiKey()
  }
  
  /// Finds the specified OpenAI Organization Key. It will first check the ``orgKey`` `Option`, and if not provided it will try the static ``Config/findOrgKey`` function, which by default will look for the `OPENAI_ORG_KEY` environment variable.
  ///
  /// - Returns The Org Key, or `nil` if unavailable.
  func findOrgKey() -> String? {
    orgKey ?? ClientOptions.findOrgKey()
  }
  
  /// Configures a ``Client/Logger`` function, which if in ``debug`` mode, will print, otherwise returns `nil`.
  var log: OpenAI.Logger? {
    guard format.debug else {
      return nil
    }
    return { format.new().print(log: $0) }
  }
  
  /// Creates a new ``Client`` based on the current configuration.
  /// - Returns: The new ``Client`` instance.
  func new() -> OpenAI {
    OpenAI(apiKey: findApiKey() ?? "NO API KEY PROVIDED", organization: findOrgKey(), log: log)
  }
  
  mutating func validate() throws {
    guard findApiKey() != nil else {
      throw ValidationError("Please provide an OpenAI API Key either via `--api-key` or the 'OPENAI_API_KEY' environment variable.")
    }
  }
}
