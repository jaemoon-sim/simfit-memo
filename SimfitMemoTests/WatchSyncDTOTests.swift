import XCTest

final class WatchSyncDTOTests: XCTestCase {
    func testSetCompletionPayloadRoundTripsThroughJSON() throws {
        let event = SetCompletionEventDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            sessionID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            exerciseID: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            setID: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            completedAt: Date(timeIntervalSince1970: 1_000),
            sourceDeviceID: "watch-test-device",
            clientSequence: 7
        )
        let payload = WatchSyncPayloadDTO.setCompletion(event)

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(WatchSyncPayloadDTO.self, from: data)

        XCTAssertEqual(decoded, payload)
    }

    func testActiveWorkoutSnapshotRoundTripsThroughJSON() throws {
        let setID = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
        let exercise = ActiveWorkoutExercise(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
            exerciseName: "바벨 벤치프레스",
            bodyPart: .chest,
            orderIndex: 0,
            sets: [
                ActiveWorkoutSet(
                    id: setID,
                    orderIndex: 0,
                    targetWeightKg: 60,
                    targetRepetitions: 8,
                    restSeconds: 90
                )
            ]
        )
        let state = ActiveWorkoutState(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!,
            startedAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 1_100),
            exercises: [exercise],
            currentExerciseID: exercise.id,
            currentSetID: setID
        )
        let snapshot = ActiveWorkoutSnapshotDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!,
            generatedAt: Date(timeIntervalSince1970: 1_200),
            state: state
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(ActiveWorkoutSnapshotDTO.self, from: data)

        XCTAssertEqual(decoded, snapshot)
    }
}
