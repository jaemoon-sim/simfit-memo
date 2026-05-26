import SwiftUI

struct CategoryChip: View {
    var title: String
    var systemImage: String?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .bold))
                }

                Text(title)
                    .font(AppTheme.bodyFont(14, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.white : AppTheme.secondaryText)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(isSelected ? AppTheme.primaryBlue : AppTheme.surface)
            .overlay {
                Capsule()
                    .stroke(isSelected ? AppTheme.primaryBlue : AppTheme.divider, lineWidth: 1)
            }
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
