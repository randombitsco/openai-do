import OpenAIBits

// MARK: Printer

/// A `Printer` will take a `value` and a ``Format`` and print it with that format.
typealias Printer<T> = (Format) -> (T) -> Void

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
  func indent(by count: Int) -> Format {
    Format(indent: indent.appending(String(repeating: " ", count: count)))
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
    print(text: text)
    print(text: String(repeating: char, count: text.count))
  }

  /// Prints the provided title text, underlined with `"="` on the next line.
  ///
  /// - Parameter title: The title text ``String``.
  func print(title text: CustomStringConvertible) {
    print(underline: text, with: "=")
  }

  /// Prints the provided subtitle text, underlined with `"-"` on the next line.
  ///
  /// - Parameter title: The title text ``String``.
  func print(subtitle text: String) {
    print(underline: text, with: "-")
  }

  /// Prints an item, with a subtitle leading it.
  ///
  /// - Parameters:
  ///   - item: The item to print.
  ///   - label: The prefix label (optional).
  ///   - index: The index of the item. Will have `+1` added to it before printing.
  ///   - printer: The ``Printer`` function to use to print the item.
  func print<T>(item: T, label: String? = nil, index: Int, with printer: Printer<T>) {
    var subtitle = ""
    if let label = label {
      subtitle += "\(label) "
    }
    subtitle += "#\(index + 1):"
    println()
    print(subtitle: subtitle)
    printer(self)(item)
  }

  func print<T>(list: [T], label: String? = nil, with printer: Printer<T>) {
    for (i, item) in list.enumerated() {
      print(item: item, label: label, index: i, with: printer)
    }
  }

  func print<T: CustomStringConvertible>(label: String, value: T) {
    print(text: "\(label): \(value)")
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

  func print(choice: Completions.Choice) {
    let border = String(repeating: "~", count: 40)

    print(label: "Logprobs", value: choice.logprobs, verbose: true)
    print(label: "Finish Reason", value: choice.finishReason)

    print(text: border)
    print(text: choice.text)
    print(text: border)
  }

  func print(completion: Completions.Response) {
    print(label: "ID", value: completion.id, verbose: true)
    print(label: "Created", value: completion.created, verbose: true)
    print(label: "Model", value: completion.model)

    println()
    print(list: completion.choices, label: "Choice", with: Format.print(choice:))

    Format.print(completion.usage as! CustomStringConvertible)
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

    let indented = indent(by: 2)
    if let events = fineTune.events, !events.isEmpty {
      println()
      print(subtitle: "Events:")
      for (i, event) in events.enumerated() {
        indented.print(item: event, index: i, with: Format.print(event:))
      }
    }

    if !fineTune.resultFiles.isEmpty {
      println()
      print(subtitle: "Result Files:")
      for (i, file) in fineTune.resultFiles.enumerated() {
        indented.print(item: file, label: "File", index: i, with: Format.print(file:))
      }
    }

    if !fineTune.validationFiles.isEmpty {
      println()
      print(subtitle: "Validation Files:")
      for (i, file) in fineTune.validationFiles.enumerated() {
        indented.print(item: file, label: "File", index: i, with: Format.print(file:))
      }
    }

    if !fineTune.trainingFiles.isEmpty {
      println()
      print(subtitle: "Training Files:")
      for (i, file) in fineTune.trainingFiles.enumerated() {
        indented.print(item: file, label: "File", index: i, with: Format.print(file:))
      }
    }
  }

  func print(model: Model) {
    print(label: "ID", value: model.id)
    print(label: "Created", value: model.created)
    print(label: "Owned By", value: model.ownedBy)
    print(label: "Fine-Tune", value: model.isFineTune ? "yes" : "no")
    print(label: "Root Model", value: model.root, verbose: true)
    print(label: "Parent Model", value: model.parent, verbose: true)
    print(label: "Supports Code", value: model.supportsCode, verbose: true)
    print(label: "Supports Edit", value: model.supportsEdit, verbose: true)
    print(label: "Supports Embedding", value: model.supportsEmbedding, verbose: true)
  }

  func print(moderationsResponse response: Moderations.Response) {
    let maxCategoryName = Moderations.Category.allCases.map { $0.rawValue.count }.max() ?? 0
    for (i, result) in response.results.enumerated() {
      print(text: "#\(i + 1): \(result.flagged ? "FLAGGED" : "Unflagged") ")
      for category in Moderations.Category.allCases {
        var output = "N/A"
        if let flagged = result.categories[category] {
          output = flagged ? "YES" : "no "
        }
        if let score = result.categoryScores[category] {
          output += " (\(score))"
        }
        let categoryName = "\(category):".padding(toLength: maxCategoryName + 1, withPad: " ", startingAt: 0)
        print(text: "\(categoryName) \(output)")
      }
    }
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
