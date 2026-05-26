import SwiftUI

struct WorkoutMemoView: View {
    @EnvironmentObject private var appStore: AppDataStore

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if let state = appStore.activeWorkout {
                        activeWorkoutContent(state)
                    } else {
                        finishedOrEmptyContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("운동 메모")
                        .font(.system(size: 31, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(appStore.activeWorkout?.routineName ?? "자유 운동")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                startMenu
            }

            restSummary
        }
    }

    private var startMenu: some View {
        Menu {
            ForEach(appStore.routines) { routine in
                Button(routine.name) {
                    appStore.startWorkout(from: routine)
                }
            }

            Button("빈 운동") {
                appStore.startEmptyWorkout()
            }
        } label: {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 44, height: 44)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
    }

    private var restSummary: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { context in
            let remaining = appStore.remainingRestSeconds(now: context.date)

            HStack(spacing: 12) {
                Image(systemName: remaining > 0 ? "timer" : "checkmark.circle")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(remaining > 0 ? AppTheme.primaryBlue : AppTheme.secondaryText)

                VStack(alignment: .leading, spacing: 3) {
                    Text(remaining > 0 ? "휴식 \(Self.formattedDuration(remaining))" : "휴식 대기")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(restDetailText(remaining: remaining))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()
            }
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
    }

    private func restDetailText(remaining: Int) -> String {
        guard let state = appStore.activeWorkout else {
            return "진행 중인 운동 없음"
        }

        if remaining > 0, let restEndAt = state.restEndAt {
            return "\(restEndAt.formatted(date: .omitted, time: .shortened)) 종료"
        }

        if state.restStartedAt != nil {
            return "다음 세트를 시작할 수 있어요"
        }

        return "세트를 완료하면 타이머가 시작돼요"
    }

    private func activeWorkoutContent(_ state: ActiveWorkoutState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(state.exercises) { exercise in
                WorkoutExerciseSectionView(appStore: appStore, exercise: exercise)
            }
        }
    }

    private var addExerciseMenu: some View {
        Menu {
            ForEach(appStore.exercises) { exercise in
                Button(exercise.displayName) {
                    if appStore.activeWorkout == nil {
                        appStore.startEmptyWorkout()
                    }

                    appStore.addExerciseToActiveWorkout(exercise)
                }
            }
        } label: {
            Label("운동 추가", systemImage: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(AppTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
    }

    private var finishedOrEmptyContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let record = appStore.lastFinishedRecord ?? appStore.history.first {
                FinishedWorkoutSummaryView(record: record)
            } else {
                Text("아직 진행 중인 운동이 없어요")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            }

            Button {
                appStore.startEmptyWorkout()
            } label: {
                Label("빈 운동 시작", systemImage: "plus.circle")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(AppTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            }
        }
    }

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            if let state = appStore.activeWorkout {
                addExerciseMenu

                Button {
                    appStore.finishActiveWorkout()
                } label: {
                    Text("운동 종료")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(state.exercises.isEmpty ? AppTheme.divider : AppTheme.primaryBlue)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                }
                .disabled(state.exercises.isEmpty)
            } else {
                Button {
                    appStore.startEmptyWorkout()
                } label: {
                    Text("빈 운동 시작")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(AppTheme.primaryBlue)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(AppTheme.background)
    }

    private static func formattedDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

private struct WorkoutExerciseSectionView: View {
    @ObservedObject var appStore: AppDataStore
    let exercise: ActiveWorkoutExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(exercise.orderIndex + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: 34, height: 30)
                    .background(AppTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.exerciseName)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("\(exercise.bodyPart.displayName) · \(exercise.sets.count)세트")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()
            }
            .padding(16)

            Divider()
                .overlay(AppTheme.divider)

            VStack(spacing: 0) {
                ForEach(exercise.sets) { set in
                    WorkoutSetRowView(appStore: appStore, exercise: exercise, set: set)

                    if set.id != exercise.sets.last?.id {
                        Divider()
                            .overlay(AppTheme.divider)
                            .padding(.leading, 16)
                    }
                }
            }

            Button {
                appStore.addSetToActiveWorkout(exerciseID: exercise.id)
            } label: {
                Label("세트 추가", systemImage: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}

private struct WorkoutSetRowView: View {
    @ObservedObject var appStore: AppDataStore
    let exercise: ActiveWorkoutExercise
    let set: ActiveWorkoutSet

    var body: some View {
        HStack(spacing: 10) {
            Text("\(set.orderIndex + 1)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(targetText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)

                HStack(spacing: 8) {
                    memoField(title: "kg", text: weightText)
                        .keyboardType(.decimalPad)

                    memoField(title: "회", text: repsText)
                        .keyboardType(.numberPad)
                }
            }

            Spacer(minLength: 6)

            Button {
                appStore.completeActiveSet(exerciseID: exercise.id, setID: set.id)
            } label: {
                Image(systemName: set.completedAt == nil ? "checkmark" : "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(set.completedAt == nil ? AppTheme.primaryText : Color.white)
                    .frame(width: 44, height: 44)
                    .background(set.completedAt == nil ? AppTheme.elevatedSurface : AppTheme.primaryBlue)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            }
            .disabled(set.completedAt != nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var targetText: String {
        let weight = set.targetWeightKg.map { Self.weightFormatter.string(from: NSNumber(value: $0)) ?? "\($0)" }
        let reps = set.targetRepetitions.map { "\($0)회" }

        switch (weight, reps) {
        case (.some(let weight), .some(let reps)):
            return "목표 \(weight)kg · \(reps)"
        case (.some(let weight), .none):
            return "목표 \(weight)kg"
        case (.none, .some(let reps)):
            return "목표 \(reps)"
        case (.none, .none):
            return "목표 없음"
        }
    }

    private var weightText: Binding<String> {
        Binding {
            set.actualWeightKg.map { Self.weightFormatter.string(from: NSNumber(value: $0)) ?? "\($0)" } ?? ""
        } set: { text in
            appStore.updateActiveSetActuals(
                exerciseID: exercise.id,
                setID: set.id,
                actualWeightKg: Self.doubleValue(from: text),
                actualRepetitions: set.actualRepetitions
            )
        }
    }

    private var repsText: Binding<String> {
        Binding {
            set.actualRepetitions.map(String.init) ?? ""
        } set: { text in
            appStore.updateActiveSetActuals(
                exerciseID: exercise.id,
                setID: set.id,
                actualWeightKg: set.actualWeightKg,
                actualRepetitions: Int(text.filter(\.isNumber))
            )
        }
    }

    private func memoField(title: String, text: Binding<String>) -> some View {
        HStack(spacing: 4) {
            TextField(title, text: text)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
                .multilineTextAlignment(.trailing)
                .frame(width: 58)

            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 18, alignment: .leading)
        }
        .frame(width: 88, height: 42)
        .background(AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private static let weightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private static func doubleValue(from text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }
}

private struct FinishedWorkoutSummaryView: View {
    let record: WorkoutSessionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("최근 완료")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)

            Text("\(record.exercises.count)개 운동 · \(completedSetCount)세트")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private var completedSetCount: Int {
        record.exercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.completedAt != nil }.count
        }
    }
}

private struct WorkoutMemoView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutMemoView()
            .environmentObject(AppDataStore())
    }
}
