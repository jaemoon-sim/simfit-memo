import SwiftUI

struct PrimaryButton: View {
    var title: String
    var systemImage: String?
    var isEnabled = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            PrimaryButtonLabel(title: title, systemImage: systemImage, isEnabled: isEnabled)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct OutlineButton: View {
    var title: String
    var systemImage: String?
    var isEnabled = true
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            OutlineButtonLabel(title: title, systemImage: systemImage, isEnabled: isEnabled)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

struct PrimaryButtonLabel: View {
    var title: String
    var systemImage: String?
    var isEnabled = true

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
            }

            Text(title)
                .font(AppTheme.bodyFont(15, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(Color.white.opacity(isEnabled ? 1 : 0.55))
        .frame(maxWidth: .infinity, minHeight: AppTheme.controlHeight)
        .padding(.horizontal, 12)
        .background(isEnabled ? AppTheme.primaryBlue : AppTheme.elevatedSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}

struct OutlineButtonLabel: View {
    var title: String
    var systemImage: String?
    var isEnabled = true

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
            }

            Text(title)
                .font(AppTheme.bodyFont(15, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(isEnabled ? AppTheme.primaryText : AppTheme.tertiaryText)
        .frame(maxWidth: .infinity, minHeight: AppTheme.controlHeight)
        .padding(.horizontal, 12)
        .background(AppTheme.recessedSurface)
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                .stroke(AppTheme.divider, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
    }
}
