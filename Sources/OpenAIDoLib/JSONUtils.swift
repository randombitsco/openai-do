import ArgumentParser
import Foundation

/// Encodes the provided value to a JSON string
///
/// - Parameter value: The value to encode
/// - Returns The encoded value.
func jsonEncode<T: Encodable>(_ value: T, pretty: Bool = false) throws -> String {
  return try String(decoding: jsonEncodeData(value, pretty: pretty), as: UTF8.self)
}

/// Encodes the provided value to a JSON ``Data`` value
///
/// - Parameter value: The value to encode
/// - Returns: The encoded value.
func jsonEncodeData<T: Encodable>(_ value: T, pretty: Bool = false) throws -> Data {
  let encoder = JSONEncoder()
  encoder.keyEncodingStrategy = .convertToSnakeCase
  encoder.dateEncodingStrategy = .custom({ date, encoder in
    let seconds = Int64(date.timeIntervalSince1970)
    var singleValueEnc = encoder.singleValueContainer()
    try singleValueEnc.encode(seconds)
  })
  if pretty {
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
  }
  
  do {
    return try encoder.encode(value)
  } catch EncodingError.invalidValue(let value, let ctx) {
    throw ValidationError("Invalid value of \(value): \(ctx.debugDescription)")
  }
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
func jsonDecode<T: Decodable>(_ value: String, as targetType: T.Type = T.self) throws -> T {
  return try jsonDecodeData(value.data(using: .utf8)!)
}

/// Attempts to decode the provided ``Data`` value into the target type `T`.
/// - Parameters:
///   - value: The data to decoe.
///   - targetType: The type to decode into (optional)
/// - Throws: An ``ArgumentParser/ValidationError`` if there is an issue while parsing.
/// - Returns: The new instance of `T`.
func jsonDecodeData<T: Decodable>(_ value: Data, as targetType: T.Type = T.self) throws -> T {
  let decoder = JSONDecoder()
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  decoder.dateDecodingStrategy = .custom({ decoder in
    let seconds: Int64 = try decoder.singleValueContainer().decode(Int64.self)
    return Date(timeIntervalSince1970: TimeInterval(seconds))
  })
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
