import SwiftUI

struct ExerciseRow: View {
    var exercise: Exercise
    var isSelected: Bool
    var isBookmarked: Bool
    var selectionAction: () -> Void
    var bookmarkAction: () -> Void
    var infoAction: () -> Void

    private var equipmentText: String {
        exercise.equipment?.isEmpty == false ? exercise.equipment! : "장비 없음"
    }

    var body: some View {
        HStack(spacing: 12) {
            AppCheckbox(isChecked: isSelected, label: nil, action: selectionAction)

            Text(String(exercise.bodyPart.displayName.prefix(1)))
                .font(AppTheme.bodyFont(14, weight: .black))
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 40, height: 40)
                .background(AppTheme.elevatedSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
                .accessibilityHidden(true)

            Button(action: selectionAction) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(exercise.displayName)
                        .font(AppTheme.bodyFont(16, weight: .bold))
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)

                    Text("\(exercise.bodyPart.displayName) · \(equipmentText)")
                        .font(AppTheme.bodyFont(13, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: bookmarkAction) {
                Image(systemName: isBookmarked ? "star.fill" : "star")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(isBookmarked ? AppTheme.warning : AppTheme.secondaryText)
                    .frame(width: 36, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isBookmarked ? "북마크 해제" : "북마크")

            Button(action: infoAction) {
                Image(systemName: "info.circle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(width: 32, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("운동 정보")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(AppTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(isSelected ? AppTheme.primaryBlue.opacity(0.72) : AppTheme.hairline, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}
