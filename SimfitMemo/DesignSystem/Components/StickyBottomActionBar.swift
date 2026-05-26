import SwiftUI

struct StickyBottomActionBar: View {
    var leadingSystemImage: String = "plus"
    var leadingAccessibilityLabel: String = "추가"
    var primaryTitle: String
    var primarySystemImage: String?
    var isPrimaryEnabled = true
    var leadingAction: () -> Void
    var primaryAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: leadingAction) {
                Image(systemName: leadingSystemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.primaryText)
                    .frame(width: 52, height: 52)
                    .background(AppTheme.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(leadingAccessibilityLabel)

            PrimaryButton(
                title: primaryTitle,
                systemImage: primarySystemImage,
                isEnabled: isPrimaryEnabled,
                action: primaryAction
            )
        }
        .padding(.horizontal, AppTheme.horizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
    }
}
