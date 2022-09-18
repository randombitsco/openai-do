import OpenAIBits

// MARK: Printer

/// A `Printer` will take a `value` and a ``Format`` and print it with that format.
typealias Printer<T> = (_ value: T, _ format: Format) -> Void

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
    subtitle += "#\(index+1):"
    println()
    print(subtitle: subtitle)
    printer(item, self)
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
}

// MARK: Printers for specific types.

func print(choice: Completions.Choice, format: Format) {
  let border = String(repeating: "~", count: 40)
  
  format.print(label: "Logprobs", value: choice.logprobs, verbose: true)
  format.print(label: "Finish Reason", value: choice.finishReason)
  
  format.print(text: border)
  print(choice.text)
  format.print(text: border)
}

func print(completion: Completions.Response, format: Format) {
  format.print(label: "ID", value: completion.id, verbose: true)
  format.print(label: "Created", value: completion.created, verbose: true)
  format.print(label: "Model", value: completion.model)
  
  format.println()
  format.print(list: completion.choices, label: "Choice", with: print(choice:format:))
  
  format.print(usage: completion.usage)
}

func print(event: FineTune.Event, format: Format) {
  format.print(label: "Created At", value: event.createdAt)
  format.print(label: "Level", value: event.level)
  format.print(label: "Message", value: event.level)
}

func print(file: File, format: Format) {
  format.print(label: "ID", value: file.id)
  format.print(label: "Filename", value: file.filename)
  format.print(label: "Purpose", value: file.purpose)
  format.print(label: "Bytes", value: file.bytes)
  format.print(label: "Status", value: file.status)
  format.print(label: "Status Details", value: file.statusDetails)
  format.print(label: "Created At", value: file.createdAt)
}

func print(fineTune: FineTune, format: Format) {
  format.print(label: "ID", value: fineTune.id)
  format.print(label: "Model", value: fineTune.model)
  format.print(label: "Fine-Tuned Model", value: fineTune.fineTunedModel)
  format.print(label: "Organization", value: fineTune.organizationId, verbose: true)
  format.print(label: "Status", value: fineTune.status)
  format.print(label: "Created At", value: fineTune.createdAt)
  format.print(label: "Updated At", value: fineTune.updatedAt)
  format.print(label: "Batch Size", value: fineTune.hyperparams.batchSize, verbose: true)
  format.print(label: "Learning Rate Multiplier", value: fineTune.hyperparams.learningRateMultiplier, verbose: true)
  format.print(label: "N-Epochs", value: fineTune.hyperparams.nEpochs, verbose: true)
  format.print(label: "Prompt Loss Weight", value: fineTune.hyperparams.promptLossWeight, verbose: true)
  
  let indented = format.indent(by: 2)
  if let events = fineTune.events, !events.isEmpty {
    format.println()
    format.print(subtitle: "Events:")
    for (i, event) in events.enumerated() {
      indented.print(item: event, index: i, with: print(event:format:))
    }
  }
  
  if !fineTune.resultFiles.isEmpty {
    format.println()
    format.print(subtitle: "Result Files:")
    for (i, file) in fineTune.resultFiles.enumerated() {
      indented.print(item: file, label: "File", index: i, with: print(file:format:))
    }
  }
  
  if !fineTune.validationFiles.isEmpty {
    format.println()
    format.print(subtitle: "Validation Files:")
    for (i, file) in fineTune.validationFiles.enumerated() {
      indented.print(item: file, label: "File", index: i, with: print(file:format:))
    }
  }
  
  if !fineTune.trainingFiles.isEmpty {
    format.println()
    format.print(subtitle: "Training Files:")
    for (i, file) in fineTune.trainingFiles.enumerated() {
      indented.print(item: file, label: "File", index: i, with: print(file:format:))
    }
  }
}

func print(model: Model, format: Format) {
  format.print(label: "ID", value: model.id)
  format.print(label: "Created", value: model.created)
  format.print(label: "Owned By", value: model.ownedBy)
  format.print(label: "Fine-Tune", value: model.isFineTune ? "yes" : "no")
  format.print(label: "Root Model", value: model.root, verbose: true)
  format.print(label: "Parent Model", value: model.parent, verbose: true)
  format.print(label: "Supports Code", value: model.supportsCode, verbose: true)
  format.print(label: "Supports Edit", value: model.supportsEdit, verbose: true)
  format.print(label: "Supports Embedding", value: model.supportsEmbedding, verbose: true)
}

func print(moderationsResponse response: Moderations.Response, format: Format) {
  let maxCategoryName = Moderations.Category.allCases.map { $0.rawValue.count }.max() ?? 0
  for (i, result) in response.results.enumerated() {
    format.print(text: "#\(i+1): \(result.flagged ? "FLAGGED" : "Unflagged") ")
    for category in Moderations.Category.allCases {
      var output = "N/A"
      if let flagged = result.categories[category] {
        output = flagged ? "YES" : "no "
      }
      if let score = result.categoryScores[category] {
        output += " (\(score))"
      }
      let categoryName = "\(category):".padding(toLength: maxCategoryName+1, withPad: " ", startingAt: 0)
      format.print(text: "\(categoryName) \(output)")
    }
  }
}

extension Format {
  func print(usage: Usage?) {
    guard let usage = usage else { return }
    println()
    print(label: "Tokens Used", value: "Prompt: \(usage.promptTokens); Completion: \(usage.completionTokens ?? 0); Total: \(usage.totalTokens)")
  }
}
