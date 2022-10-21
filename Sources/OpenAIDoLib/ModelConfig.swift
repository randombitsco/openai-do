import ArgumentParser
import OpenAIBits

/// A utility protocol to allow providing aliases for common model IDs while still allowing specific IDs to be provided. Works in concert with the ``ModelConfig``.
protocol ModelAlias: RawRepresentable, CaseIterable, ExpressibleByArgument where RawValue == String {
  var modelId: Model.ID { get }
  
  /// Provides help text for the `ModelConfig.model` this is used in.
  static var modelHelp: String { get }
  
  /// Provides help text for the `ModelConfig.modelIdHelp` this is used in.
  static var modelIdHelp: String { get }
}

// Default implementations.
extension ModelAlias {
  init?(argument: String) {
    guard let result = Self.init(rawValue: argument) else {
      return nil
    }
    self = result
  }
  
  static func modelId(for alias: String) -> Model.ID? {
    guard let result = Self(rawValue: alias) else {
      return nil
    }
    return result.modelId
  }
  
  static var modelHelp: String {
    let allCases = Self.allCases
    let count = allCases.count
    switch count {
    case 0: return "No aliases available."
    case 1: return "Must be '\(allCases.first!)'."
    case 2: return "Either '\(allCases.first!)' or '\(allCases.dropFirst().first!)'."
    default:
      let head = allCases.dropLast().map { "'\($0.rawValue)'" }.joined(separator: ", ")
      let tail = allCases.dropFirst(count-1).first!
      return "Either \(head), or '\(tail)'."
    }
  }
  
  static var modelIdHelp: String {
    var result = "The full ID for a compatible model"
    if let first = Self.allCases.first {
      result += " (eg. '\(first.modelId)')"
    }
    result += "."
    return result
  }
}

/// Provides support for having common aliases for `Model.ID` values which can be specified
/// via the `--model` argument, and specific IDs via the `--model-id` argument.
struct ModelConfig<T>: ParsableArguments where T: ModelAlias {
  @Option(help: .init("""
  \(T.modelHelp) Provide an alias here, or the ID via --model-id, but not both.
  """))
  var model: T?
  
  @Option(help: .init("""
  \(T.modelIdHelp) Provide a model ID here, or the alias via --model, but not both.
  """))
  var modelId: Model.ID?
  
  func validate() throws {
    switch (model, modelId) {
    case (.none, .none), (.some, .some):
      throw ValidationError("Provide either an alias via --model, or a full ID via --model-id, but not both.")
    default:
      break
    }
  }
  
  /// Call this function to return whichever `Model.ID` was provided.
  /// - Returns: The `Model.ID`
  func findModelId() throws -> Model.ID {
    guard let result = model?.modelId ?? modelId else {
      throw ValidationError("Provide either --model or --model-id")
    }
    return result
  }
}
