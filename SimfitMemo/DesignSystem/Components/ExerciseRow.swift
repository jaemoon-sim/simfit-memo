import SwiftUI

struct ExerciseRow: View {
    var exercise: Exercise
    var selectionIndex: Int?
    var isBookmarked: Bool
    var selectionAction: () -> Void
    var bookmarkAction: () -> Void
    var infoAction: () -> Void

    private var isSelected: Bool {
        selectionIndex != nil
    }

    private var equipmentText: String {
        exercise.equipment?.isEmpty == false ? exercise.equipment! : "장비 없음"
    }

    var body: some View {
        HStack(spacing: 12) {
            selectionControl

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

    @ViewBuilder
    private var selectionControl: some View {
        if let selectionIndex {
            Button(action: selectionAction) {
                Text("\(selectionIndex)")
                    .font(AppTheme.bodyFont(13, weight: .black))
                    .foregroundStyle(Color.white)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.primaryBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(selectionIndex)번째 선택됨")
        } else {
            AppCheckbox(isChecked: false, label: nil, action: selectionAction)
                .accessibilityLabel("운동 선택")
        }
    }
}
