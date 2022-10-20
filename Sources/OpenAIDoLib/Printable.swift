import Foundation
import OpenAIBits
import Prism

/// A result builder type that builds either a single prism element, or an
/// array of prism elements.
@resultBuilder
struct PrintableBuilder {
  public static func buildBlock(_ components: any Printable...) -> any Printable { components }
  public static func buildBlock(_ component: any Printable) -> any Printable { component }
  public static func buildArray(_ components: [any Printable]) -> any Printable { components }
  public static func buildExpression(_ expression: any Printable) -> any Printable { expression }
  public static func buildEither(first component: any Printable) -> any Printable { component }
  public static func buildEither(second component: any Printable) -> any Printable { component }
}

struct PrintableContext {
  let verbose: Bool
}

protocol Printable {
  func format(context: PrintableContext) -> CustomStringConvertible
}

extension String: Printable {
  func format(context: PrintableContext) -> CustomStringConvertible {
    self
  }
}

extension Array: Printable where Element == any Printable {
  func format(context: PrintableContext) -> CustomStringConvertible {
    reduce(into: "") { partialResult, printable in
      partialResult.append(String(describing: printable.format(context: context)))
    }
  }
}

struct Block: Printable {
  
  let body: any Printable
  
  init(@PrintableBuilder body: () -> any Printable) {
    self.body = body()
  }
  
  func format(context: PrintableContext) -> CustomStringConvertible {
    body.format(context: context)
  }
}

struct WhenVerbose: Printable {
  let body: Printable
  
  init(@PrintableBuilder body: () -> Printable) {
    self.body = body()
  }
  
  func format(context: PrintableContext) -> CustomStringConvertible {
    guard context.verbose else { return "" }
    
    return body.format(context: context)
  }
}

struct Title: Printable {
  
  let body: Printable
  
  init(@PrintableBuilder body: () -> Printable) {
    self.body = body()
  }
  
  func format(context: PrintableContext) -> CustomStringConvertible {
    ForegroundColor(.green) { Bold {
      String(describing: body.format(context: context))
    } }
  }
}

struct Label: Printable {
  let text: Printable
  let body: Printable
  
  init(_ text: String, @PrintableBuilder body: () -> Printable) {
    self.text = text
    self.body = body()
  }
  
  func format(context: PrintableContext) -> CustomStringConvertible {
    Prism {
      Bold { "\(text.format(context: context))):" }
      String(describing: body.format(context: context))
    }
  }
}

struct Bullet: Printable {
  let body: Printable
  
  public init(@PrintableBuilder body: () -> Printable) {
    self.body = body()
  }
  
  func format(context: PrintableContext) -> CustomStringConvertible {
    "∙ \(body.format(context: context))"
  }
}

// MARK: Specific Type Printables

struct ID: Printable {
  let of: any Identifier
  
  init(of: any Identifier) {
    self.of = of
  }
  
  init(of: any Identified) {
    self.of = of.id
  }
  
  func format(context: PrintableContext) -> CustomStringConvertible {
    Prism {
      Bold { "ID:" }
      Italic { of.value }
    }
  }
}

extension Date: Printable {
  func format(context: PrintableContext) -> CustomStringConvertible {
    self.description
  }
}

extension Bool: Printable {
  func format(context: PrintableContext) -> CustomStringConvertible {
    yesNo
  }
}

// MARK: Print

func Print(verbose: Bool, @PrintableBuilder body: () -> Printable) {
  let context = PrintableContext(verbose: verbose)
  let result = body().format(context: context)
  print(result)
}

