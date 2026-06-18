import SwiftUI

/// The two interactive variants a settings row can take.
public enum RipeSettingsRowVariant {
    case toggle(isOn: Bool, onToggle: () -> Void)
    case disclosure(action: () -> Void)
}

/// Standard settings list row. Supports toggle and disclosure variants.
public struct RipeSettingsRow: View {
    let title: String
    var subtitle: String?
    var systemImage: String?
    let variant: RipeSettingsRowVariant

    public init(
        title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        variant: RipeSettingsRowVariant
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.variant = variant
    }

    // MARK: - Body

    public var body: some View {
        rowContainerView
    }
}

// MARK: - Subviews

extension RipeSettingsRow {
    private var rowContainerView: some View {
        VStack(spacing: 0) {
            rowContentView
            separatorLine
        }
    }

    private var rowContentView: some View {
        Button(action: rowAction) {
            rowInnerView
        }
        .buttonStyle(.plain)
        .frame(minHeight: 52)
    }

    private var rowInnerView: some View {
        HStack(spacing: RipeSpacing.s3) {
            if let systemImage {
                leadingIconView(systemImage)
            }
            textStackView
            Spacer()
            trailingControlView
        }
        .padding(.horizontal, RipeSpacing.s5)
    }

    private func leadingIconView(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(Color(.ripeAccent))
            .frame(width: 24, height: 24)
    }

    private var textStackView: some View {
        VStack(alignment: .leading, spacing: 2) {
            titleTextView
            if let subtitle {
                subtitleTextView(subtitle)
            }
        }
    }

    private var titleTextView: some View {
        Text(title)
            .font(CustomFont.label(16))
            .foregroundStyle(Color(.ripeInk))
    }

    private func subtitleTextView(_ text: String) -> some View {
        Text(text)
            .font(CustomFont.caption(12))
            .foregroundStyle(Color(.ripeInk2))
    }

    @ViewBuilder
    private var trailingControlView: some View {
        switch variant {
        case let .toggle(isOn, onToggle):
            RipeToggle(isOn: isOn, onToggle: onToggle)
        case .disclosure:
            disclosureChevron
        }
    }

    private var disclosureChevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color(.ripeInk3))
    }

    private var separatorLine: some View {
        Rectangle()
            .fill(Color(.ripeLine))
            .frame(height: 1)
            .padding(.leading, RipeSpacing.s5)
    }
}

// MARK: - Helpers

extension RipeSettingsRow {
    private var rowAction: () -> Void {
        switch variant {
        case let .toggle(_, onToggle): onToggle
        case let .disclosure(action): action
        }
    }
}

// MARK: - Preview

#Preview("RipeSettingsRow") {
    VStack(spacing: 0) {
        RipeSettingsRow(
            title: "Push Notifications",
            systemImage: "bell.fill",
            variant: .toggle(isOn: true, onToggle: {})
        )
        RipeSettingsRow(
            title: "Price Alerts",
            subtitle: "Notify when below target",
            systemImage: "tag.fill",
            variant: .toggle(isOn: false, onToggle: {})
        )
        RipeSettingsRow(
            title: "Account",
            systemImage: "person.fill",
            variant: .disclosure(action: {})
        )
        RipeSettingsRow(
            title: "Privacy Policy",
            subtitle: "Last updated Jan 2025",
            variant: .disclosure(action: {})
        )
        RipeSettingsRow(
            title: "Help & Support",
            variant: .disclosure(action: {})
        )
    }
    .background(Color(.ripeSurface))
    .clipShape(RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous))
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("RipeSettingsRow Dark") {
    VStack(spacing: 0) {
        RipeSettingsRow(
            title: "Notifications",
            systemImage: "bell.fill",
            variant: .toggle(isOn: true, onToggle: {})
        )
        RipeSettingsRow(
            title: "Subscription",
            subtitle: "Free tier",
            systemImage: "crown.fill",
            variant: .disclosure(action: {})
        )
    }
    .background(Color(.ripeSurface))
    .clipShape(RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous))
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
