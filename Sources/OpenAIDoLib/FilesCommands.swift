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
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
  mutating func run() async throws {
    let client = client.new()
    let format = format.new()
    
    let files = try await client.call(Files.List())
        
    format.print(title: "Files List")
    format.print(list: files.data.sorted(by: { $0.id.value < $1.id.value }), with: Format.print(file:))
  }
}

// MARK: upload

struct FilesUploadCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "upload",
    abstract: "Upload a file that contains document(s) to be used across various endpoints/features. Currently, the size of all the files uploaded by one organization can be up to 1 GB."
  )
  
  @Option(help: """
  Name of the JSON Lines file to be uploaded.

  If the purpose is set to 'fine-tune', each line is a JSON record with "prompt" and "completion" fields representing your training examples.
  """, completion: .file())
  var inputFile: String
  
  @Option(name: .long, help: """
  The intended purpose of the uploaded documents.

  Use "fine-tune" for Fine-tuning. This allows validation of the format of the uploaded file.
  """)
  var purpose: Files.Upload.Purpose
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
  mutating func run() async throws {
    let client = client.new()
    let format = format.new()
    
    let fileURL = URL(fileURLWithPath: inputFile)
    
    let result = try await client.call(Files.Upload(purpose: purpose, url: fileURL))
    
    format.print(title: "File Upload")
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
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
  mutating func run() async throws {
    let client = client.new()
    let format = format.new()

    let file = try await client.call(Files.Detail(id: fileId))
    
    format.print(title: "File Detail")
    format.print(id: file)
    format.print(file: file)
  }
}

// MARK: download

struct FilesDownloadCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "download",
    abstract: "Returns the contents of the specified file."
  )
  
  @Option(help: "The file ID.")
  var fileId: File.ID
  
  @Option(help: """
  The name of the output file. Outputs to stdout by default.
  """, completion: .file())
  var outputFile: String?
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
  mutating func run() async throws {
    let client = client.new()
    let format = format.new()
    
    let result = try await client.call(Files.Content(id: fileId))
    
    format.print(title: "File Download")
    format.print(label: "Filename", value: result.filename)
    
    if format.showVerbose || outputFile == nil {
      format.println()
      let outputString = String(data: result.data, encoding: .utf8)
      guard let outputString = outputString else {
        throw AppError("Unable to decode data file as UTF-8: \(fileId)")
      }
      format.print(section: "Content")
      format.print(textBlock: outputString)
    }

    if let outputFile = outputFile {
      format.println()
      
      let outputURL = URL(fileURLWithPath: outputFile)
      try result.data.write(to: outputURL)
      
      format.print(label: "Saved To", value: outputFile)
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
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
  mutating func run() async throws {
    let client = client.new()
    let format = format.new()
    
    let result = try await client.call(Files.Delete(id: fileId))
    
    format.print(label: "File ID", value: result.id)
    format.print(label: "Deleted", value: result.deleted ? "yes" : "no")
  }
}
