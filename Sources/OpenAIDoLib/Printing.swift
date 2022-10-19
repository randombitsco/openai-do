import OpenAIBits
import Prism

// MARK: Printer

/// A `Printer` takes a ``Format``, and returns a function that accepts a `T` value, and prints with that format.
/// The simplest way to create one is via a `KeyPath` reference to a ``Format`` method, eg: `Format.print(model:)`
typealias Printer<T> = (Format) -> (T) -> Void

/// A `Labeller` takes a type and returns a function that accepts an `Int` value for the index, and returns
/// a `String` representing the label for the item.
typealias Labeller<T> = (T) -> CustomStringConvertible

// MARK: Format

struct Format {
  
  /// The base function called to print text. It will print whatever is provided, with no terminator.
  /// The default implementation calls ``Swift.print(_:separator:terminator)``.
  ///
  /// - Parameter item: The item to print.
  static var print: (_ item: CustomStringConvertible) -> Void = {
    Swift.print(String(describing: $0), terminator: "")
  }
  
  /// The basic ``Format``, no indentation, not verbose.
  static let `default` = Format()
  
  /// A ``Format`` which is verbose by default.
  static let verbose = Format(showVerbose: true)
  
  /// Returns a new ``Format`` with an `indent` of the specified number of spaces.
  ///
  /// - Parameter count: The number of spaces to indent by.
  /// - Returns a new ``Format`` with additional indentation.
  static func indent(by count: Int) -> Format {
    Format(indent: String(repeating: " ", count: count))
  }
  
  /// The current indentation ``String``.
  let indent: String
  
  /// If true, verbose values will be output.
  let showVerbose: Bool
  
  /// Creates a new ``Format``.
  ///
  /// - Parameter indent: The indent ``String``.
  init(indent: String = "", showVerbose: Bool = false) {
    self.indent = indent
    self.showVerbose = showVerbose
  }
  
  /// Creates a new ``Format`` with the indentation increased by the specified `count`.
  ///
  /// - Parameter count: the number of spaces to increase the increment by.
  /// - Returns the new ``Format`` with the indentation increased.
  func indented(by count: Int) -> Format {
    Format(indent: indent.appending(String(repeating: " ", count: count)), showVerbose: showVerbose)
  }
  
  /// A ``Format`` with the same settings, where ``showVerbose`` is `true`.
  var verbose: Format {
    guard showVerbose else {
      return Format(indent: indent, showVerbose: true)
    }
    return self
  }
  
  // MARK: General Print Functions
  
  /// Prints a line of text with the specified ``Format``.
  ///
  /// - Parameter text: The text to print.
  func print(text: CustomStringConvertible) {
    Format.print("\(indent)\(text)\n")
  }
  
  /// Prints a blank line.
  func println() {
    Format.print("\n")
  }
  
  /// Prints the provided text, underlined on the next line with the `char` character matching the text length.
  ///
  /// - Parameter underline: The text of the title.
  /// - Parameter with: The ``Character`` to use for the underline (eg. `"="`).
  func print(underline text: CustomStringConvertible, with char: Character) {
    let text = String(describing: text)
    print(text: Underline { text })
    //    print(text: String(repeating: char, count: text.count))
  }
  
  /// Prints the provided text as a stronger "title".
  ///
  /// - Parameter title: The title text ``String``.
  func print(title text: CustomStringConvertible) {
    print(text: ForegroundColor(.green) { Bold { String(describing: text) } })
  }
  
  /// Prints the provided text as a "subtitle".
  ///
  /// - Parameter title: The title text ``String``.
  func print(subtitle text: CustomStringConvertible) {
    print(text: Italic { String(describing: text) })
  }
  
  /// Prints the provided text, prefixed with a bullet-point character.
  ///
  /// - Parameter bullet: The text to print.
  func print(bullet text: CustomStringConvertible) {
    print(text: "∙ \(text)")
  }
  
  /// Prints the provided text as a log entry.
  ///
  /// - Parameter log: The text to log.
  func print(log text: CustomStringConvertible) {
    print(text: ForegroundColor(.yellow) { "> \(text)" } )
  }

