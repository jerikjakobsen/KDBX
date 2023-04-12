import XCTest
@testable import KDBX

final class KDBXTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(KDBX().text, "Hello, World!")
    }
}
