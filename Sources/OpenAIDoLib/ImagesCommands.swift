import ArgumentParser
import Foundation
import OpenAIBits

// MARK: images

struct ImagesCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "images",
    abstract: "Commands relating to images.",
    subcommands: [
      ImagesCreateCommand.self,
      ImagesEditCommand.self,
      ImagesVariationCommand.self,
    ]
  )
}

/// Creates a filename given the `created` `Date`, image index, and prompt. It does not include a file extension.
///
/// - Parameters:
///   - created: The created date.
///   - index: The image index.
///   - prompt: The prompt that created the image.
/// - Returns: The filename.
fileprivate func imageName(created: Date, index: Int, prompt: String?) -> String {
  var result = ""
  
  let createdValue = ISO8601DateFormatter.string(from: created, timeZone: .current, formatOptions: [.withFullDate, .withFullTime])
  
  result.append(createdValue)
  
  let indexFormatter = NumberFormatter()
  indexFormatter.minimumIntegerDigits = 2
  if let indexValue = indexFormatter.string(for: index+1) {
    result.append(" (\(indexValue))")
  }
  
  if var prompt = prompt?[...] {
    result.append(" - ")
    if prompt.last == "." {
      prompt = prompt.dropLast(1)
    }
    result.append(String(prompt))
  }
  
  return result.whitespaceCondensed().sanitized(replacement: "_")
}

// MARK: create

struct ImagesCreateCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "create",
    abstract: "Creates one or more images given a prompt."
  )
  
  struct Help: InputHelp {
    
    static var inputValueHelp: String {
      "A text description of the desired image(s). The maximum length is 1000 characters."
    }
    
    static var inputFileHelp: String {
      "The path to a file containing the image input prompt to create generations for. Provide either this or --input, not both."
    }
  }
  
  @OptionGroup var input: InputOptions<Help>
  
  @Option(name: .short, help: """
  The number of images to generate. Must be between 1 and 10. (defaults to 1)
  """)
  var n: Int?
  
  @Option(help: "The size of the generated images. Must be one of '256x256', '512x512', or '1024x1024'. (defaults to '1024x1024')")
  var size: Images.Size?
  
  @Option(help: "The format in which the generated images are returned. Must be one of 'url' or 'data'. (defaults to 'data'")
  var responseFormat: Images.ResponseFormat?
  
  @Option(help: """
  A unique identifier representing your end-user, which will help OpenAI to monitor and detect abuse.
  """)
  var user: String?
  
  @Option(help: "The path to the output folder for generated images. (defaults to current working directory)")
  var outputFolder: String?
  
  @OptionGroup var toJson: ToJSONFrom<Generations>
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
  func validate() throws {
    if let n = n, n < 1 || n > 10 {
      throw ValidationError("-n must be between 1 and 10")
    }
  }
  
  func run() async throws {
    let client = client.new()
    let format = format.new()
    
    let prompt = try input.getValue()
    
    let result = try await client.call(Images.Create(
      prompt: prompt,
      n: n,
      size: size,
      responseFormat: responseFormat ?? .data,
      user: user
    ))
    
    if toJson.enabled {
      format.print(text: try toJson.encode(value: result))
    } else {
      let targetFolder = URL(fileURLWithPath: outputFolder ?? "")
      
      format.print(title: "Image Generations")
      format.print(label: "Input", value: prompt, verbose: true)
      format.print(label: "Size", value: size?.rawValue, verbose: true)
      
      format.print(subtitle: "Result", verbose: true)
      format.print(label: "Created", value: result.created, verbose: true)
      
      let indented = format.indented(by: 2)

      for (i, image) in result.images.enumerated() {
        
        format.print(section: "Image \(i+1)")
        if case let .url(url) = image {
          indented.print(label: "URL", value: url, verbose: true)
        }

        let filename = imageName(created: result.created, index: i, prompt: prompt)
        let fileUrl = URL(fileURLWithPath: "\(filename).png", relativeTo: targetFolder)
        
        do {
          let data = try image.getData()
          try image.getData().write(to: fileUrl)
          
          indented.print(label: "Path", value: fileUrl.absoluteString)
          
          let sizeValue = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .binary)
          
          indented.print(label: "Size", value: sizeValue)
        } catch {
          indented.print(error: "Unable to save image #\(i).")
          throw error
        }
      }
    }
  }
}

// MARK: edit