  /// Prints a list of `T` values, using the provided `printer`.
  ///
  /// - Parameters:
  ///   - list: The list of values.
  ///   - label: (optional) label to print before the
  func print<T>(list: [T], itemLabel: (Int) -> Labeller<T> = { index in { _ in "#\(index)"}}, with printer: Printer<T>) {
    for (i, item) in list.enumerated() {
      print(item: item, label: itemLabel(i), with: printer)
    }
  }
  
  /// Prints a list of `T` values, using the provided `label` and `printer`.
  ///
  /// - Parameters:
  ///   - list: The list to print.
  ///   - label: The ``Labeller`` to print with.
  ///   - printer: The ``Printer`` to print with.
  func print<T>(list: [T], label: @escaping Labeller<T>, with printer: Printer<T>) {
    print(list: list, itemLabel: { _ in label }, with: printer)
  }
  
  /// Prints the list of `T` values that are `OpenAIDo.Identified`, using the label.
  ///
  /// - Parameters:
  ///   - list: The list of items to print.
  ///   - printer: The ``Printer`` to print the item with.
  func print<T>(list: [T], with printer: Printer<T>) where T: Identified {
    print(list: list, label: \.label, with: printer)
  }

  /// Prints an item, with a subtitle leading it.
  ///
  /// - Parameters:
  ///   - item: The item to print.
  ///   - label: The prefix label (optional).
  ///   - index: The index of the item. Will have `+1` added to it before printing.
  ///   - printer: The ``Printer`` function to use to print the item.
  func print<T>(item: T, label: Labeller<T>, with printer: Printer<T>) {
    print(text: label(item))
    printer(indented(by: 2))(item)
  }

  func print<T: CustomStringConvertible>(label: String, value: T) {
    print(text: Prism {
      Bold { "\(label):" }
      String(describing: value)
    })
  }

  enum WhenNil {
    case skip
    case print(String)
  }

  func print<T: CustomStringConvertible>(label: String, value: T?, verbose: Bool = false, whenNil: WhenNil = .skip) {
    guard !verbose || showVerbose else {
      return
    }

    if let value = value {
      print(label: label, value: value)
    } else {
      switch whenNil {
      case .skip: break
      case .print(let value):
        print(label: label, value: value)
      }
    }
  }

  // MARK: Printers for specific types.

  func print(choice: Completion.Choice) {
    let border = String(repeating: "~", count: 40)

    print(label: "Logprobs", value: choice.logprobs, verbose: true)
    print(label: "Finish Reason", value: choice.finishReason)

    print(text: border)
    print(text: choice.text)
    print(text: border)
  }

  func print(completion: Completion) {
    print(label: "ID", value: completion.id, verbose: true)
    print(label: "Created", value: completion.created, verbose: true)
    print(label: "Model", value: completion.model)

    print(subtitle: "Choices:")
    print(list: completion.choices, with: Format.print(choice:))

    print(usage: completion.usage)
  }

  func print(event: FineTune.Event) {
    print(label: "Created At", value: event.createdAt)
    print(label: "Level", value: event.level)
    print(label: "Message", value: event.level)
  }

  func print(file: File) {
    print(label: "ID", value: file.id)
    print(label: "Filename", value: file.filename)
    print(label: "Purpose", value: file.purpose)
    print(label: "Bytes", value: file.bytes)
    print(label: "Status", value: file.status)
    print(label: "Status Details", value: file.statusDetails)
    print(label: "Created At", value: file.createdAt)
  }

