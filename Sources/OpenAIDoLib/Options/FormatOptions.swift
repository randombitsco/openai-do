import ArgumentParser

struct FormatOptions: ParsableArguments {
  @Flag(help: "Output more details.")
  var verbose: Bool = false
    
  @Flag(help: "Output debugging information.")
  var debug: Bool = false
  
  /// The default format, given the config.
  func new() -> Format {
    .init(indent: "", showVerbose: verbose, showDebug: debug)
  }
}
