import XCTest

final class WorkoutRestTimerTests: XCTestCase {
    func testRestEndDateUsesNonNegativeRestDuration() {
        let calculator = RestTimerCalculator()
        let startedAt = Date(timeIntervalSince1970: 1_000)

        XCTAssertEqual(calculator.restEndDate(startedAt: startedAt, restSeconds: 0), startedAt)
        XCTAssertEqual(calculator.restEndDate(startedAt: startedAt, restSeconds: -30), startedAt)
        XCTAssertEqual(calculator.restEndDate(startedAt: startedAt, restSeconds: 45), startedAt.addingTimeInterval(45))
    }
}
