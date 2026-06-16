import SwiftUI

enum RoutineTargetEditorSaveMode {
    case updateAndDismiss
    case createAndShowRoutineList
}

struct RoutineTargetEditorView: View {
    let routine: Routine
    var saveMode: RoutineTargetEditorSaveMode = .updateAndDismiss

    @EnvironmentObject private var appStore: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.resetToHome) private var resetToHome
    @State private var draft: RoutineTargetDraft
    @State private var isAddingExercises = false
    @State private var showsRoutineList = false

    init(routine: Routine, saveMode: RoutineTargetEditorSaveMode = .updateAndDismiss) {
        self.routine = routine
        self.saveMode = saveMode
        _draft = State(initialValue: RoutineTargetDraft(routine: routine))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    AppTopBar(title: "루틴 편집", showsBackButton: true, leadingAction: {
                        dismiss()
                    })

                    nameField
                    exerciseSections
                    addExerciseButton
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, AppTheme.screenTopPadding)
                .padding(.bottom, 96)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "저장하기", systemImage: "checkmark", isEnabled: draft.canSave) {
                saveRoutine()
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(AppTheme.background)
        }
        .navigationDestination(isPresented: $isAddingExercises) {
            ExerciseSelectionView(
                exercises: appStore.exercises,
                selectionTitle: "운동 추가"
            ) { selectedExercises in
                draft.appendExercises(selectedExercises)
            }
        }
        .navigationDestination(isPresented: $showsRoutineList) {
            RoutineListView(backAction: resetToHome)
        }
        .preferredColorScheme(.dark)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("루틴 이름")
                .font(AppTheme.bodyFont(14, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)

            TextField("루틴 이름", text: $draft.name)
                .font(AppTheme.bodyFont(17, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
                .tint(AppTheme.primaryBlue)
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(AppTheme.recessedSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                        .stroke(draft.canSave ? AppTheme.divider : AppTheme.warning, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
    }

    private var exerciseSections: some View {
        VStack(spacing: 12) {
            ForEach($draft.exercises) { $exercise in
                RoutineTargetExerciseSection(exercise: $exercise)
            }
        }
    }

    private var addExerciseButton: some View {
        Button {
            isAddingExercises = true
        } label: {
            Label("운동 추가하기", systemImage: "plus")
                .font(AppTheme.bodyFont(15, weight: .bold))
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(AppTheme.recessedSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                        .stroke(AppTheme.divider, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
        .buttonStyle(.plain)
    }

    private func saveRoutine() {
        guard let updatedRoutine = draft.makeRoutine() else {
            return
        }

        switch saveMode {
        case .updateAndDismiss:
            appStore.updateRoutine(updatedRoutine)
            dismiss()
        case .createAndShowRoutineList:
            if appStore.saveNewRoutine(updatedRoutine) != nil {
                showsRoutineList = true
            }
        }
    }
}

private struct RoutineTargetExerciseSection: View {
    @Binding var exercise: RoutineExerciseTargetDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()
                .overlay(AppTheme.divider)

            VStack(spacing: 0) {
                ForEach($exercise.sets) { $set in
                    RoutineTargetSetRow(set: $set)

                    if set.id != exercise.sets.last?.id {
                        Divider()
                            .overlay(AppTheme.divider)
                            .padding(.leading, 16)
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    exercise.addSet()
                } label: {
                    Label("세트 추가", systemImage: "plus")
                        .font(AppTheme.bodyFont(14, weight: .bold))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(AppTheme.recessedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                }
                .buttonStyle(.plain)

                Button {
                    exercise.removeLastSet()
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(exercise.sets.count > 1 ? AppTheme.primaryText : AppTheme.tertiaryText)
                        .frame(width: 48, height: 46)
                        .background(AppTheme.recessedSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                }
                .buttonStyle(.plain)
                .disabled(exercise.sets.count <= 1)
            }
            .padding(12)
        }
        .background(AppTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(exercise.orderIndex + 1)")
                .font(AppTheme.bodyFont(14, weight: .black))
                .foregroundStyle(Color.white)
                .frame(width: 32, height: 32)
                .background(AppTheme.primaryBlue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(exercise.exerciseName)
                    .font(AppTheme.bodyFont(17, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)

                Text("\(exercise.bodyPart.displayName) · \(exercise.sets.count)세트")
                    .font(AppTheme.bodyFont(13, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(16)
    }
}

private struct RoutineTargetSetRow: View {
    @Binding var set: RoutineSetTargetDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(set.orderIndex + 1)세트")
                    .font(AppTheme.bodyFont(13, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)

                Spacer()

                Text("목표")
                    .font(AppTheme.bodyFont(12, weight: .bold))
                    .foregroundStyle(AppTheme.tertiaryText)
            }

            HStack(spacing: 8) {
                targetField(title: "kg", text: $set.weightText, keyboard: .decimalPad)
                targetField(title: "회", text: $set.repetitionsText, keyboard: .numberPad)
                targetField(title: "초", text: $set.restText, keyboard: .numberPad)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func targetField(title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack(spacing: 4) {
            TextField("-", text: text)
                .font(AppTheme.bodyFont(15, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.trailing)
                .keyboardType(keyboard)

            Text(title)
                .font(AppTheme.bodyFont(12, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 18, alignment: .leading)
        }
        .frame(maxWidth: .infinity, minHeight: 42)
        .padding(.horizontal, 8)
        .background(AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct RoutineTargetDraft {
    var id: UUID
    var name: String
    var exercises: [RoutineExerciseTargetDraft]
    var createdAt: Date
    var lastPerformedAt: Date?
    var completedCount: Int

    init(routine: Routine) {
        id = routine.id
        name = routine.name
        exercises = routine.exercises
            .sorted { $0.orderIndex < $1.orderIndex }
            .map(RoutineExerciseTargetDraft.init)
        createdAt = routine.createdAt
        lastPerformedAt = routine.lastPerformedAt
        completedCount = routine.completedCount
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !exercises.isEmpty
            && exercises.allSatisfy { !$0.sets.isEmpty }
    }

    func makeRoutine() -> Routine? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            return nil
        }

        return Routine(
            id: id,
            name: trimmedName,
            exercises: exercises.enumerated().map { index, exercise in
                exercise.makeRoutineExercise(orderIndex: index)
            },
            createdAt: createdAt,
            updatedAt: Date(),
            lastPerformedAt: lastPerformedAt,
            completedCount: completedCount
        )
    }

    mutating func appendExercises(_ selectedExercises: [Exercise]) {
        var existingExerciseIDs = Set(exercises.map(\.exerciseID))

        for selectedExercise in selectedExercises where !existingExerciseIDs.contains(selectedExercise.id) {
            exercises.append(
                RoutineExerciseTargetDraft(
                    exercise: selectedExercise,
                    orderIndex: exercises.count
                )
            )
            existingExerciseIDs.insert(selectedExercise.id)
        }

        normalizeOrder()
    }

    private mutating func normalizeOrder() {
        for index in exercises.indices {
            exercises[index].orderIndex = index
        }
    }
}

private struct RoutineExerciseTargetDraft: Identifiable {
    var id: UUID
    var exerciseID: UUID
    var exerciseName: String
    var bodyPart: BodyPart
    var orderIndex: Int
    var sets: [RoutineSetTargetDraft]

    init(exercise: RoutineExercise) {
        id = exercise.id
        exerciseID = exercise.exerciseID
        exerciseName = exercise.exerciseName
        bodyPart = exercise.bodyPart
        orderIndex = exercise.orderIndex
        let sortedTargets = exercise.setTargets.sorted { $0.orderIndex < $1.orderIndex }
        sets = sortedTargets.isEmpty
            ? [RoutineSetTargetDraft(orderIndex: 0)]
            : sortedTargets.map(RoutineSetTargetDraft.init)
    }

    init(exercise: Exercise, orderIndex: Int) {
        id = UUID()
        exerciseID = exercise.id
        exerciseName = exercise.displayName
        bodyPart = exercise.bodyPart
        self.orderIndex = orderIndex
        sets = (0..<3).map { RoutineSetTargetDraft(orderIndex: $0) }
    }

    mutating func addSet() {
        sets.append(RoutineSetTargetDraft(orderIndex: sets.count))
    }

    mutating func removeLastSet() {
        guard sets.count > 1 else {
            return
        }

        sets.removeLast()
        normalizeOrder()
    }

    func makeRoutineExercise(orderIndex: Int) -> RoutineExercise {
        RoutineExercise(
            id: id,
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            bodyPart: bodyPart,
            orderIndex: orderIndex,
            setTargets: sets.enumerated().map { index, set in
                set.makeTarget(orderIndex: index)
            }
        )
    }

    private mutating func normalizeOrder() {
        for index in sets.indices {
            sets[index].orderIndex = index
        }
    }
}

private struct RoutineSetTargetDraft: Identifiable {
    var id: UUID
    var orderIndex: Int
    var weightText: String
    var repetitionsText: String
    var restText: String

    init(orderIndex: Int) {
        id = UUID()
        self.orderIndex = orderIndex
        weightText = ""
        repetitionsText = ""
        restText = String(ExerciseSeedService.defaultRestSeconds)
    }

    init(target: RoutineSetTarget) {
        id = target.id
        orderIndex = target.orderIndex
        weightText = target.targetWeightKg.map { Self.weightFormatter.string(from: NSNumber(value: $0)) ?? "\($0)" } ?? ""
        repetitionsText = target.targetRepetitions.map(String.init) ?? ""
        restText = String(target.restSeconds)
    }

    func makeTarget(orderIndex: Int) -> RoutineSetTarget {
        RoutineSetTarget(
            id: id,
            orderIndex: orderIndex,
            targetWeightKg: Self.doubleValue(from: weightText),
            targetRepetitions: Self.intValue(from: repetitionsText),
            restSeconds: max(Self.intValue(from: restText) ?? ExerciseSeedService.defaultRestSeconds, 0)
        )
    }

    private static let weightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private static func doubleValue(from text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        return normalized.isEmpty ? nil : Double(normalized)
    }

    private static func intValue(from text: String) -> Int? {
        let digits = text.filter(\.isNumber)
        return digits.isEmpty ? nil : Int(digits)
    }
}
