import SwiftUI

struct WorkoutHistoryDetailView: View {
    let record: WorkoutSessionRecord

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    AppTopBar(title: "운동 기록", showsBackButton: true, leadingAction: {
                        dismiss()
                    })

                    summaryCard
                    exerciseList
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, AppTheme.screenTopPadding)
                .padding(.bottom, 28)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(record.routineName ?? "자유 운동")
                .font(AppTheme.titleFont(25))
                .foregroundStyle(AppTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                summaryPill(title: "\(record.exercises.count)개 운동", systemImage: "figure.strengthtraining.traditional")
                summaryPill(title: "\(completedSetCount)세트", systemImage: "checkmark")
            }

            Text(dateRangeText)
                .font(AppTheme.bodyFont(13, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(AppTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }

    private var exerciseList: some View {
        VStack(spacing: 12) {
            ForEach(record.exercises.sorted { $0.orderIndex < $1.orderIndex }) { exercise in
                WorkoutHistoryExerciseCard(exercise: exercise)
            }
        }
    }

    private func summaryPill(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(AppTheme.bodyFont(13, weight: .bold))
            .foregroundStyle(AppTheme.primaryBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(AppTheme.softBlue.opacity(0.24))
            .clipShape(Capsule())
    }

    private var completedSetCount: Int {
        record.exercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.completedAt != nil }.count
        }
    }

    private var dateRangeText: String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "yyyy년 M월 d일"

        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "ko_KR")
        timeFormatter.dateFormat = "a h:mm"

        if let endedAt = record.endedAt {
            return "\(dateFormatter.string(from: record.startedAt)) · \(timeFormatter.string(from: record.startedAt)) - \(timeFormatter.string(from: endedAt))"
        }

        return "\(dateFormatter.string(from: record.startedAt)) · \(timeFormatter.string(from: record.startedAt)) 시작"
    }
}

private struct WorkoutHistoryExerciseCard: View {
    let exercise: WorkoutExerciseRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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

            Divider()
                .overlay(AppTheme.divider)

            VStack(spacing: 0) {
                ForEach(exercise.sets.sorted { $0.orderIndex < $1.orderIndex }) { set in
                    WorkoutHistorySetRow(set: set)

                    if set.id != exercise.sets.last?.id {
                        Divider()
                            .overlay(AppTheme.divider)
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}

private struct WorkoutHistorySetRow: View {
    let set: WorkoutSetRecord

    var body: some View {
        HStack(spacing: 12) {
            Text("\(set.orderIndex + 1)")
                .font(AppTheme.bodyFont(14, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(resultText)
                    .font(AppTheme.bodyFont(15, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text(targetText)
                    .font(AppTheme.bodyFont(12, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Image(systemName: set.completedAt == nil ? "circle" : "checkmark.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(set.completedAt == nil ? AppTheme.tertiaryText : AppTheme.primaryBlue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var resultText: String {
        let weight = set.actualWeightKg ?? set.targetWeightKg
        let repetitions = set.actualRepetitions ?? set.targetRepetitions

        switch (weight, repetitions) {
        case (.some(let weight), .some(let repetitions)):
            return "\(Self.weightText(weight))kg · \(repetitions)회"
        case (.some(let weight), .none):
            return "\(Self.weightText(weight))kg"
        case (.none, .some(let repetitions)):
            return "\(repetitions)회"
        case (.none, .none):
            return "기록 없음"
        }
    }

    private var targetText: String {
        let weight = set.targetWeightKg.map { "\(Self.weightText($0))kg" }
        let repetitions = set.targetRepetitions.map { "\($0)회" }

        switch (weight, repetitions) {
        case (.some(let weight), .some(let repetitions)):
            return "목표 \(weight) · \(repetitions) · 휴식 \(set.restSeconds)초"
        case (.some(let weight), .none):
            return "목표 \(weight) · 휴식 \(set.restSeconds)초"
        case (.none, .some(let repetitions)):
            return "목표 \(repetitions) · 휴식 \(set.restSeconds)초"
        case (.none, .none):
            return "목표 없음 · 휴식 \(set.restSeconds)초"
        }
    }

    private static func weightText(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
