import SwiftUI

struct CurrentWorkoutView: View {
    @EnvironmentObject private var watchSyncService: WatchSyncService
    @EnvironmentObject private var heartRateService: HealthKitHeartRateService

    private let restTimerCalculator = RestTimerCalculator()

    private var displayState: ActiveWorkoutState {
        watchSyncService.activeWorkoutSnapshot?.state ?? WatchMockData.activeWorkoutState
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let state = displayState
            let context = state.displayContext

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    header(for: state)

                    if let context {
                        exerciseSummary(context)
                        restTimer(state: state, context: context, now: timeline.date)
                        heartRateSummary
                        completionButton(state: state)
                    } else {
                        EmptyWorkoutStateView()
                    }

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

    private func header(for state: ActiveWorkoutState) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(state.routineName ?? "진행 중인 운동")
                .font(.caption)
                .foregroundStyle(WatchTheme.secondaryText)
                .lineLimit(1)

            Text("현재 운동")
                .font(.headline)
                .foregroundStyle(WatchTheme.primaryText)
        }
    }

    private func exerciseSummary(_ context: WorkoutDisplayContext) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(context.exercise.exerciseName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(WatchTheme.primaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            HStack(spacing: 6) {
                MetricPill(title: "세트", value: "\(context.setNumber)/\(context.totalSets)")
                MetricPill(title: "목표", value: context.targetText)
            }
        }
        .padding(10)
        .background(WatchTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func restTimer(state: ActiveWorkoutState, context: WorkoutDisplayContext, now: Date) -> some View {
        let restEndAt = state.restEndAt ?? context.set.completedAt.map {
            restTimerCalculator.restEndDate(startedAt: $0, restSeconds: context.set.restSeconds)
        }
        let remaining = restTimerCalculator.remainingSeconds(restEndAt: restEndAt, now: now)

        return VStack(alignment: .leading, spacing: 2) {
            Text(remaining > 0 ? "휴식" : "다음 세트")
                .font(.caption2)
                .foregroundStyle(WatchTheme.secondaryText)

            Text(remaining > 0 ? format(seconds: remaining) : "준비 완료")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(WatchTheme.primaryBlue)
                .monospacedDigit()
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(WatchTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
