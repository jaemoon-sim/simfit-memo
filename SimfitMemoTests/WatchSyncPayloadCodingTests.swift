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
}
