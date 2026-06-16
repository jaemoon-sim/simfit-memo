import ActivityKit
import SwiftUI
import WidgetKit

struct SimfitMemoLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutLiveActivityAttributes.self) { context in
            LiveActivityLockScreenView(
                routineName: context.attributes.routineName,
                state: context.state
            )
            .activityBackgroundTint(Color(red: 0.04, green: 0.06, blue: 0.09))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    phaseBadge(context.state)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    timerText(context.state)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.exerciseName)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                        Text("\(context.state.setText) · \(context.state.targetText)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: context.state.phase == .resting ? "timer" : "figure.strengthtraining.traditional")
                    .foregroundStyle(Color(red: 0.13, green: 0.48, blue: 1.0))
            } compactTrailing: {
                timerText(context.state)
                    .font(.caption2.bold())
                    .monospacedDigit()
            } minimal: {
                Image(systemName: context.state.phase == .resting ? "timer" : "checkmark.circle.fill")
                    .foregroundStyle(Color(red: 0.13, green: 0.48, blue: 1.0))
            }
        }
    }

    @ViewBuilder
    private func phaseBadge(_ state: WorkoutLiveActivityAttributes.ContentState) -> some View {
        HStack(spacing: 6) {
            Image(systemName: state.phase == .resting ? "timer" : "figure.strengthtraining.traditional")
            Text(state.headline)
        }
        .font(.caption.bold())
        .foregroundStyle(Color(red: 0.13, green: 0.48, blue: 1.0))
    }

    @ViewBuilder
    private func timerText(_ state: WorkoutLiveActivityAttributes.ContentState) -> some View {
        if state.phase == .resting, let restEndAt = state.restEndAt {
            Text(timerInterval: Date()...restEndAt, countsDown: true)
        } else {
            Text(state.workoutStartedAt, style: .timer)
        }
    }
}

private struct LiveActivityLockScreenView: View {
    var routineName: String
    var state: WorkoutLiveActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.10, green: 0.14, blue: 0.21))

                Image(systemName: state.phase == .resting ? "timer" : "figure.strengthtraining.traditional")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(red: 0.13, green: 0.48, blue: 1.0))
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 5) {
                Text(routineName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(state.exerciseName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(state.setText) · \(state.targetText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(state.headline)
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 0.13, green: 0.48, blue: 1.0))

                timerText
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private var timerText: some View {
        if state.phase == .resting, let restEndAt = state.restEndAt {
            Text(timerInterval: Date()...restEndAt, countsDown: true)
        } else {
            Text(state.workoutStartedAt, style: .timer)
        }
    }
}
