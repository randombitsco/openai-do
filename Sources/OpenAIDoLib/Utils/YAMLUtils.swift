import ArgumentParser
import Foundation
import Yams

/// Encodes the provided value to a YAML string
///
/// - Parameter value: The value to encode
/// - Returns The encoded value.
func yamlEncode<T: Encodable>(_ value: T, pretty: Bool = false) throws -> String {
  let encoder = YAMLEncoder()
  encoder.options = .init(
    indent: 2,
    sortKeys: true
  )
  
  do {
    return try encoder.encode(value)
  } catch EncodingError.invalidValue(let value, let ctx) {
    throw ValidationError("Invalid value of \(value): \(ctx.debugDescription)")
  }
}

/// Encodes the provided value to a YAML ``Data`` value
///
/// - Parameter value: The value to encode
/// - Returns: The encoded value.
func yamlEncodeData<T: Encodable>(_ value: T, pretty: Bool = false) throws -> Data {
  return try Data(yamlEncode(value, pretty: pretty).utf8)
}

/// Attempts to decode the provided `String` value into the target type `T`.
///
/// - Parameters:
///   - value: The value to decode
///   - targetType: The type to decode to (optional)
///
/// - Returns: The decoded value as the `targetType`
///
/// - Throws A ``ArgumentParser/ValidationError`` if there is an issue.
func yamlDecode<T: Decodable>(_ value: String, as targetType: T.Type = T.self) throws -> T {
  return try yamlDecodeData(value.data(using: .utf8)!)
}

/// Attempts to decode the provided ``Data`` value into the target type `T`.
/// - Parameters:
///   - value: The data to decoe.
///   - targetType: The type to decode into (optional)
/// - Throws: An ``ArgumentParser/ValidationError`` if there is an issue while parsing.
/// - Returns: The new instance of `T`.
func yamlDecodeData<T: Decodable>(_ value: Data, as targetType: T.Type = T.self) throws -> T {
  let decoder = YAMLDecoder(encoding: .utf8)
  do {
    return try decoder.decode(targetType, from: value)
  } catch DecodingError.dataCorrupted(let ctx),
          DecodingError.typeMismatch(_, let ctx),
          DecodingError.valueNotFound(_, let ctx),
          DecodingError.keyNotFound(_, let ctx)
  {
    throw ValidationError(ctx.debugDescription)
  }
}