  func print(fineTune: FineTune) {
    print(label: "ID", value: fineTune.id)
    print(label: "Model", value: fineTune.model)
    print(label: "Fine-Tuned Model", value: fineTune.fineTunedModel)
    print(label: "Organization", value: fineTune.organizationId, verbose: true)
    print(label: "Status", value: fineTune.status)
    print(label: "Created At", value: fineTune.createdAt)
    print(label: "Updated At", value: fineTune.updatedAt)
    print(label: "Batch Size", value: fineTune.hyperparams.batchSize, verbose: true)
    print(label: "Learning Rate Multiplier", value: fineTune.hyperparams.learningRateMultiplier, verbose: true)
    print(label: "N-Epochs", value: fineTune.hyperparams.nEpochs, verbose: true)
    print(label: "Prompt Loss Weight", value: fineTune.hyperparams.promptLossWeight, verbose: true)

    let indented = indented(by: 2)
    if let events = fineTune.events, !events.isEmpty {
      println()
      print(subtitle: "Events:")
      indented.print(list: events, with: Format.print(event:))
    }

    if !fineTune.resultFiles.isEmpty {
      println()
      print(subtitle: "Result Files:")
      indented.print(list: fineTune.resultFiles, with: Format.print(file:))
    }

    if !fineTune.validationFiles.isEmpty {
      println()
      print(subtitle: "Validation Files:")
      indented.print(list: fineTune.validationFiles, with: Format.print(file:))
    }

    if !fineTune.trainingFiles.isEmpty {
      println()
      print(subtitle: "Training Files:")
      indented.print(list: fineTune.trainingFiles, with: Format.print(file:))
    }
  }
  
  func print<T: Identifier>(id: T) {
    print(label: "ID", value: Italic { id.value })
  }
  
  func print<T: Identified>(id identified: T) {
    print(id: identified.id)
  }

  func print(model: Model) {
    print(label: "Created", value: model.created, verbose: true)
    print(label: "Owned By", value: model.ownedBy, verbose: true)
    print(label: "Is Fine-Tune", value: model.isFineTune.yesNo)
    print(label: "Root Model", value: model.root, verbose: true)
    print(label: "Parent Model", value: model.parent, verbose: true)
    print(label: "Supports Code", value: model.supportsCode.yesNo)
    print(label: "Supports Edit", value: model.supportsEdit.yesNo)
    print(label: "Supports Embedding", value: model.supportsEmbedding.yesNo)
    
    print(label: "Permissions", value: "")
    indented(by: 2).print(list: model.permission, with: Format.print(permission:))
  }

  func print(moderation response: Moderation) {
    let maxCategoryName = Moderation.Category.allCases.map { $0.rawValue.count }.max() ?? 0
    for (i, result) in response.results.enumerated() {
      print(text: "#\(i + 1): \(result.flagged ? "FLAGGED" : "Unflagged") ")
      for category in Moderation.Category.allCases {
        var output = "N/A"
        if let flagged = result.categories?[category] {
          output = flagged ? "YES" : "no "
        }
        if let score = result.categoryScores?[category] {
          output += " (\(score))"
        }
        let categoryName = "\(category):".padding(toLength: maxCategoryName + 1, withPad: " ", startingAt: 0)
        print(text: "\(categoryName) \(output)")
      }
    }
  }
  
  func print(permission: Model.Permission) {
    print(label: "Created", value: permission.created, verbose: true)
    print(label: "Is Blocking", value: permission.isBlocking.yesNo)
    print(label: "Allow View", value: permission.allowView)
    print(label: "Allow Logprobs", value: permission.allowLogprobs.yesNo)
    print(label: "Allow Fine-Tuning", value: permission.allowFineTuning.yesNo)
    print(label: "Allow Create Engine", value: permission.allowCreateEngine.yesNo, verbose: true)
    print(label: "Allow Sampling", value: permission.allowSampling.yesNo, verbose: true)
    print(label: "Allow Search Indices", value: permission.allowSearchIndices.yesNo, verbose: true)
    print(label: "Organization", value: permission.organization, verbose: true)
    print(label: "Group", value: permission.group, verbose: true)
  }

  func print(usage: Usage?) {
    guard let usage = usage else { return }
    println()
    print(label: "Tokens Used", value: "Prompt: \(usage.promptTokens); Completion: \(usage.completionTokens ?? 0); Total: \(usage.totalTokens)")
  }
}

extension Format {
  func print<T: Encodable>(asJson value: T, pretty: Bool = false) {
    do {
      let json = try jsonEncode(value, pretty: pretty)
      print(text: json)
    } catch {
      let message = "{\"error\": \"\(String(describing: error))\"}"
      print(text: message)
    }
  }
}

extension Bool {
  var yesNo: String { self ? "yes" : "no" }
}

extension Identified {
  /// Creates a label for the `Identified` as a string, using the `id`'s `value`.
  var label: CustomStringConvertible {
    Prism {
      Bold { "ID:"}
      Italic { id.value }
    }
  }
}
