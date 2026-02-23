import SwiftUI

struct OnboardingCard<Content: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: action) {
            content()
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isSelected ? Color.manor.primary.opacity(0.15) : Color.manor.surfaceContainer)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isSelected ? Color.manor.primary : Color.manor.outlineVariant, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingIconCard: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        OnboardingCard(isSelected: isSelected, action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.manor.primary.opacity(0.2) : Color.manor.surfaceContainerHigh)
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.manor.primary : Color.manor.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Color.manor.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(Color.manor.textTertiary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.manor.primary)
                }
            }
        }
    }
}
