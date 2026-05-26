import XCTest

final class FreeExerciseDBExerciseSeedImporterTests: XCTestCase {
    private let importedAt = Date(timeIntervalSince1970: 1_779_753_600)

    func testImportsStrengthExerciseAndPreservesSourceFields() throws {
        let importer = FreeExerciseDBExerciseSeedImporter()
        let exercises = try importer.importExercises(
            from: fixtureData(
                """
                [
                  {
                    "id": "barbell-bench-press",
                    "name": "Barbell Bench Press",
                    "force": "push",
                    "level": "beginner",
                    "mechanic": "compound",
                    "equipment": "barbell",
                    "primaryMuscles": ["chest"],
                    "secondaryMuscles": ["shoulders", "triceps"],
                    "instructions": ["Lie on a flat bench.", "Press the bar upward."],
                    "category": "strength",
                    "images": ["barbell-bench-press/0.jpg"]
                  }
                ]
                """
            ),
            importedAt: importedAt
        )

        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises[0].sourceID, "barbell-bench-press")
        XCTAssertEqual(exercises[0].name, "Barbell Bench Press")
        XCTAssertEqual(exercises[0].localizedName, "바벨 벤치프레스")
        XCTAssertEqual(exercises[0].bodyPart, .chest)
        XCTAssertEqual(exercises[0].primaryMuscles, ["chest"])
        XCTAssertEqual(exercises[0].secondaryMuscles, ["shoulders", "triceps"])
        XCTAssertEqual(exercises[0].equipment, "barbell")
        XCTAssertEqual(exercises[0].category, "strength")
        XCTAssertEqual(exercises[0].instructions, ["Lie on a flat bench.", "Press the bar upward."])
        XCTAssertFalse(exercises[0].isBookmarked)
        XCTAssertFalse(exercises[0].isCustom)
        XCTAssertEqual(exercises[0].createdAt, importedAt)
        XCTAssertEqual(exercises[0].updatedAt, importedAt)
    }

    func testImportsNullOptionalFieldsAsEmptyOrNilValues() throws {
        let importer = FreeExerciseDBExerciseSeedImporter()
        let exercises = try importer.importExercises(
            from: fixtureData(
                """
                [
                  {
                    "id": "plank",
                    "name": "Plank",
                    "force": null,
                    "level": null,
                    "mechanic": null,
                    "equipment": null,
                    "primaryMuscles": ["abdominals"],
                    "secondaryMuscles": null,
                    "instructions": null,
                    "category": "strength"
                  }
                ]
                """
            ),
            importedAt: importedAt
        )

        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises[0].localizedName, "플랭크")
        XCTAssertEqual(exercises[0].bodyPart, .core)
        XCTAssertNil(exercises[0].equipment)
        XCTAssertEqual(exercises[0].secondaryMuscles, [])
        XCTAssertEqual(exercises[0].instructions, [])
    }

    func testDefaultImportFiltersNonStrengthExercises() throws {
        let importer = FreeExerciseDBExerciseSeedImporter()
        let exercises = try importer.importExercises(
            from: fixtureData(
                """
                [
                  {
                    "id": "barbell-squat",
                    "name": "Barbell Squat",
                    "force": "push",
                    "level": "beginner",
                    "mechanic": "compound",
                    "equipment": "barbell",
                    "primaryMuscles": ["quadriceps"],
                    "secondaryMuscles": ["glutes"],
                    "instructions": ["Squat under control."],
                    "category": "strength"
                  },
                  {
                    "id": "runner-stretch",
                    "name": "Runner Stretch",
                    "force": null,
                    "level": "beginner",
                    "mechanic": null,
                    "equipment": "body only",
                    "primaryMuscles": ["hamstrings"],
                    "secondaryMuscles": [],
                    "instructions": ["Hold the stretch."],
                    "category": "stretching"
                  }
                ]
                """
            ),
            importedAt: importedAt
        )

        XCTAssertEqual(exercises.map(\.sourceID), ["barbell-squat"])
    }

    func testBodyPartMappingUsesPrimaryMusclesThenSecondaryFallback() throws {
        let importer = FreeExerciseDBExerciseSeedImporter()
        let exercises = try importer.importExercises(
            from: fixtureData(
                """
                [
                  {
                    "id": "leg-press",
                    "name": "Leg Press",
                    "force": "push",
                    "level": "beginner",
                    "mechanic": "compound",
                    "equipment": "machine",
                    "primaryMuscles": ["quadriceps"],
                    "secondaryMuscles": [],
                    "instructions": [],
                    "category": "strength"
                  },
                  {
                    "id": "lat-pulldown",
                    "name": "Lat Pulldown",
                    "force": "pull",
                    "level": "beginner",
                    "mechanic": "compound",
                    "equipment": "cable",
                    "primaryMuscles": ["lats"],
                    "secondaryMuscles": [],
                    "instructions": [],
                    "category": "strength"
                  },
                  {
                    "id": "shoulder-press",
                    "name": "Dumbbell Shoulder Press",
                    "force": "push",
                    "level": "beginner",
                    "mechanic": "compound",
                    "equipment": "dumbbell",
                    "primaryMuscles": ["shoulders"],
                    "secondaryMuscles": [],
                    "instructions": [],
                    "category": "strength"
                  },
                  {
                    "id": "barbell-curl",
                    "name": "Barbell Curl",
                    "force": "pull",
                    "level": "beginner",
                    "mechanic": "isolation",
                    "equipment": "barbell",
                    "primaryMuscles": ["biceps"],
                    "secondaryMuscles": [],
                    "instructions": [],
                    "category": "strength"
                  },
                  {
                    "id": "unknown-secondary-arm",
                    "name": "Unknown Secondary Arm",
                    "force": null,
                    "level": "beginner",
                    "mechanic": null,
                    "equipment": null,
                    "primaryMuscles": ["unknown"],
                    "secondaryMuscles": ["triceps"],
                    "instructions": [],
                    "category": "strength"
                  },
                  {
                    "id": "unknown-neck",
                    "name": "Unknown Neck",
                    "force": null,
                    "level": "beginner",
                    "mechanic": null,
                    "equipment": null,
                    "primaryMuscles": ["neck"],
                    "secondaryMuscles": [],
                    "instructions": [],
                    "category": "strength"
                  }
                ]
                """
            ),
            importedAt: importedAt
        )

        XCTAssertEqual(exercises.map(\.bodyPart), [.lowerBody, .back, .shoulders, .arms, .arms, .other])
    }

    func testLocalizedNameFallsBackToOriginalEnglishName() throws {
        let importer = FreeExerciseDBExerciseSeedImporter()
        let exercises = try importer.importExercises(
            from: fixtureData(
                """
                [
                  {
                    "id": "cable-woodchop",
                    "name": "Cable Woodchop",
                    "force": "pull",
                    "level": "beginner",
                    "mechanic": "compound",
                    "equipment": "cable",
                    "primaryMuscles": ["abdominals"],
                    "secondaryMuscles": ["shoulders"],
                    "instructions": ["Rotate through the torso."],
                    "category": "strength"
                  }
                ]
                """
            ),
            importedAt: importedAt
        )

        XCTAssertEqual(exercises[0].name, "Cable Woodchop")
        XCTAssertEqual(exercises[0].localizedName, "Cable Woodchop")
        XCTAssertEqual(exercises[0].displayName, "Cable Woodchop")
    }

    private func fixtureData(_ json: String) -> Data {
        Data(json.utf8)
    }
}
