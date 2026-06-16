import Foundation

#if canImport(ActivityKit)
import ActivityKit
#endif

@MainActor
final class WorkoutLiveActivityService: ObservableObject {
    #if canImport(ActivityKit)
    @available(iOS 16.2, *)
    private var currentActivity: Activity<WorkoutLiveActivityAttributes>? {
        Activity<WorkoutLiveActivityAttributes>.activities.first
    }
    #endif

    func sync(with workout: ActiveWorkoutState?) {
        #if canImport(ActivityKit)
        guard #available(iOS 16.2, *) else {
            return
        }

        Task {
            await syncActivity(with: workout)
        }
        #endif
    }

    #if canImport(ActivityKit)
    @available(iOS 16.2, *)
    private func syncActivity(with workout: ActiveWorkoutState?) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        guard let workout else {
            await endCurrentActivity()
            return
        }

        let attributes = WorkoutLiveActivityAttributes(
            workoutID: workout.id,
            routineName: workout.routineName ?? "자유 운동"
        )
        let state = WorkoutLiveActivityAttributes.ContentState(workout: workout)
        let content = ActivityContent(state: state, staleDate: state.restEndAt)

        if let currentActivity, currentActivity.attributes.workoutID == workout.id {
            await currentActivity.update(content)
            return
        }

        await endCurrentActivity()

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            return
        }
    }

    @available(iOS 16.2, *)
    private func endCurrentActivity() async {
        guard let currentActivity else {
            return
        }

        let state = WorkoutLiveActivityAttributes.ContentState(
            phase: .finished,
            headline: "운동 완료",
            exerciseName: currentActivity.attributes.routineName,
            setText: "기록 저장됨",
            targetText: "",
            workoutStartedAt: Date(),
            updatedAt: Date()
        )
        await currentActivity.end(
            ActivityContent(state: state, staleDate: Date()),
            dismissalPolicy: .immediate
        )
    }
    #endif
}

#if canImport(ActivityKit)
@available(iOS 16.2, *)
private extension WorkoutLiveActivityAttributes.ContentState {
    init(workout: ActiveWorkoutState, now: Date = Date()) {
        let context = workout.liveActivityDisplayContext
        let remainingRestSeconds = workout.restEndAt.map { max(0, Int(ceil($0.timeIntervalSince(now)))) } ?? 0
        let isResting = remainingRestSeconds > 0

        self.init(
            phase: isResting ? .resting : .working,
            headline: isResting ? "휴식중" : "운동중",
            exerciseName: context?.exercise.exerciseName ?? "다음 운동 없음",
            setText: context.map { "\($0.setNumber)/\($0.totalSets)세트" } ?? "완료",
            targetText: context?.targetText ?? "모든 세트를 완료했어요",
            workoutStartedAt: workout.startedAt,
            restEndAt: isResting ? workout.restEndAt : nil,
            updatedAt: now
        )
    }
}

private struct LiveActivityDisplayContext {
    var exercise: ActiveWorkoutExercise
    var set: ActiveWorkoutSet
    var setNumber: Int
    var totalSets: Int

    var targetText: String {
        let weight = set.targetWeightKg.map {
            String(format: "%.1fkg", $0).replacingOccurrences(of: ".0kg", with: "kg")
        } ?? "-"
        let repetitions = set.targetRepetitions.map { "\($0)회" } ?? "-"
        return "\(weight) x \(repetitions)"
    }
}

private extension ActiveWorkoutState {
    var liveActivityDisplayContext: LiveActivityDisplayContext? {
        let orderedExercises = exercises.sorted { $0.orderIndex < $1.orderIndex }

        if let currentExerciseID, let currentSetID {
            for exercise in orderedExercises where exercise.id == currentExerciseID {
                let orderedSets = exercise.sets.sorted { $0.orderIndex < $1.orderIndex }
                if let setIndex = orderedSets.firstIndex(where: { $0.id == currentSetID }) {
                    return LiveActivityDisplayContext(
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
                return LiveActivityDisplayContext(
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
#endif
