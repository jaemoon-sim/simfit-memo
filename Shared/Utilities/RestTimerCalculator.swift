import Foundation

public struct RestTimerCalculator: Sendable {
    public init() {}

    public func restEndDate(startedAt: Date, restSeconds: Int) -> Date {
        startedAt.addingTimeInterval(TimeInterval(max(0, restSeconds)))
    }

    public func remainingSeconds(restEndAt: Date?, now: Date) -> Int {
        guard let restEndAt else {
            return 0
        }

        return max(0, Int(ceil(restEndAt.timeIntervalSince(now))))
    }

    public func isResting(restEndAt: Date?, now: Date) -> Bool {
        remainingSeconds(restEndAt: restEndAt, now: now) > 0
    }
}
