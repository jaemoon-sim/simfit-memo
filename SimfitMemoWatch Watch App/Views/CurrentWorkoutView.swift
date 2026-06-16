import SwiftUI
import WatchKit

struct CurrentWorkoutView: View {
    @EnvironmentObject private var watchSyncService: WatchSyncService
    @EnvironmentObject private var heartRateService: HealthKitHeartRateService
    @State private var restCountdownCueTracker = RestCountdownCueTracker()

    private let restTimerCalculator = RestTimerCalculator()

    private var displayState: ActiveWorkoutState? {
        watchSyncService.activeWorkoutSnapshot?.state
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let state = displayState
            let context = state?.displayContext
            let remainingRestSeconds = restTimerCalculator.remainingSeconds(
                restEndAt: state?.restEndAt,
                now: timeline.date
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let state, remainingRestSeconds > 0 {
                        restContent(
                            state: state,
                            nextContext: context,
                            remainingSeconds: remainingRestSeconds
                        )
                    } else if let state, let context {
                        workoutContent(state: state, context: context)
                    } else {
                        EmptyWorkoutStateView()
                    }

                    manualSyncButton
                    deliveryStatus
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(WatchTheme.background)
        }
        .navigationTitle("현재 운동")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            heartRateService.requestAuthorizationAndStart()
        }
    }

    private func workoutContent(state: ActiveWorkoutState, context: WorkoutDisplayContext) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("현재 운동")
                .font(.caption)
                .foregroundStyle(WatchTheme.secondaryText)

            Text(context.exercise.exerciseName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(WatchTheme.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            HStack(spacing: 6) {
                MetricPill(title: "세트", value: "\(context.setNumber)/\(context.totalSets)")
                MetricPill(title: "목표", value: context.targetText)
            }

            heartRateSummary
            completionButton(state: state)
        }
    }

    private func restContent(
        state: ActiveWorkoutState,
        nextContext: WorkoutDisplayContext?,
        remainingSeconds: Int
    ) -> some View {
        let cueSnapshot = RestCountdownCueSnapshot(
            restStartedAt: state.restStartedAt ?? state.restEndAt,
            remainingSeconds: remainingSeconds
        )

        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("휴식중")
                    .font(.caption)
                    .foregroundStyle(WatchTheme.secondaryText)

                Text(format(seconds: remainingSeconds))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(WatchTheme.primaryBlue)
                    .monospacedDigit()
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(WatchTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 6) {
                restAdjustmentButton(title: "-10s", deltaSeconds: -10, state: state, isEnabled: remainingSeconds > 0)
                restAdjustmentButton(title: "+10s", deltaSeconds: 10, state: state, isEnabled: remainingSeconds > 0)
            }

            nextWorkoutGuide(nextContext)
            restCompleteButton(state: state, remainingSeconds: remainingSeconds)
        }
        .onAppear {
            playRestCountdownCues(for: cueSnapshot)
        }
        .onChange(of: cueSnapshot) { _, cueSnapshot in
            playRestCountdownCues(for: cueSnapshot)
        }
    }

    @ViewBuilder
    private func nextWorkoutGuide(_ context: WorkoutDisplayContext?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("다음 운동")
                .font(.caption2)
                .foregroundStyle(WatchTheme.secondaryText)

            if let context {
                Text(context.exercise.exerciseName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(WatchTheme.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text("\(context.setNumber)/\(context.totalSets)세트 · 목표 \(context.targetText)")
                    .font(.caption)
                    .foregroundStyle(WatchTheme.secondaryText)
                    .lineLimit(2)
            } else {
                Text("다음 운동 없음")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(WatchTheme.primaryText)

                Text("모든 세트를 완료했어요.")
                    .font(.caption)
                    .foregroundStyle(WatchTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func playRestCountdownCues(for snapshot: RestCountdownCueSnapshot) {
        for cue in restCountdownCueTracker.cues(for: snapshot) {
            WatchRestCountdownNotifier.play(cue)
        }
    }

    private func restAdjustmentButton(
        title: String,
        deltaSeconds: Int,
        state: ActiveWorkoutState,
        isEnabled: Bool
    ) -> some View {
        Button {
            _ = watchSyncService.sendRestAdjustment(for: state, deltaSeconds: deltaSeconds)
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(deltaSeconds < 0 ? WatchTheme.secondaryText : WatchTheme.primaryBlue)
        .disabled(!isEnabled)
    }

    private func restCompleteButton(state: ActiveWorkoutState, remainingSeconds: Int) -> some View {
        Button {
            _ = watchSyncService.sendRestAdjustment(for: state, deltaSeconds: -remainingSeconds)
        } label: {
            Text("휴식 완료")
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(WatchTheme.primaryBlue)
        .disabled(remainingSeconds <= 0)
    }

    private var heartRateSummary: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 1) {
                Text(heartRateService.state.displayText)
                    .font(.caption2)
                    .foregroundStyle(WatchTheme.secondaryText)

                Text(heartRateText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(WatchTheme.primaryText)
                    .monospacedDigit()
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func completionButton(state: ActiveWorkoutState) -> some View {
        Button {
            _ = watchSyncService.sendCompletion(for: state)
        } label: {
            Text("세트 완료")
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(WatchTheme.primaryBlue)
        .disabled(state.displayContext == nil)
    }

    private var manualSyncButton: some View {
        Button {
            _ = watchSyncService.requestSync()
        } label: {
            Label("동기화", systemImage: "arrow.triangle.2.circlepath")
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(WatchTheme.primaryBlue)
    }

    private var deliveryStatus: some View {
        Group {
            if let result = watchSyncService.lastDeliveryResult {
                Text(result.displayText)
                    .font(.caption2)
                    .foregroundStyle(WatchTheme.secondaryText)
                    .lineLimit(2)
            }
        }
    }

    private var heartRateText: String {
        guard let latestHeartRate = heartRateService.latestHeartRate else {
            return "-- bpm"
        }

        return "\(latestHeartRate) bpm"
    }

    private func format(seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

@MainActor
private enum WatchRestCountdownNotifier {
    static func play(_ cue: RestCountdownCue) {
        switch cue {
        case .tenSeconds, .finalCountdown:
            HeadsetOnlyBeepPlayer.playBeep()
            WKInterfaceDevice.current().play(.notification)
        }
    }
}

private struct MetricPill: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(WatchTheme.secondaryText)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(WatchTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(WatchTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct EmptyWorkoutStateView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("동기화 대기 중")
                .font(.headline)
                .foregroundStyle(WatchTheme.primaryText)

            Text("iPhone에서 운동을 시작하면 여기에 표시됩니다.")
                .font(.caption)
                .foregroundStyle(WatchTheme.secondaryText)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct WorkoutDisplayContext {
    var exercise: ActiveWorkoutExercise
    var set: ActiveWorkoutSet
    var setNumber: Int
    var totalSets: Int

    var targetText: String {
        let weight = set.targetWeightKg.map { String(format: "%.1fkg", $0).replacingOccurrences(of: ".0kg", with: "kg") } ?? "-"
        let repetitions = set.targetRepetitions.map { "\($0)회" } ?? "-"
        return "\(weight) x \(repetitions)"
    }
}

private extension ActiveWorkoutState {
    var displayContext: WorkoutDisplayContext? {
        let orderedExercises = exercises.sorted { $0.orderIndex < $1.orderIndex }

        if let currentExerciseID, let currentSetID {
            for exercise in orderedExercises where exercise.id == currentExerciseID {
                let orderedSets = exercise.sets.sorted { $0.orderIndex < $1.orderIndex }
                if let setIndex = orderedSets.firstIndex(where: { $0.id == currentSetID }) {
                    return WorkoutDisplayContext(
                        exercise: exercise,
                        set: orderedSets[setIndex],
                        setNumber: setIndex + 1,
                        totalSets: orderedSets.count
                    )
                }
            }
        }

        for exercise in orderedExercises {
            let orderedSets = exercise.sets.sorted { $0.orderIndex < $1.orderIndex }
            if let setIndex = orderedSets.firstIndex(where: { $0.completedAt == nil }) {
                return WorkoutDisplayContext(
                    exercise: exercise,
                    set: orderedSets[setIndex],
                    setNumber: setIndex + 1,
                    totalSets: orderedSets.count
                )
            }
        }

        return nil
    }
}

private extension WatchSyncDeliveryResult {
    var displayText: String {
        switch self {
        case .sentLive:
            return "iPhone으로 전송됨"
        case .queuedUserInfo:
            return "연결되면 전송됩니다"
        case .unavailable:
            return "연결을 기다리는 중"
        case .duplicate:
            return "이미 완료 요청됨"
        case .failed:
            return "전송 실패"
        }
    }
}
