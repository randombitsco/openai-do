import ArgumentParser

@inlinable
func errorMessage(_ description: String, example: String) -> String {
  return """
  \(description)
  
    > \(COMMAND_NAME) \(example)
  
  """
}

/// Creates an error message with an optional example of what was expected. The example will have `" > openai-do "` prefixed, so only include the sub-commands.
///
/// Example of usage:
///
/// ```swift
/// errorMessage {
///   "Only specify `--pretty` if also specifying `--to-json`."
///  } example: {
///   "tokens encode --to-json --pretty 'Hello, world!'"
///  }
/// ```
///
/// This results in:
///
/// ```sh
/// Only specify `--pretty` if also specifying `--to-json`.
///
///   > openai-dotokens encode --to-json --pretty 'Hello, world!'
/// ```
///
/// - Parameters:
///   - description: provides the text of the message.
///   - example: provides a good example.
/// - Returns: The final message.
@inlinable
func errorMessage(_ description: () -> String, example: () -> String) -> String {
  return """
  \(description())
  
    > \(COMMAND_NAME) \(example())
  
  """
}

extension ValidationError {
  @usableFromInline
  init(_ description: String, example: String) {
    self.init(errorMessage(description, example: example))
  }
  
  @usableFromInline
  init(_ description: () -> String, example: () -> String) {
    self.init(description(), example: example())
  }
}

infix operator ?!: NilCoalescingPrecedence

/// Throws the right hand side error if the left hand side optional is `nil`.
func ?!<T>(value: T?, error: @autoclosure () -> Error) throws -> T {
    guard let value = value else {
        throw error()
    }
    return value
}
