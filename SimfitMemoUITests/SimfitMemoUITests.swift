import XCTest

final class SimfitMemoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsWorkoutRecordHome() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["운동 기록"].waitForExistence(timeout: 5))
    }
}
