import SwiftUI

struct RoutineDetailSheet: View {
    var routine: Routine

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    BottomSheetHeader(title: routine.name, actionTitle: "편집") {}

                    VStack(spacing: 10) {
                        ForEach(routine.exercises.sorted { $0.orderIndex < $1.orderIndex }) { exercise in
                            RoutineDetailExerciseRow(exercise: exercise)
                        }
                    }
                    .padding(.horizontal, AppTheme.horizontalPadding)
                    .padding(.bottom, 92)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "운동 시작하기", systemImage: "play.fill") {}
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        }
        .preferredColorScheme(.dark)
    }
}

private struct RoutineDetailExerciseRow: View {
    var exercise: RoutineExercise

    private var setCount: Int {
        max(exercise.setTargets.count, 1)
    }

    private var summaryText: String {
        let totalVolume = exercise.setTargets.reduce(0.0) { partial, target in
            guard let weight = target.targetWeightKg, let repetitions = target.targetRepetitions else {
                return partial
            }
            return partial + (weight * Double(repetitions))
        }

        let totalRepetitions = exercise.setTargets.compactMap(\.targetRepetitions).reduce(0, +)

        if totalVolume > 0 {
            return "\(setCount)세트 · 총 \(Int(totalVolume))kg"
        } else if totalRepetitions > 0 {
            return "\(setCount)세트 · 총 \(totalRepetitions)회"
        } else {
            return "\(setCount)세트 · 목표 미정"
        }
    }

    var body: some View {
        HStack(spacing: 13) {
            Text("\(exercise.orderIndex + 1)")
                .font(AppTheme.bodyFont(15, weight: .black))
                .foregroundStyle(Color.white)
                .frame(width: 34, height: 34)
                .background(AppTheme.primaryBlue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(exercise.exerciseName)
                    .font(AppTheme.bodyFont(16, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)

                Text("\(exercise.bodyPart.displayName) · \(summaryText)")
                    .font(AppTheme.bodyFont(13, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.down")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.tertiaryText)
                .frame(width: 28, height: 28)
        }
        .padding(15)
        .background(AppTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}
