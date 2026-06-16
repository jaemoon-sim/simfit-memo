import Foundation

#if canImport(ActivityKit) && os(iOS)
import ActivityKit

public struct WorkoutLiveActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var phase: WorkoutLiveActivityPhase
        public var headline: String
        public var exerciseName: String
        public var setText: String
        public var targetText: String
        public var workoutStartedAt: Date
        public var restEndAt: Date?
        public var updatedAt: Date

        public init(
            phase: WorkoutLiveActivityPhase,
            headline: String,
            exerciseName: String,
            setText: String,
            targetText: String,
            workoutStartedAt: Date,
            restEndAt: Date? = nil,
            updatedAt: Date = Date()
        ) {
            self.phase = phase
            self.headline = headline
            self.exerciseName = exerciseName
            self.setText = setText
            self.targetText = targetText
            self.workoutStartedAt = workoutStartedAt
            self.restEndAt = restEndAt
            self.updatedAt = updatedAt
        }
    }

    public var workoutID: UUID
    public var routineName: String

    public init(workoutID: UUID, routineName: String) {
        self.workoutID = workoutID
        self.routineName = routineName
    }
}

public enum WorkoutLiveActivityPhase: String, Codable, Hashable, Sendable {
    case working
    case resting
    case finished
}
#endif
