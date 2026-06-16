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

public enum RestCountdownCue: Equatable, Sendable {
    case tenSeconds
    case finalCountdown(remainingSeconds: Int)
}

public struct RestCountdownCueSnapshot: Equatable, Sendable {
    public var restStartedAt: Date?
    public var remainingSeconds: Int

    public init(restStartedAt: Date?, remainingSeconds: Int) {
        self.restStartedAt = restStartedAt
        self.remainingSeconds = remainingSeconds
    }
}

public struct RestCountdownCueTracker: Equatable, Sendable {
    private var activeRestStartedAt: Date?
    private var firedRemainingSeconds: Set<Int> = []

    public init() {}

    public mutating func cues(for snapshot: RestCountdownCueSnapshot) -> [RestCountdownCue] {
        guard let restStartedAt = snapshot.restStartedAt,
              snapshot.remainingSeconds > 0 else {
            reset()
            return []
        }

        if activeRestStartedAt != restStartedAt {
            activeRestStartedAt = restStartedAt
            firedRemainingSeconds = []
        }

        resetCuesAfterRestExtension(remainingSeconds: snapshot.remainingSeconds)

        guard Self.cueRemainingSeconds.contains(snapshot.remainingSeconds),
              firedRemainingSeconds.insert(snapshot.remainingSeconds).inserted else {
            return []
        }

        switch snapshot.remainingSeconds {
        case 10:
            return [.tenSeconds]
        case 3, 2, 1:
            return [.finalCountdown(remainingSeconds: snapshot.remainingSeconds)]
        default:
            return []
        }
    }

    private mutating func reset() {
        activeRestStartedAt = nil
        firedRemainingSeconds = []
    }

    private mutating func resetCuesAfterRestExtension(remainingSeconds: Int) {
        if remainingSeconds > 10 {
            firedRemainingSeconds.remove(10)
        }

        if remainingSeconds > 3 {
            firedRemainingSeconds.subtract([3, 2, 1])
        }
    }

    private static let cueRemainingSeconds: Set<Int> = [10, 3, 2, 1]
}
