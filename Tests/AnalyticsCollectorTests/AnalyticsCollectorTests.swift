import XCTest
@testable import AnalyticsCollector

final class AnalyticsCollectorTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(AnalyticsCollector().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