struct ImagesEditCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "edit",
    abstract: "Creates an edited or extended image given an original image and a prompt."
  )
  
  @Option(help: "The path to the image to edit. Must be a valid PNG file, less than 4MB, and square.")
  var image: String
  
  @Option(help: "An additional image whose fully transparent areas (e.g. where alpha is zero) indicate where image should be edited. Must be a valid PNG file, less than 4MB, and have the same dimensions as --image.")
  var mask: String
  
  struct Help: InputHelp {
    
    static var inputValueHelp: String {
      "A text description of the desired image(s). The maximum length is 1000 characters."
    }
    
    static var inputFileHelp: String {
      "The path to a file containing the image input prompt to create generations for. Provide either this or --input, not both."
    }
  }
  
  @OptionGroup var input: InputOptions<Help>
  
  @Option(name: .short, help: """
  The number of images to generate. Must be between 1 and 10. (defaults to 1)
  """)
  var n: Int?
  
  @Option(help: "The size of the generated images. Must be one of '256x256', '512x512', or '1024x1024'. (defaults to '1024x1024')")
  var size: Images.Size?
  
  @Option(help: "The format in which the generated images are returned. Must be one of 'url' or 'data'. (defaults to 'data'")
  var responseFormat: Images.ResponseFormat?
  
  @Option(help: """
  A unique identifier representing your end-user, which will help OpenAI to monitor and detect abuse.
  """)
  var user: String?
  
  @Option(help: "The path to the output folder for generated images. (defaults to current working directory)")
  var outputFolder: String?
  
  @OptionGroup var toJson: ToJSONFrom<Generations>
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
  func validate() throws {
    if let n = n, n < 1 || n > 10 {
      throw ValidationError("-n must be between 1 and 10")
    }
  }
  
  func run() async throws {
    let client = client.new()
    let format = format.new()
    
    let imageUrl = URL(fileURLWithPath: image)
    let imageData = try Data(contentsOf: imageUrl)
    
    let maskUrl = URL(fileURLWithPath: mask)
    let maskData = try Data(contentsOf: maskUrl)
    
    let prompt = try input.getValue()
    
    let result = try await client.call(Images.Edit(
      image: imageData,
      mask: maskData,
      prompt: prompt,
      n: n,
      size: size,
      responseFormat: responseFormat ?? .data,
      user: user
    ))
    
    if toJson.enabled {
      format.print(text: try toJson.encode(value: result))
    } else {
      let targetFolder = URL(fileURLWithPath: outputFolder ?? "")
      
      format.print(title: "Image Generations")
      format.print(label: "Input", value: prompt, verbose: true)
      format.print(label: "Size", value: size?.rawValue, verbose: true)
      
      format.print(subtitle: "Result", verbose: true)
      format.print(label: "Created", value: result.created, verbose: true)
      
      let indented = format.indented(by: 2)

      for (i, image) in result.images.enumerated() {
        
        format.print(section: "Image \(i+1)")
        if case let .url(url) = image {
          indented.print(label: "URL", value: url, verbose: true)
        }

        let filename = imageName(created: result.created, index: i, prompt: prompt)
        let fileUrl = URL(fileURLWithPath: "\(filename).png", relativeTo: targetFolder)
        
        do {
          let data = try image.getData()
          try image.getData().write(to: fileUrl)
          
          indented.print(label: "Path", value: fileUrl.absoluteString)
          
          let sizeValue = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .binary)
          
          indented.print(label: "Size", value: sizeValue)
        } catch {
          indented.print(error: "Unable to save image #\(i).")
          throw error
        }
      }
    }
  }
}

// MARK: variation

struct ImagesVariationCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "variation",
    abstract: "Creates a variation of a given image."
  )
  
  @Option(help: "The path to the image to edit. Must be a valid PNG file, less than 4MB, and square.", completion: .file(extensions: [".png"]))
  var image: String
  
  @Option(name: .short, help: """
  The number of images to generate. Must be between 1 and 10. (defaults to 1)
  """)
  var n: Int?
  
  @Option(help: "The size of the generated images. Must be one of '256x256', '512x512', or '1024x1024'. (defaults to '1024x1024')")
  var size: Images.Size?
  
  @Option(help: "The format in which the generated images are returned. Must be one of 'url' or 'data'. (defaults to 'data'")
  var responseFormat: Images.ResponseFormat?
  
  @Option(help: """
  A unique identifier representing your end-user, which will help OpenAI to monitor and detect abuse.
  """)
  var user: String?
  
  @Option(help: "The path to the output folder for generated images. (defaults to current working directory)")
  var outputFolder: String?
  
  @OptionGroup var toJson: ToJSONFrom<Generations>
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
  func validate() throws {
    if let n = n, n < 1 || n > 10 {
      throw ValidationError("-n must be between 1 and 10")
    }
  }
  
  func run() async throws {
    let client = client.new()
    let format = format.new()

    let imageUrl = URL(fileURLWithPath: image)
    let imageData = try Data(contentsOf: imageUrl)
    
    let result = try await client.call(Images.Variation(
      image: imageData,
      n: n,
      size: size,
      responseFormat: responseFormat ?? .data,
      user: user
    ))
    
    if toJson.enabled {
      format.print(text: try toJson.encode(value: result))
    } else {
      let targetFolder = URL(fileURLWithPath: outputFolder ?? "")
      
      format.print(title: "Image Variations")
      format.print(label: "Size", value: size?.rawValue, verbose: true)
      
      format.print(subtitle: "Result", verbose: true)
      format.print(label: "Created", value: result.created, verbose: true)
      
      let indented = format.indented(by: 2)

      for (i, image) in result.images.enumerated() {
        
        format.print(section: "Image \(i+1)")
        if case let .url(url) = image {
          indented.print(label: "URL", value: url, verbose: true)
        }

        let filename = imageName(created: result.created, index: i, prompt: nil)
        let fileUrl = URL(fileURLWithPath: "\(filename).png", relativeTo: targetFolder)
        
        do {
          let data = try image.getData()
          try image.getData().write(to: fileUrl)
          
          indented.print(label: "Path", value: fileUrl.absoluteString)
          
          let sizeValue = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .binary)
          
          indented.print(label: "Size", value: sizeValue)
        } catch {
          indented.print(error: "Unable to save image #\(i).")
          throw error
        }
      }
    }
  }
}
