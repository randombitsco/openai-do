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
    ]
  )
}

// MARK: generations

struct ImagesCreateCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "generations",
    abstract: "Creates an image given a prompt."
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
  var size: Images.Generations.Size?
  
  @Option(help: "The format in which the generated images are returned. Must be one of 'url' or 'b64_json'. (defaults to 'url'")
  var responseFormat: Images.Generations.ResponseFormat?
  
  @Option(help: """
  A unique identifier representing your end-user, which will help OpenAI to monitor and detect abuse.
  """)
  var user: String?
  
  @OptionGroup var toJson: ToJSONFrom<Image>
  
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
    
    let generations = Images.Generations(
      prompt: prompt,
      n: n,
      size: size,
      responseFormat: responseFormat,
      user: user
    )
    
    let result = try await client.call(generations)
    
    if toJson.enabled {
      format.print(text: try toJson.encode(value: result))
    } else {
      format.print(title: "Image Generations")
      format.print(image: result)
    }
  }
}
