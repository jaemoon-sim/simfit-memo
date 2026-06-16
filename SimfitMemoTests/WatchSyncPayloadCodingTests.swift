import XCTest

final class WatchSyncPayloadCodingTests: XCTestCase {
    func testPayloadDictionaryIncludesKindAndSchemaVersion() throws {
        let event = makeSetCompletionEvent()
        let payload = WatchSyncPayloadDTO.setCompletion(event)

        let dictionary = try WatchPayloadCoding.makeDictionary(from: payload)

        XCTAssertEqual(dictionary[WatchPayloadCoding.payloadKindKey] as? String, WatchSyncPayloadKind.setCompletion.rawValue)
        XCTAssertEqual(dictionary[WatchPayloadCoding.schemaVersionKey] as? Int, WatchSyncSchema.currentVersion)
        XCTAssertNotNil(dictionary[WatchPayloadCoding.payloadDataKey] as? Data)
    }

    func testPayloadDictionaryRoundTrips() throws {
        let payload = WatchSyncPayloadDTO.setCompletion(makeSetCompletionEvent())

        let dictionary = try WatchPayloadCoding.makeDictionary(from: payload)
        let decoded = try WatchPayloadCoding.decodeDictionary(dictionary)

        XCTAssertEqual(decoded, payload)
    }

    func testRestAdjustmentPayloadDictionaryUsesRestAdjustmentKind() throws {
        let payload = WatchSyncPayloadDTO.restAdjustment(makeRestAdjustmentEvent())

        let dictionary = try WatchPayloadCoding.makeDictionary(from: payload)
        let decoded = try WatchPayloadCoding.decodeDictionary(dictionary)

        XCTAssertEqual(dictionary[WatchPayloadCoding.payloadKindKey] as? String, WatchSyncPayloadKind.restAdjustment.rawValue)
        XCTAssertEqual(decoded, payload)
    }

    func testSyncRequestPayloadDictionaryUsesSyncRequestKind() throws {
        let payload = WatchSyncPayloadDTO.syncRequest(makeSyncRequestEvent())

        let dictionary = try WatchPayloadCoding.makeDictionary(from: payload)
        let decoded = try WatchPayloadCoding.decodeDictionary(dictionary)

        XCTAssertEqual(dictionary[WatchPayloadCoding.payloadKindKey] as? String, WatchSyncPayloadKind.syncRequest.rawValue)
        XCTAssertEqual(decoded, payload)
    }

    func testFullSnapshotPayloadDictionaryUsesFullSnapshotKind() throws {
        let payload = WatchSyncPayloadDTO.fullSnapshot(makeFullSnapshot())

        let dictionary = try WatchPayloadCoding.makeDictionary(from: payload)
        let decoded = try WatchPayloadCoding.decodeDictionary(dictionary)

        XCTAssertEqual(dictionary[WatchPayloadCoding.payloadKindKey] as? String, WatchSyncPayloadKind.fullSnapshot.rawValue)
        XCTAssertEqual(decoded, payload)
    }

    func testPayloadDictionaryRejectsFutureSchemaVersion() throws {
        let payload = WatchSyncPayloadDTO.setCompletion(makeSetCompletionEvent())
        var dictionary = try WatchPayloadCoding.makeDictionary(from: payload)
        dictionary[WatchPayloadCoding.schemaVersionKey] = WatchSyncSchema.currentVersion + 1

        XCTAssertThrowsError(try WatchPayloadCoding.decodeDictionary(dictionary)) { error in
            XCTAssertEqual(
                error as? WatchPayloadCodingError,
                .unsupportedSchemaVersion(WatchSyncSchema.currentVersion + 1)
            )
        }
    }

    func testPayloadDictionaryRejectsMismatchedKind() throws {
        let payload = WatchSyncPayloadDTO.setCompletion(makeSetCompletionEvent())
        var dictionary = try WatchPayloadCoding.makeDictionary(from: payload)
        dictionary[WatchPayloadCoding.payloadKindKey] = WatchSyncPayloadKind.history.rawValue

        XCTAssertThrowsError(try WatchPayloadCoding.decodeDictionary(dictionary)) { error in
            XCTAssertEqual(
                error as? WatchPayloadCodingError,
                .mismatchedPayloadKind(expected: .history, actual: .setCompletion)
            )
        }
    }

    func testSetCompletionDeduplicatorRejectsDuplicateSetIdentity() {
        var deduplicator = WatchSetCompletionEventDeduplicator()
        let firstEvent = makeSetCompletionEvent()
        let duplicateEvent = SetCompletionEventDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000099")!,
            sessionID: firstEvent.sessionID,
            exerciseID: firstEvent.exerciseID,
            setID: firstEvent.setID,
            completedAt: firstEvent.completedAt.addingTimeInterval(1),
            sourceDeviceID: "watch-test-device",
            clientSequence: 8
        )

        XCTAssertTrue(deduplicator.shouldAccept(firstEvent))
        XCTAssertFalse(deduplicator.shouldAccept(duplicateEvent))
    }

    func testSetCompletionDeduplicatorAllowsDifferentSets() {
        var deduplicator = WatchSetCompletionEventDeduplicator()
        let firstEvent = makeSetCompletionEvent()
        let nextSetEvent = SetCompletionEventDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000099")!,
            sessionID: firstEvent.sessionID,
            exerciseID: firstEvent.exerciseID,
            setID: UUID(uuidString: "00000000-0000-0000-0000-000000000088")!,
            completedAt: firstEvent.completedAt.addingTimeInterval(1),
            sourceDeviceID: "watch-test-device",
            clientSequence: 8
        )

        XCTAssertTrue(deduplicator.shouldAccept(firstEvent))
        XCTAssertTrue(deduplicator.shouldAccept(nextSetEvent))
    }

    private func makeSetCompletionEvent() -> SetCompletionEventDTO {
        SetCompletionEventDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            sessionID: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            exerciseID: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            setID: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            completedAt: Date(timeIntervalSince1970: 1_000),
            sourceDeviceID: "watch-test-device",
            clientSequence: 7
        )
    }

    private func makeRestAdjustmentEvent() -> RestAdjustmentEventDTO {
        RestAdjustmentEventDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
            sessionID: UUID(uuidString: "00000000-0000-0000-0000-000000000022")!,
            deltaSeconds: 10,
            requestedAt: Date(timeIntervalSince1970: 1_050),
            sourceDeviceID: "watch-test-device",
            clientSequence: 8
        )
    }

    private func makeSyncRequestEvent() -> SyncRequestEventDTO {
        SyncRequestEventDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000031")!,
            requestedAt: Date(timeIntervalSince1970: 1_060),
            sourceDeviceID: "watch-test-device",
            clientSequence: 9
        )
    }

    private func makeFullSnapshot() -> FullSyncSnapshotDTO {
        FullSyncSnapshotDTO(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000041")!,
            generatedAt: Date(timeIntervalSince1970: 1_200),
            activeWorkout: nil,
            routines: [],
            history: []
        )
    }
}
