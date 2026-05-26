import XCTest

final class ExerciseSeedServiceTests: XCTestCase {
    func testEmbeddedSeedsRemainAvailable() {
        let now = Date(timeIntervalSince1970: 1_779_753_600)
        let exercises = ExerciseSeedService().loadEmbeddedSeeds(now: now)

        XCTAssertEqual(exercises.count, 3)
        XCTAssertEqual(exercises.map(\.sourceID), ["barbell-bench-press", "barbell-squat", "pull-up"])
        XCTAssertTrue(exercises.allSatisfy { $0.category == "strength" })
        XCTAssertTrue(exercises.allSatisfy { $0.createdAt == now && $0.updatedAt == now })
    }

    func testServiceImportsFreeExerciseDBDataThroughDefaultImporter() throws {
        let importedAt = Date(timeIntervalSince1970: 1_779_753_600)
        let data = Data(
            """
            [
              {
                "id": "pull-up",
                "name": "Pull-up",
                "force": "pull",
                "level": "intermediate",
                "mechanic": "compound",
                "equipment": "body only",
                "primaryMuscles": ["lats"],
                "secondaryMuscles": ["biceps"],
                "instructions": ["Pull until the chin clears the bar."],
                "category": "strength"
              }
            ]
            """.utf8
        )

        let exercises = try ExerciseSeedService().importFreeExerciseDBData(data, importedAt: importedAt)

        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises[0].sourceID, "pull-up")
        XCTAssertEqual(exercises[0].localizedName, "풀업")
        XCTAssertEqual(exercises[0].bodyPart, .back)
        XCTAssertEqual(exercises[0].createdAt, importedAt)
    }
}
