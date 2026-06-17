import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct WorkoutMemoView: View {
    @EnvironmentObject private var appStore: AppDataStore
    @EnvironmentObject private var watchSyncService: WatchSyncService
    @State private var isAddingExercises = false
    @State private var isReorderingExercises = false
    @State private var finishedWorkoutAlert: FinishedWorkoutAlert?
    @State private var latestWatchTransferResult: WatchSyncDeliveryResult?
    @State private var restCountdownCueTracker = RestCountdownCueTracker()

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
            .scrollDismissesKeyboard(.interactively)
        }
        .background(KeyboardDismissTapInstaller {
            dismissKeyboard()
        })
        .safeAreaInset(edge: .bottom) {
            bottomActionBar
        }
        .navigationDestination(isPresented: $isAddingExercises) {
            ExerciseSelectionView(
                exercises: appStore.exercises,
                selectionTitle: "운동 추가"
            ) { selectedExercises in
                for exercise in selectedExercises {
                    appStore.addExerciseToActiveWorkout(exercise)
                }
            }
        }
        .alert(item: $finishedWorkoutAlert) { summary in
            Alert(
                title: Text("운동 완료"),
                message: Text("총 운동시간 \(summary.durationText)\n\(summary.completedSetCount)세트 기록했어요."),
                dismissButton: .default(Text("확인"))
            )
        }
        .onChange(of: appStore.activeWorkout?.id) { _, activeWorkoutID in
            if activeWorkoutID == nil {
                isReorderingExercises = false
            }
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
                    workoutSubtitle
                }

                Spacer()

                startMenu
            }

            restSummary

            if appStore.activeWorkout != nil {
                watchTransferControl
            }
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

    @ViewBuilder
    private var workoutSubtitle: some View {
        if let activeWorkout = appStore.activeWorkout {
            TimelineView(.periodic(from: Date(), by: 1)) { context in
                Text("\(activeWorkout.routineName ?? "자유 운동") · \(Self.formattedWorkoutDuration(activeWorkout.elapsedWorkoutSeconds(now: context.date))) 경과")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .monospacedDigit()
            }
        } else {
            Text("자유 운동")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var restSummary: some View {
        TimelineView(.periodic(from: Date(), by: 1)) { context in
            let activeWorkout = appStore.activeWorkout
            let remaining = appStore.remainingRestSeconds(now: context.date)
            let cueSnapshot = RestCountdownCueSnapshot(
                restStartedAt: activeWorkout?.restStartedAt ?? activeWorkout?.restEndAt,
                remainingSeconds: remaining
            )

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
            .onAppear {
                playRestCountdownCues(for: cueSnapshot)
            }
            .onChange(of: cueSnapshot) { _, cueSnapshot in
                playRestCountdownCues(for: cueSnapshot)
            }
        }
    }

    private func playRestCountdownCues(for snapshot: RestCountdownCueSnapshot) {
        for cue in restCountdownCueTracker.cues(for: snapshot) {
            RestCountdownSoundPlayer.play(cue)
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

    private var watchTransferControl: some View {
        HStack(spacing: 12) {
            Image(systemName: "applewatch")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 42, height: 42)
                .background(AppTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text("Watch 전송")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(
                    latestWatchTransferResult?.phoneDisplayText(connectionState: watchSyncService.connectionState)
                    ?? watchSyncService.connectionState.phoneIdleText
                )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button {
                sendCurrentStateToWatch()
            } label: {
                Text("전송")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .background(AppTheme.primaryBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private func sendCurrentStateToWatch() {
        watchSyncService.activate()
        latestWatchTransferResult = watchSyncService.sendFullSnapshot(
            activeWorkout: appStore.activeWorkout,
            routines: appStore.routines,
            history: appStore.history
        )
    }

    private func activeWorkoutContent(_ state: ActiveWorkoutState) -> some View {
        let orderedExercises = state.exercises.sortedByWorkoutOrder()

        return VStack(alignment: .leading, spacing: 14) {
            if orderedExercises.count > 1 {
                HStack {
                    Spacer()

                    Button {
                        withAnimation(.snappy) {
                            isReorderingExercises.toggle()
                        }
                        dismissKeyboard()
                    } label: {
                        Label(isReorderingExercises ? "완료" : "순서 변경", systemImage: "arrow.up.arrow.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isReorderingExercises ? AppTheme.primaryText : AppTheme.primaryBlue)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            ForEach(Array(orderedExercises.enumerated()), id: \.element.id) { index, exercise in
                WorkoutExerciseSectionView(
                    appStore: appStore,
                    exercise: exercise,
                    isReordering: isReorderingExercises,
                    canMoveUp: index > 0,
                    canMoveDown: index < orderedExercises.count - 1
                )
            }
        }
    }

    private var addExerciseButton: some View {
        Button {
            isAddingExercises = true
        } label: {
            Label("운동 추가", systemImage: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(AppTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
        .buttonStyle(.plain)
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
                addExerciseButton

                Button {
                    if let record = appStore.finishActiveWorkout() {
                        finishedWorkoutAlert = FinishedWorkoutAlert(record: record)
                    }
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

    fileprivate static func formattedWorkoutDuration(_ seconds: Int) -> String {
        let clampedSeconds = max(0, seconds)
        let hours = clampedSeconds / 3_600
        let minutes = (clampedSeconds % 3_600) / 60
        let seconds = clampedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }

    private func dismissKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }
}

private struct FinishedWorkoutAlert: Identifiable {
    let id: UUID
    let durationText: String
    let completedSetCount: Int

    init(record: WorkoutSessionRecord) {
        id = record.id
        durationText = WorkoutMemoView.formattedWorkoutDuration(record.workoutDurationSeconds())
        completedSetCount = record.completedSetCount
    }
}

private extension WatchSyncDeliveryResult {
    func phoneDisplayText(connectionState: WatchSyncConnectionState) -> String {
        switch self {
        case .sentLive:
            return "워치로 즉시 전송했습니다"
        case .queuedApplicationContext:
            return "워치가 열리면 최신 상태로 반영됩니다"
        case .queuedUserInfo:
            return "연결되면 워치로 전송됩니다"
        case .unavailable:
            return connectionState.unavailableDisplayText
        case .failed(let message):
            return "전송 실패: \(message)"
        }
    }
}

private extension WatchSyncConnectionState {
    var phoneIdleText: String {
        switch self {
        case .unavailable:
            return "이 기기에서 Watch 동기화를 사용할 수 없어요"
        case .inactive:
            return "Watch 연결 준비 중입니다"
        case .activated:
            return "전송 가능: 워치가 열리면 반영됩니다"
        case .reachable:
            return "전송 가능: 워치로 즉시 보낼 수 있어요"
        case .notPaired:
            return "페어링된 Apple Watch가 없습니다"
        case .watchAppNotInstalled:
            return "워치 앱 설치 상태를 확인해주세요"
        case .failed(let message):
            return "Watch 연결 오류: \(message)"
        }
    }

    var unavailableDisplayText: String {
        switch self {
        case .notPaired:
            return "페어링된 Apple Watch가 없습니다"
        case .watchAppNotInstalled:
            return "워치 앱이 설치되지 않은 것으로 인식됩니다"
        case .unavailable:
            return "WatchConnectivity를 사용할 수 없어요"
        case .inactive:
            return "Watch 연결 준비 중입니다. 잠시 후 다시 시도해주세요"
        case .failed(let message):
            return "Watch 연결 오류: \(message)"
        case .activated:
            return "워치가 바로 응답하지 않아 백그라운드 전송이 필요합니다"
        case .reachable:
            return "워치 연결 상태를 다시 확인해주세요"
        }
    }
}

@MainActor
private enum RestCountdownSoundPlayer {
    static func play(_ cue: RestCountdownCue) {
        switch cue {
        case .tenSeconds, .finalCountdown:
            HeadsetOnlyBeepPlayer.playBeep()
            playHaptic()
        }
    }

    private static func playHaptic() {
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }
}

private struct WorkoutExerciseSectionView: View {
    @ObservedObject var appStore: AppDataStore
    let exercise: ActiveWorkoutExercise
    let isReordering: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool

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

                if isReordering {
                    HStack(spacing: 8) {
                        reorderButton(systemName: "chevron.up", direction: .up, isEnabled: canMoveUp)
                        reorderButton(systemName: "chevron.down", direction: .down, isEnabled: canMoveDown)
                    }
                }
            }
            .padding(16)

            Divider()
                .overlay(AppTheme.divider)

            VStack(spacing: 0) {
                ForEach(exercise.sets) { set in
                    WorkoutSetRowView(
                        appStore: appStore,
                        exercise: exercise,
                        set: set,
                        previousPerformance: appStore.history.latestSetPerformance(
                            matching: exercise,
                            setOrderIndex: set.orderIndex,
                            before: appStore.activeWorkout?.startedAt
                        )
                    )

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

    private func reorderButton(
        systemName: String,
        direction: ActiveWorkoutExerciseMoveDirection,
        isEnabled: Bool
    ) -> some View {
        Button {
            withAnimation(.snappy) {
                _ = appStore.moveActiveWorkoutExercise(exerciseID: exercise.id, direction: direction)
            }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(isEnabled ? AppTheme.primaryBlue : AppTheme.secondaryText.opacity(0.45))
                .frame(width: 36, height: 36)
                .background(AppTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

private struct WorkoutSetRowView: View {
    @ObservedObject var appStore: AppDataStore
    let exercise: ActiveWorkoutExercise
    let set: ActiveWorkoutSet
    let previousPerformance: PreviousWorkoutSetPerformance?

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
            return previousPerformanceText ?? "목표 없음"
        }
    }

    private var previousPerformanceText: String? {
        guard let previousPerformance else {
            return nil
        }

        let weight = previousPerformance.weightKg.map { Self.weightFormatter.string(from: NSNumber(value: $0)) ?? "\($0)" }
        let reps = previousPerformance.repetitions.map { "\($0)회" }

        switch (weight, reps) {
        case (.some(let weight), .some(let reps)):
            return "직전 \(weight)kg · \(reps)"
        case (.some(let weight), .none):
            return "직전 \(weight)kg"
        case (.none, .some(let reps)):
            return "직전 \(reps)"
        case (.none, .none):
            return nil
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
            Text("총 운동시간 \(Self.formattedWorkoutDuration(record.workoutDurationSeconds()))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private var completedSetCount: Int {
        record.completedSetCount
    }

    private static func formattedWorkoutDuration(_ seconds: Int) -> String {
        let clampedSeconds = max(0, seconds)
        let hours = clampedSeconds / 3_600
        let minutes = (clampedSeconds % 3_600) / 60
        let seconds = clampedSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%d:%02d", minutes, seconds)
    }
}

private extension WorkoutSessionRecord {
    var completedSetCount: Int {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.completedAt != nil }.count
        }
    }
}

private extension Array where Element == ActiveWorkoutExercise {
    func sortedByWorkoutOrder() -> [ActiveWorkoutExercise] {
        enumerated()
            .sorted { lhs, rhs in
                if lhs.element.orderIndex == rhs.element.orderIndex {
                    return lhs.offset < rhs.offset
                }

                return lhs.element.orderIndex < rhs.element.orderIndex
            }
            .map(\.element)
    }
}

#if canImport(UIKit)
private struct KeyboardDismissTapInstaller: UIViewRepresentable {
    var onTapOutsideInput: () -> Void

    func makeUIView(context: Context) -> UIView {
        UIView(frame: .zero)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onTapOutsideInput = onTapOutsideInput

        DispatchQueue.main.async {
            guard let window = uiView.window else {
                return
            }

            context.coordinator.installIfNeeded(on: window)
        }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTapOutsideInput: onTapOutsideInput)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onTapOutsideInput: () -> Void
        private weak var installedWindow: UIWindow?
        private weak var recognizer: UITapGestureRecognizer?

        init(onTapOutsideInput: @escaping () -> Void) {
            self.onTapOutsideInput = onTapOutsideInput
        }

        func installIfNeeded(on window: UIWindow) {
            guard installedWindow !== window else {
                return
            }

            uninstall()

            let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            window.addGestureRecognizer(recognizer)
            installedWindow = window
            self.recognizer = recognizer
        }

        func uninstall() {
            if let recognizer, let installedWindow {
                installedWindow.removeGestureRecognizer(recognizer)
            }

            installedWindow = nil
            recognizer = nil
        }

        @objc private func handleTap() {
            onTapOutsideInput()
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var touchedView: UIView? = touch.view
            while let view = touchedView {
                if view is UITextField || view is UITextView {
                    return false
                }

                touchedView = view.superview
            }

            return true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
#else
private struct KeyboardDismissTapInstaller: View {
    var onTapOutsideInput: () -> Void

    var body: some View {
        EmptyView()
    }
}
#endif

private struct WorkoutMemoView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutMemoView()
            .environmentObject(AppDataStore())
            .environmentObject(WatchSyncService())
    }
}
