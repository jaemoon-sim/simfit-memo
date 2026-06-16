import Foundation

public struct ActiveWorkoutState: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var routineID: UUID?
    public var routineName: String?
    public var startedAt: Date
    public var updatedAt: Date
    public var syncVersion: Int
    public var exercises: [ActiveWorkoutExercise]
    public var currentExerciseID: UUID?
    public var currentSetID: UUID?
    public var restStartedAt: Date?
    public var restEndAt: Date?

    public init(
        id: UUID = UUID(),
        routineID: UUID? = nil,
        routineName: String? = nil,
        startedAt: Date = Date(),
        updatedAt: Date = Date(),
        syncVersion: Int = 1,
        exercises: [ActiveWorkoutExercise] = [],
        currentExerciseID: UUID? = nil,
        currentSetID: UUID? = nil,
        restStartedAt: Date? = nil,
        restEndAt: Date? = nil
    ) {
        self.id = id
        self.routineID = routineID
        self.routineName = routineName
        self.startedAt = startedAt
        self.updatedAt = updatedAt
        self.syncVersion = syncVersion
        self.exercises = exercises
        self.currentExerciseID = currentExerciseID
        self.currentSetID = currentSetID
        self.restStartedAt = restStartedAt
        self.restEndAt = restEndAt
    }
}

public struct ActiveWorkoutExercise: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var exerciseID: UUID?
    public var exerciseName: String
    public var bodyPart: BodyPart
    public var orderIndex: Int
    public var sets: [ActiveWorkoutSet]

    public init(
        id: UUID = UUID(),
        exerciseID: UUID? = nil,
        exerciseName: String,
        bodyPart: BodyPart,
        orderIndex: Int,
        sets: [ActiveWorkoutSet] = []
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.bodyPart = bodyPart
        self.orderIndex = orderIndex
        self.sets = sets
    }
}

public struct ActiveWorkoutSet: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var orderIndex: Int
    public var targetWeightKg: Double?
    public var targetRepetitions: Int?
    public var actualWeightKg: Double?
    public var actualRepetitions: Int?
    public var restSeconds: Int
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        orderIndex: Int,
        targetWeightKg: Double? = nil,
        targetRepetitions: Int? = nil,
        actualWeightKg: Double? = nil,
        actualRepetitions: Int? = nil,
        restSeconds: Int = ExerciseSeedService.defaultRestSeconds,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.targetWeightKg = targetWeightKg
        self.targetRepetitions = targetRepetitions
        self.actualWeightKg = actualWeightKg
        self.actualRepetitions = actualRepetitions
        self.restSeconds = restSeconds
        self.completedAt = completedAt
    }
}
