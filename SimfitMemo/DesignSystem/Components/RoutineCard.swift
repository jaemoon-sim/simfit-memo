import SwiftUI

struct RoutineCard: View {
    var routine: Routine
    var onTap: () -> Void
    var onEdit: () -> Void = {}
    var onDuplicate: () -> Void = {}
    var onDelete: () -> Void = {}

    private var bodyPartSummary: String {
        var orderedParts: [String] = []
        for exercise in routine.exercises {
            let name = exercise.bodyPart.displayName
            if !orderedParts.contains(name) {
                orderedParts.append(name)
            }
        }

        return orderedParts.isEmpty ? "운동 없음" : orderedParts.prefix(3).joined(separator: ", ")
    }

    private var lastPerformedText: String {
        guard let date = routine.lastPerformedAt else {
            return "수행 정보 없음"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 d일"
        return "최근 수행 \(formatter.string(from: date))"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(routine.name)
                            .font(AppTheme.bodyFont(18, weight: .bold))
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(1)

                        if routine.completedCount > 0 {
                            Text("\(routine.completedCount)회")
                                .font(AppTheme.bodyFont(12, weight: .bold))
                                .foregroundStyle(AppTheme.primaryBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.softBlue.opacity(0.28))
                                .clipShape(Capsule())
                        }

                        Spacer(minLength: 0)
                    }

                    Text(bodyPartSummary)
                        .font(AppTheme.bodyFont(14, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)

                    HStack(spacing: 7) {
                        Image(systemName: "clock")
                            .font(.system(size: 12, weight: .semibold))
                        Text(lastPerformedText)
                            .font(AppTheme.bodyFont(13, weight: .medium))
                    }
                    .foregroundStyle(AppTheme.tertiaryText)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Menu {
                Button("편집", action: onEdit)
                Button("복제", action: onDuplicate)
                Button("삭제", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(AppTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.hairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}
