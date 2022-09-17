import ArgumentParser
import OpenAIDoLib

@main
enum MainCLI {
  static func main() async throws {
    await OpenAIDo.main()
  }
}
