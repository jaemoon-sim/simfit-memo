import XCTest

final class RestTimerCalculatorTests: XCTestCase {
    func testRemainingSecondsRoundsUpAndClampsAtZero() {
        let calculator = RestTimerCalculator()
        let startedAt = Date(timeIntervalSince1970: 1_000)
        let restEndAt = calculator.restEndDate(startedAt: startedAt, restSeconds: 90)

        XCTAssertEqual(calculator.remainingSeconds(restEndAt: restEndAt, now: startedAt), 90)
        XCTAssertEqual(calculator.remainingSeconds(restEndAt: restEndAt, now: startedAt.addingTimeInterval(89.2)), 1)
        XCTAssertEqual(calculator.remainingSeconds(restEndAt: restEndAt, now: startedAt.addingTimeInterval(91)), 0)
    }

    func testMissingRestEndDateIsNotResting() {
        let calculator = RestTimerCalculator()

        XCTAssertEqual(calculator.remainingSeconds(restEndAt: nil, now: Date(timeIntervalSince1970: 1_000)), 0)
        XCTAssertFalse(calculator.isResting(restEndAt: nil, now: Date(timeIntervalSince1970: 1_000)))
    }
}
