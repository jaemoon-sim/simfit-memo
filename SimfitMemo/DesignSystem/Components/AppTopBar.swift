import SwiftUI

struct AppTopBar: View {
    var title: String
    var showsBackButton = false
    var leadingAction: (() -> Void)?
    var trailingSystemImage: String?
    var trailingTitle: String?
    var trailingAction: (() -> Void)?

    var body: some View {
        ZStack {
            Text(title)
                .font(AppTheme.bodyFont(17, weight: .bold))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)

            HStack {
                if showsBackButton {
                    AppIconButton(systemName: "chevron.left", action: leadingAction ?? {})
                        .accessibilityLabel("뒤로가기")
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                }

                Spacer()

                if let trailingSystemImage {
                    AppIconButton(systemName: trailingSystemImage, action: trailingAction ?? {})
                        .accessibilityLabel(trailingTitle ?? "추가")
                } else if let trailingTitle {
                    Button(action: trailingAction ?? {}) {
                        Text(trailingTitle)
                            .font(AppTheme.bodyFont(15, weight: .bold))
                            .foregroundStyle(AppTheme.primaryBlue)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
        }
        .frame(height: 48)
    }
}

struct AppIconButton: View {
    var systemName: String
    var foregroundColor: Color = AppTheme.primaryText
    var backgroundColor: Color = .clear
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: 44, height: 44)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
        }
        .buttonStyle(.plain)
    }
}
