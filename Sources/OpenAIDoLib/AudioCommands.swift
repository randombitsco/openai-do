import ArgumentParser
import Foundation
import OpenAIBits

// MARK: images

struct AudioCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "audio",
    abstract: "Commands relating to audio.",
    subcommands: [
      AudioTranscriptionsCommand.self,
      AudioTranslationsCommand.self,
    ]
  )
}

// MARK: transcription

struct AudioTranscriptionsCommand: AsyncParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: "transcriptions",
    abstract: "Transcribes an audio recording."
  )
  
  /// The path to the input text file.
  @Option(name: [.customLong("audio-file")], help: "The file containing the audio to transcribe, in one of these formats: `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `wav`, or `webm`.", completion: .file())
  var audioFile: String

  @Option(help: "The model to use for transcription. Must be an audio model.")
  var model: Model.ID = .whisper_1
  
  struct Help: InputHelp {
    static var inputValueOptionName: String { "prompt" }
    static var inputFileOptionName: String { "prompt-file" }

    static var inputValueHelp: String {
      """
      An optional text to guide the model's style or continue a previous audio segment. It should match the audio language.
      
      See: https://platform.openai.com/docs/guides/speech-to-text/prompting
      """
    }
    
    static var inputFileHelp: String {
      "The path to a file containing the text prompt to create generations for. Provide either this or --prompt, not both."
    }

    static var optional: Bool { true }
  }

  @OptionGroup var prompt: InputOptions<Help>
  
  @Option(help: "The format of the transcript output, in one of these options: `json`, `text`, `srt`, `verbose_json`, or `vtt`. (default: json)")
  var responseFormat: Audio.ResponseFormat?

  @Option(help: "The sampling temperature, between `0` and `1`. Higher values like `0.8` will make the output more random, while lower values like `0.2` will make it more focused and deterministic. If set to `0`, the model will use log probability to automatically increase the temperature until certain thresholds are hit.")
  public var temperature: Percentage?

  @Option(help: "The 2-3 character language code of the input audio. (eg. 'en', 'ja')")
  var language: Language?

  @Option(help: "The file to save the transcript to. If not provided, the transcript will be printed to the console.")
  var outputFile: String?
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
  func validate() throws {}
  
  func run() async throws {
    let client = client.new()
    let format = format.new()
    
    let audioUrl = URL(fileURLWithPath: audioFile)
    let audioData: Data
    do {
      audioData = try Data(contentsOf: audioUrl)
    } catch {
      format.print(error: "Unable to load audio source file: \(audioFile)")
      throw error
    }
    
    let prompt = try prompt.getOptionalValue()
    
    if outputFile == nil {
      format.print(title: "Audio Transcription")
      
      if let prompt {
        format.print(label: "Prompt", value: prompt, verbose: true)
        format.println(verbose: true)
      }
      
      format.print(info: "Sending request...")
      format.println()
    }
    
    let result = try await client.call(Audio.Transcriptions(
      file: audioData,
      fileName: audioUrl.lastPathComponent,
      model: model,
      prompt: prompt,
      responseFormat: responseFormat,
      temperature: temperature,
      language: language
    ))
    
    if let outputFile {
      let outputUrl = URL(fileURLWithPath: outputFile)
      let resultText = try result.textValue()
      do {
        try resultText.write(to: outputUrl, atomically: true, encoding: .utf8)
      } catch {
        format.print(error: "Unable to save transcript to file: \(outputFile)")
        throw error
      }
    } else {
      format.print(subtitle: "Result")
      format.println()
      format.print(text: try result.textValue())
    }
  }
}

// MARK: Audio.Translations

struct AudioTranslationsCommand: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
    commandName: "translations",
    abstract: "Translates an audio recording into English."
  )
  
  /// The path to the input text file.
  @Option(name: [.customLong("audio-file")], help: "The file containing the audio to transcribe, in one of these formats: `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `wav`, or `webm`.", completion: .file())
  var audioFile: String

  @Option(help: "The model to use for transcription. Must be an audio model.")
  var model: Model.ID = .whisper_1
  
  struct Help: InputHelp {
    static var inputValueOptionName: String { "prompt" }
    static var inputFileOptionName: String { "prompt-file" }

    static var inputValueHelp: String {
      """
      An optional text to guide the model's style or continue a previous audio segment. It should match the audio language.
      
      See: https://platform.openai.com/docs/guides/speech-to-text/prompting
      """
    }
    
    static var inputFileHelp: String {
      "The path to a file containing the text prompt to create generations for. Provide either this or --prompt, not both."
    }

    static var optional: Bool { true }
  }

  @OptionGroup var prompt: InputOptions<Help>
  
  @Option(help: "The format of the transcript output, in one of these options: `json`, `text`, `srt`, `verbose_json`, or `vtt`. (default: json)")
  var responseFormat: Audio.ResponseFormat?

  @Option(help: "The sampling temperature, between `0` and `1`. Higher values like `0.8` will make the output more random, while lower values like `0.2` will make it more focused and deterministic. If set to `0`, the model will use log probability to automatically increase the temperature until certain thresholds are hit.")
  public var temperature: Percentage?

  @Option(help: "The file to save the transcript to. If not provided, the transcript will be printed to the console.")
  var outputFile: String?
  
  @OptionGroup var client: ClientOptions
  
  var format: FormatOptions { client.format }
  
  func validate() throws {}
  
  func run() async throws {
    let client = client.new()
    let format = format.new()
    
    let audioUrl = URL(fileURLWithPath: audioFile)
    let audioData: Data
    do {
      audioData = try Data(contentsOf: audioUrl)
    } catch {
      format.print(error: "Unable to load audio source file: \(audioFile)")
      throw error
    }
    
    let prompt = try prompt.getOptionalValue()
    
    if outputFile == nil {
      format.print(title: "Audio Translation into English")
      
      if let prompt {
        format.print(label: "Prompt", value: prompt, verbose: true)
        format.println(verbose: true)
      }

      format.print(info: "Sending request...")
      format.println()
    }
    
    let result = try await client.call(Audio.Translations(
      file: audioData,
      fileName: audioUrl.lastPathComponent,
      model: model,
      prompt: prompt,
      responseFormat: responseFormat,
      temperature: temperature
    ))
    
    if let outputFile {
      let outputUrl = URL(fileURLWithPath: outputFile)
      let resultText = try result.textValue()
      do {
        try resultText.write(to: outputUrl, atomically: true, encoding: .utf8)
      } catch {
        format.print(error: "Unable to save transcript to file: \(outputFile)")
        throw error
      }
    } else {
      format.print(subtitle: "Result")
      format.println()
      format.print(text: try result.textValue())
    }
  }
}

// MARK: Audio.ResponseFormat + ExpressibleByArgument

extension Audio.ResponseFormat: ExpressibleByArgument {
  public init?(argument: String) {
    guard let result = Self.init(rawValue: argument) else {
      return nil
    }
    self = result
  }
}

extension Language: ExpressibleByArgument {
  public init?(argument: String) {
    guard let result = Self.init(rawValue: argument) else {
      return nil
    }
    self = result
  }
}
