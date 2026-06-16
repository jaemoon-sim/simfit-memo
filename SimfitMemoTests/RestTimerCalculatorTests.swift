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

    func testRestCountdownCueTrackerEmitsOnlyConfiguredCuesOnce() {
        let restStartedAt = Date(timeIntervalSince1970: 1_000)
        var tracker = RestCountdownCueTracker()

        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 11)), [])
        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 10)), [.tenSeconds])
        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 10)), [])
        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 3)), [.finalCountdown(remainingSeconds: 3)])
        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 2)), [.finalCountdown(remainingSeconds: 2)])
        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 1)), [.finalCountdown(remainingSeconds: 1)])
        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 0)), [])
    }

    func testRestCountdownCueTrackerResetsForNewRestSession() {
        var tracker = RestCountdownCueTracker()

        XCTAssertEqual(
            tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: Date(timeIntervalSince1970: 1_000), remainingSeconds: 10)),
            [.tenSeconds]
        )
        XCTAssertEqual(
            tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: Date(timeIntervalSince1970: 2_000), remainingSeconds: 10)),
            [.tenSeconds]
        )
    }

    func testRestCountdownCueTrackerAllowsCuesAgainAfterRestExtension() {
        let restStartedAt = Date(timeIntervalSince1970: 1_000)
        var tracker = RestCountdownCueTracker()

        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 10)), [.tenSeconds])
        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 3)), [.finalCountdown(remainingSeconds: 3)])
        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 12)), [])
        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 10)), [.tenSeconds])
        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 4)), [])
        XCTAssertEqual(tracker.cues(for: RestCountdownCueSnapshot(restStartedAt: restStartedAt, remainingSeconds: 3)), [.finalCountdown(remainingSeconds: 3)])
    }
}
