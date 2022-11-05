// Additional `ExpressibleByArgument` extensions for `OpenAIBits` types.

import ArgumentParser
import Foundation
import OpenAIBits

// MARK: Completions.Stop

extension Completions.Stop: ExpressibleByArgument {
  public init?(argument: String) {
    self.init(argument)
  }
}

// MARK: File.ID

extension File.ID: ExpressibleByArgument {
  public init(argument: String) {
    self.init(argument)
  }
}

// MARK: Files.Upload.Purpose

extension Files.Upload.Purpose: ExpressibleByArgument {}

// MARK: FineTune.ID

extension FineTune.ID: ExpressibleByArgument {
  public init?(argument: String) {
    self.init(argument)
  }
}

// MARK: FineTune.Model

extension FineTune.Model: ExpressibleByArgument {}

// MARK: Model.ID

extension Model.ID: ExpressibleByArgument {
  public init(argument: String) {
    self.init(argument)
  }
}

// MARK: Penalty

extension Penalty: ExpressibleByArgument {
  public init?(argument: String) {
    guard let value = Decimal(string: argument) else {
      return nil
    }
    self.init(value)
  }
}

// MARK: Percentage

extension Percentage: ExpressibleByArgument {
  public init?(argument: String) {
    guard let value = Decimal(string: argument) else {
      return nil
    }
    self.init(value)
  }
}

// MARK: Images.Generations.Size

extension Images.Generations.Size: ExpressibleByArgument {
  public init?(argument: String) {
    self.init(rawValue: argument)
  }
}

// MARK: Images.Generations.ResponseFormat

extension Images.Generations.ResponseFormat: ExpressibleByArgument {
  public init?(argument: String) {
    self.init(rawValue: argument)
  }
}
