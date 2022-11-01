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
  static let `default` = Format(indent: "", showVerbose: false, showDebug: false)
  
  /// A ``Format`` which is verbose by default.
  static let verbose = Format(indent: "", showVerbose: true, showDebug: false)
  
  /// A ``Format`` which is showing logs by default.
  static let debug = Format(indent: "", showVerbose: false, showDebug: true)
  
  /// Returns a new ``Format`` with an `indent` of the specified number of spaces.
  ///
  /// - Parameter count: The number of spaces to indent by.
  /// - Returns a new ``Format`` with additional indentation.
  static func indent(by count: Int) -> Format {
    Format(indent: String(repeating: " ", count: count), showVerbose: false, showDebug: false)
  }
  
  /// The current indentation ``String``.
  let indent: String
  
  /// If `true`, verbose values will be output.
  let showVerbose: Bool
  
  /// If `true`, logs will be output.
  let showDebug: Bool
  
  /// Creates a new ``Format``.
  ///
  /// - Parameter indent: The indent ``String``.
  /// - Parameter showVerbose: If `true`, verbose items will be shown.
  /// - Parameter showDebug: If `true`, debug logs will be shown.
  init(indent: String, showVerbose: Bool, showDebug: Bool) {
    self.indent = indent
    self.showVerbose = showVerbose
    self.showDebug = showDebug
  }
  
  /// Creates a new ``Format`` with the indentation increased by the specified `count`.
  ///
  /// - Parameter count: the number of spaces to increase the increment by.
  /// - Returns the new ``Format`` with the indentation increased.
  func indented(by count: Int) -> Format {
    Format(indent: indent.appending(String(repeating: " ", count: count)), showVerbose: showVerbose, showDebug: showDebug)
  }
  
  /// A ``Format`` with the same settings, where ``showVerbose`` is `true`.
  var verbose: Format {
    guard showVerbose else {
      return Format(indent: indent, showVerbose: true, showDebug: showDebug)
    }
    return self
  }
  
  /// A ``Format`` with the same settings, where `showDebug` is `true`.
  var debug: Format {
    guard showDebug else {
      return Format(indent: indent, showVerbose: showVerbose, showDebug: true)
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
  ///
  /// - Parameter verbose: If `true`, will only print when `showVerbose` is `true`. Defaults to `false`.
  func println(verbose: Bool = false) {
    guard !verbose || showVerbose else { return }
    Format.print("\n")
  }
  
  /// Generates a horizontal border `String` with the specified number of characters,
  /// optionally specifying the character to repeat.
  ///
  /// - Parameters:
  ///   - count: The number of characters in the border (minimum of 1)
  ///   - of: The `Character` to repeat (defaults to `" "`).
  /// - Returns: The border characters.
  static func border(_ count: Int, of: Character = " ") -> String {
    String(repeating: of, count: max(count, 1))
  }
  
  /// Prints a horizontal border block, indented by the current amount.
  ///
  /// - Parameter count: The number of characters to have in the border.
  /// - Parameter borderChar: The `Character` to repeat in the border. Defaults to " ".
  func print(border count: Int, of borderChar: Character = " ") {
    let border = Strikethrough { Self.border(count, of: borderChar) }
    print(text: border)
  }
  
  /// Prints a potentially multi-line block of text. It will have a border before and after to visually indicate
  /// the beginning and end of the block.
  ///
  /// - Parameter textBlock: The text to print.
  func print(textBlock: CustomStringConvertible, verbose: Bool = false) {
    guard !verbose || showVerbose else { return }
    
    let lines = textBlock.description.split(separator: "\n")
    let borderLength = lines.map(\.count).max() ?? 0
    let indented = lines.joined(separator: "\n\(indent)")
    
    print(border: borderLength)
    print(text: indented)
    print(border: borderLength)
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
    println()
  }
  
  /// Prints the provided text as a "subtitle".
  ///
  /// - Parameter title: The title text ``String``.
  func print(subtitle text: CustomStringConvertible) {
    print(text: Italic { String(describing: text) })
  }
  
  /// Prints a section title. Typically used for sub-sections within a value.
  /// - Parameter text: The section title.
  func print(section text: String, verbose: Bool = false) {
    guard !verbose || showVerbose else { return }
    print(text: Bold { "\(text):" })
  }
  
  /// Prints the provided text, prefixed with a bullet-point character.
  ///
  /// - Parameter bullet: The text to print.
  func print(bullet text: CustomStringConvertible) {
    print(text: "∙ \(text)")
  }
  
  /// Prints the provided text as a log entry, if ``showDebug`` is `true`.
  ///
  /// - Parameter log: The text to log.
  func print(log text: @autoclosure () -> CustomStringConvertible) {
    guard showDebug else { return }
    print(text: ForegroundColor(.yellow) { "> \(text())" } )
  }

  /// Prints a list of `T` values, using the provided `printer`.
  ///
  /// - Parameters:
  ///   - list: The list of values.
  ///   - label: (optional) label to print before the
  func print<T>(list: [T], itemLabel: (Int) -> Labeller<T> = { index in { _ in "#\(index+1):"}}, with printer: Printer<T>) {
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
  func print<T>(list: [T], with printer: Printer<T>) where T: Identifiable {
    print(list: list, label: \.label, with: printer)
  }
  
  func print<K,V>(dictionary: [K:V]) where K: CustomStringConvertible, K: Comparable, V: CustomStringConvertible {
    for k in dictionary.keys.sorted() {
      print(label: String(describing: k), value: dictionary[k])
    }
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

  func print<T: CustomStringConvertible>(label: String, value: T, verbose: Bool = false) {
    guard !verbose || showVerbose else {
      return
    }
    
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

  func print(label: String, value: Bool, verbose: Bool = false) {
    print(label: label, value: value.yesNo, verbose: verbose)
  }

  func print(label: String, value: Bool?, verbose: Bool = false, whenNil: WhenNil = .skip) {
    print(label: label, value: value?.yesNo, verbose: verbose, whenNil: whenNil)
  }

  // MARK: Printers for specific types.

  func print(completion: Completion) {
    print(label: "ID", value: completion.id, verbose: true)
    print(label: "Created", value: completion.created, verbose: true)
    print(label: "Model", value: completion.model)

    if completion.choices.count == 1,
       let choice = completion.choices.first {
      print(choice: choice)
    } else {
      print(section: "Choices")
      print(list: completion.choices, with: Format.print(choice:))
    }

    print(usage: completion.usage)
  }

  func print(choice: Completion.Choice) {
    print(section: "Text")
    print(textBlock: choice.text)
    print(label: "Finish Reason", value: choice.finishReason)

    if let logprobs = choice.logprobs {
      print(section: "Logprobs")
      print(logprobs: logprobs)
    }
  }
  
  func print(edit: Edit) {
    print(label: "Created", value: edit.created, verbose: true)
    
    if edit.choices.count == 1, let choice = edit.choices.first {
      print(choice: choice)
    } else {
      print(section: "Choices")
      print(list: edit.choices, with: Format.print(choice:))
    }
    
    print(usage: edit.usage)
  }

  func print(choice: Edit.Choice) {
    print(section: "Text")
    print(textBlock: choice.text)
  }

  func print(event: FineTune.Event) {
    print(label: "Created At", value: event.createdAt)
    print(label: "Level", value: event.level)
    print(label: "Message", value: event.level)
  }

  func print(file: File) {
    print(label: "Filename", value: file.filename)
    print(label: "Purpose", value: file.purpose)
    print(label: "Bytes", value: file.bytes)
    print(label: "Status", value: file.status)
    print(label: "Status Details", value: file.statusDetails)
    print(label: "Created At", value: file.createdAt)
  }

  func print(fineTune: FineTune) {
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
      print(section: "Events")
      indented.print(list: events, with: Format.print(event:))
    }

    if !fineTune.resultFiles.isEmpty {
      println()
      print(section: "Result Files")
      indented.print(list: fineTune.resultFiles, with: Format.print(file:))
    }

    if !fineTune.validationFiles.isEmpty {
      println()
      print(section: "Validation Files")
      indented.print(list: fineTune.validationFiles, with: Format.print(file:))
    }

    if !fineTune.trainingFiles.isEmpty {
      println()
      print(section: "Training Files")
      indented.print(list: fineTune.trainingFiles, with: Format.print(file:))
    }
  }
  
  func print<T: Identifier>(id: T) {
    print(label: "ID", value: Italic { id.value })
  }
  
  func print<T: Identifiable>(id identifiable: T) where T.ID: Identifier {
    print(id: identifiable.id)
  }
  
  func print(logprobs: Logprobs) {
    let count = logprobs.tokens.count
    let indented = indented(by: 2)
    
    for i in 0..<count {
      print(section: "#\(i+1)")
      indented.print(label: "Token", value: logprobs.tokens[i].debugDescription)
      indented.print(label: "Token Logprobs", value: logprobs.tokenLogprobs[i])
      if showVerbose {
        let value = logprobs.topLogprobs[i].enumerated()
          .sorted(by: { left, right in
            left.element.value > right.element.value
          })
          .map { value in
            "\(value.element.key.debugDescription): \(value.element.value)"
          }
          .joined(separator: ", ")
        indented.print(label: "Top Logprobs", value: value)
        
//        var topLogprobs = [String: Double]()
//        for (k, v) in logprobs.topLogprobs[i] {
//          topLogprobs[k.debugDescription] = v
//        }
//        indented.print(section: "Top Logprobs")
//        indented.indented(by: 2).print(dictionary: topLogprobs)
      }
      indented.print(label: "Text Offset", value: logprobs.textOffset[i])
    }
  }

  func print(model: Model) {
    print(label: "Created", value: model.created, verbose: true)
    print(label: "Owned By", value: model.ownedBy, verbose: true)
    print(label: "Root Model", value: model.root, verbose: true)
    print(label: "Parent Model", value: model.parent, verbose: true)
    print(label: "Is Fine-Tune", value: model.isFineTune)
    print(label: "Supports Code", value: model.supportsCode)
    print(label: "Supports Edit", value: model.supportsEdit)
    print(label: "Supports Embedding", value: model.supportsEmbedding)
    
    print(section: "Permissions")
    indented(by: 2).print(list: model.permission, with: Format.print(permission:))
  }

  func print(moderation: Moderation) {
    print(label: "ID", value: moderation.id, verbose: true)
    print(label: "Model", value: moderation.model, verbose: true)
    println(verbose: true)
    
    if moderation.results.count == 1, let result = moderation.results.first {
      print(label: "Result", value: result.flagged ? ForegroundColor(.red) { "FLAGGED" } : ForegroundColor(.green) { "Unflagged" } )
      print(moderationResult: result)
    } else {
      for (i, result) in moderation.results.enumerated() {
        print(label: "Result #\(i + 1)", value: result.flagged ? ForegroundColor(.red) { "FLAGGED" } : ForegroundColor(.green) { "Unflagged" })
        print(moderationResult: result)
      }
    }
  }
  
  func print(moderationResult result: Moderation.Result) {
    let maxCategoryName = Moderation.Category.allCases.map { $0.rawValue.count }.max() ?? 0
    
    for category in Moderation.Category.allCases {
      var output = "N/A"
      if let flagged = result.categories?[category] {
        output = String(describing: flagged ? ForegroundColor(.red) { "YES" } : ForegroundColor(.green) { "no " })
      }
      if showVerbose, let score = result.categoryScores?[category] {
        output += " (\(score))"
      }
      let categoryName = Bold { "\(category):".padding(toLength: maxCategoryName + 1, withPad: " ", startingAt: 0) }
      print(bullet: "\(categoryName) \(output)")
    }
  }
  
  func print(permission: Model.Permission) {
    print(label: "Created", value: permission.created, verbose: true)
    print(label: "Is Blocking", value: permission.isBlocking)
    print(label: "Allow View", value: permission.allowView)
    print(label: "Allow Logprobs", value: permission.allowLogprobs)
    print(label: "Allow Fine-Tuning", value: permission.allowFineTuning)
    print(label: "Allow Sampling", value: permission.allowSampling, verbose: true)
    print(label: "Allow Search Indices", value: permission.allowSearchIndices, verbose: true)
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

extension Identifiable {
  /// Creates a label for the `Identified` as a string, using the `id`'s `value`.
  var label: CustomStringConvertible {
    Prism {
      Bold { "ID:"}
      Italic { String(describing: id) }
    }
  }
}
