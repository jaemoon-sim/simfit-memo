import SwiftUI

struct CurrentWorkoutView: View {
    private let restTimerCalculator = RestTimerCalculator()
    private let restEndAt = Date.now.addingTimeInterval(90)

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            VStack(alignment: .leading, spacing: 8) {
                Text("현재 운동")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("바벨 벤치프레스")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack {
                    MetricPill(title: "세트", value: "1/3")
                    MetricPill(title: "목표", value: "60kg x 8")
                }

                Spacer(minLength: 4)

                Text(restText(now: timeline.date))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.12, green: 0.48, blue: 1.0))
                    .monospacedDigit()

                Button("완료") {}
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(red: 0.04, green: 0.05, blue: 0.07))
        }
    }

    private func restText(now: Date) -> String {
        let remaining = restTimerCalculator.remainingSeconds(restEndAt: restEndAt, now: now)
        return remaining > 0 ? "\(remaining)초 휴식" : "다음 세트"
    }
}

private struct MetricPill: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color(red: 0.12, green: 0.15, blue: 0.20))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
