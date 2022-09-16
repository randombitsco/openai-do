import XCTest
@testable import swift_openai_cli

final class swift_openai_cliTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(swift_openai_cli().text, "Hello, World!")
    }
}
