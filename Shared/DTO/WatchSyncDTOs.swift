import Foundation

public enum WatchSyncSchema {
    public static let currentVersion = 1
}

public struct ActiveWorkoutSnapshotDTO: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var schemaVersion: Int
    public var generatedAt: Date
    public var state: ActiveWorkoutState?

    public init(
        id: UUID = UUID(),
        schemaVersion: Int = WatchSyncSchema.currentVersion,
        generatedAt: Date = Date(),
        state: ActiveWorkoutState?
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.state = state
    }
}

public struct RoutineSnapshotDTO: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var schemaVersion: Int
    public var generatedAt: Date
    public var routines: [Routine]

    public init(
        id: UUID = UUID(),
        schemaVersion: Int = WatchSyncSchema.currentVersion,
        generatedAt: Date = Date(),
        routines: [Routine]
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.routines = routines
    }
}

public struct WorkoutHistorySnapshotDTO: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var schemaVersion: Int
    public var generatedAt: Date
    public var records: [WorkoutSessionRecord]

    public init(
        id: UUID = UUID(),
        schemaVersion: Int = WatchSyncSchema.currentVersion,
        generatedAt: Date = Date(),
        records: [WorkoutSessionRecord]
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.records = records
    }
}

public struct SetCompletionEventDTO: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var schemaVersion: Int
    public var sessionID: UUID
    public var exerciseID: UUID
    public var setID: UUID
    public var completedAt: Date
    public var sourceDeviceID: String
    public var clientSequence: Int

    public init(
        id: UUID = UUID(),
        schemaVersion: Int = WatchSyncSchema.currentVersion,
        sessionID: UUID,
        exerciseID: UUID,
        setID: UUID,
        completedAt: Date = Date(),
        sourceDeviceID: String,
        clientSequence: Int
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.sessionID = sessionID
        self.exerciseID = exerciseID
        self.setID = setID
        self.completedAt = completedAt
        self.sourceDeviceID = sourceDeviceID
        self.clientSequence = clientSequence
    }
}

public enum WatchSyncPayloadDTO: Codable, Equatable, Sendable {
    case activeWorkout(ActiveWorkoutSnapshotDTO)
    case routines(RoutineSnapshotDTO)
    case history(WorkoutHistorySnapshotDTO)
    case setCompletion(SetCompletionEventDTO)

    private enum CodingKeys: String, CodingKey {
        case kind
        case payload
    }

    private enum Kind: String, Codable {
        case activeWorkout
        case routines
        case history
        case setCompletion
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)

        switch kind {
        case .activeWorkout:
            self = .activeWorkout(try container.decode(ActiveWorkoutSnapshotDTO.self, forKey: .payload))
        case .routines:
            self = .routines(try container.decode(RoutineSnapshotDTO.self, forKey: .payload))
        case .history:
            self = .history(try container.decode(WorkoutHistorySnapshotDTO.self, forKey: .payload))
        case .setCompletion:
            self = .setCompletion(try container.decode(SetCompletionEventDTO.self, forKey: .payload))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .activeWorkout(let snapshot):
            try container.encode(Kind.activeWorkout, forKey: .kind)
            try container.encode(snapshot, forKey: .payload)
        case .routines(let snapshot):
            try container.encode(Kind.routines, forKey: .kind)
            try container.encode(snapshot, forKey: .payload)
        case .history(let snapshot):
            try container.encode(Kind.history, forKey: .kind)
            try container.encode(snapshot, forKey: .payload)
        case .setCompletion(let event):
            try container.encode(Kind.setCompletion, forKey: .kind)
            try container.encode(event, forKey: .payload)
        }
    }
}
