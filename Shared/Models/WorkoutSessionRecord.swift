import Foundation

public struct WorkoutSessionRecord: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var routineID: UUID?
    public var routineName: String?
    public var startedAt: Date
    public var endedAt: Date?
    public var exercises: [WorkoutExerciseRecord]

    public init(
        id: UUID = UUID(),
        routineID: UUID? = nil,
        routineName: String? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        exercises: [WorkoutExerciseRecord] = []
    ) {
        self.id = id
        self.routineID = routineID
        self.routineName = routineName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.exercises = exercises
    }
}

public struct WorkoutExerciseRecord: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var exerciseID: UUID?
    public var exerciseName: String
    public var bodyPart: BodyPart
    public var orderIndex: Int
    public var sets: [WorkoutSetRecord]

    public init(
        id: UUID = UUID(),
        exerciseID: UUID? = nil,
        exerciseName: String,
        bodyPart: BodyPart,
        orderIndex: Int,
        sets: [WorkoutSetRecord] = []
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.bodyPart = bodyPart
        self.orderIndex = orderIndex
        self.sets = sets
    }
}

public struct WorkoutSetRecord: Identifiable, Codable, Equatable, Sendable {
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
        restSeconds: Int = 90,
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
