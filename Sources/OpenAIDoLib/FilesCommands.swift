import ArgumentParser
import Foundation
import OpenAIBits

// MARK: files

struct FilesCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "files",
    abstract: "Used to manage documents that can be used with features like `fine-tunes`.",
    subcommands: [
      FilesListCommand.self,
      FilesDetailCommand.self,
      FilesUploadCommand.self,
      FilesDownloadCommand.self,
      FilesDeleteCommand.self,
    ]
  )
}

// MARK: list

struct FilesListCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "list",
    abstract: "List available files."
  )
  
  @OptionGroup var config: Config
  
  mutating func run() async throws {
    let client = config.client()
    let format = config.format()
    
    let files = try await client.call(Files.List())
        
    format.print(title: "Files:")
    format.print(list: files.data.sorted(by: { $0.id.value < $1.id.value }), with: Format.print(file:))
  }
}

// MARK: upload

struct FilesUploadCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "upload",
    abstract: "Upload a file that contains document(s) to be used across various endpoints/features. Currently, the size of all the files uploaded by one organization can be up to 1 GB. "
  )
  
  @Option(name: .shortAndLong, help: """
  Name of the JSON Lines file to be uploaded.

  If the purpose is set to 'fine-tune', each line is a JSON record with "prompt" and "completion" fields representing your training examples.
  """, completion: .file())
  var input: String
  
  @Option(name: .long, help: """
  The intended purpose of the uploaded documents.

  Use 'fine-tune' for Fine-tuning. This allows validation of the format of the uploaded file.
  """)
  var purpose: Files.Upload.Purpose
  
  @OptionGroup var config: Config
  
  mutating func run() async throws {
    let client = config.client()
    let format = config.format()
    
    let fileURL = URL(fileURLWithPath: input)
    
    let result = try await client.call(Files.Upload(purpose: purpose, file: fileURL))
    
    format.print(title: "File Detail")
    format.print(file: result)
  }
}

// MARK: detail

struct FilesDetailCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "detail",
    abstract: "Returns information about a specific file."
  )
  
  @Option(name: [.customLong("id"), .long], help: "The file ID.")
  var fileId: File.ID
  
  @OptionGroup var config: Config
  
  mutating func run() async throws {
    let client = config.client()
    let format = config.format()

    let file = try await client.call(Files.Details(id: fileId))
    
    format.print(title: "File Detail")
    format.print(file: file)
  }
}

/// MARK: download

struct FilesDownloadCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "download",
    abstract: "Returns the contents of the specified file."
  )
  
  @Option(name: [.customLong("id"), .long], help: "The file ID.")
  var fileId: File.ID
  
  @Option(name: .shortAndLong, help: """
  The name of the output file. Outputs to stdout by default.
  """, completion: .file())
  var output: String?
  
  @OptionGroup var config: Config
  
  mutating func run() async throws {
    let client = config.client()
    let format = config.format()
    
    let result = try await client.call(Files.Content(id: fileId))
    
    if let output = output {
      let outputURL = URL(fileURLWithPath: output)
      try result.data.write(to: outputURL)
      format.print(label: "File Saved:", value: output)
    } else {
      format.print(label: "File Name", value: result.filename)
      let outputString = String(data: result.data, encoding: .utf8)
      guard let outputString = outputString else {
        throw AppError("Unable to decode data file as UTF-8: \(fileId)")
      }
      format.print(subtitle: "File Content:")
      format.print(text: outputString)
    }
  }
}

// MARK: delete

struct FilesDeleteCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "delete",
    abstract: "Deletes an uploaded file permanently."
  )
  
  @Option(name: [.customLong("id"), .long], help: "The file ID.")
  var fileId: File.ID
  
  @OptionGroup var config: Config
  
  mutating func run() async throws {
    let client = config.client()
    let format = config.format()
    
    let result = try await client.call(Files.Delete(id: fileId))
    
    format.print(label: "File ID", value: result.id)
    format.print(label: "Deleted", value: result.deleted ? "yes" : "no")
  }
}
