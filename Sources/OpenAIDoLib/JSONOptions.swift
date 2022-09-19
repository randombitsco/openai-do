import ArgumentParser

// MARK: FromJSON

/// Provides arguments for commands that support receiving their input as JSON.
struct FromJSONTo<T: Decodable>: ParsableArguments {
  @Flag(name: .customLong("from-json"), help: """
  If set, input is parsed as JSON-encoded text.
  """)
  var enabled: Bool = false
  
  enum CodingKeys: String, CodingKey {
    case enabled
  }
}

extension FromJSONTo {
  func decode(text: String) throws -> T {
    try jsonDecode(text, as: T.self)
  }
  
  func decode(text: () throws -> String, otherwise: () throws -> T) throws -> T {
    guard enabled else {
      return try otherwise()
    }
    
    return try jsonDecode(text(), as: T.self)
  }
  
  /// If ``enabled``, validates if the ``String`` value is present as expected.
  ///
  /// - Parameter input: The input to test.
  func validate(
    input: () -> String?,
    example: () -> String,
    ifDisabled: () throws -> Void = {}
  ) throws {
    guard enabled else {
      return try ifDisabled()
    }
    
    if input() == nil {
      throw ValidationError(
        "Specify a single JSON-encoded text value.",
        example: example()
      )
    }
  }
  
  /// If ``enabled``, verifies if the ``[String]`` has exactly one item, and  that it is valid JSON-encoded text.
  
  func validate(
    input: () -> [String],
    example: () -> String,
    ifDisabled: () throws -> Void = {}
  ) throws {
    guard enabled else {
      return try ifDisabled()
    }
    
    let input = input()
    
    guard input.count == 1 else {
      throw ValidationError(
        "Provide a single JSON-encoded text value.",
        example: example()
      )
    }
  }
}


// MARK: ToJSON

/// Provides arguments for outputting in JSON format.
struct ToJSONFrom<T: Encodable>: ParsableArguments {
  enum Style: String, EnumerableFlag {
    case compact, pretty
  }
  
  @Flag(name: .customLong("to-json"), help: """
  If set, output will be JSON-encoded text.
  """)
  var enabled: Bool = false
  
  @Flag(help: """
  If outputting to JSON, how should it be output?
  """)
  var style: Style?
  
//  enum CodingKeys: String, CodingKey {
//    case enabled = "to-json"
//    case style
//  }
}

extension ToJSONFrom {
  mutating func validate() throws {
    if let style = style, !enabled {
      throw ValidationError("Only use `--\(style)` if `--to-json` is specified.")
    }
  }
  
  /// Encodes the value to a JSON based on the settings.
  ///
  /// - Parameter value: The value to encode.
  /// - Returns: The value, encoded as JSON.
  /// - Throws: ``ValidationError``s if there is a problem with the configuration or encoding.
  func encode(value: T) throws -> String {
    try jsonEncode(value, pretty: style == .pretty)
  }
}
