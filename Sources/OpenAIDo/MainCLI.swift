import ArgumentParser
import OpenAIDoLib

@main
struct MainCLI {
  static func main() async throws {
    await OpenAIDo.main()
  }
}
