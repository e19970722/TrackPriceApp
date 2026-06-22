import SwiftUI

/// An `accentSoft` callout used to summarize a rule or surface a hint, with a
/// leading SF Symbol (frame 5 of the add-tracker flow uses it for the alert
/// rule summary).
public struct InfoBanner: View {
    let message: String
    var systemImage: String

    public init(message: String, systemImage: String = "bell.fill") {
        self.message = message
        self.systemImage = systemImage
    }

    // MARK: - Body

    public var body: some View {
        bannerContainerView
    }
}

// MARK: - Subviews

extension InfoBanner {
    private var bannerContainerView: some View {
        HStack(alignment: .top, spacing: RipeSpacing.s3) {
            bannerIconView
            bannerMessageText
            Spacer(minLength: 0)
        }
        .padding(RipeSpacing.s4)
        .background(bannerBackgroundView)
    }

    private var bannerIconView: some View {
        Image(systemName: systemImage)
            .iconFont(.bodyIcon)
            .foregroundStyle(Color(.ripeAccent))
    }

    private var bannerMessageText: some View {
        Text(message)
            .customFont(.medium13)
            .foregroundStyle(Color(.ripeInk2))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var bannerBackgroundView: some View {
        RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous)
            .fill(Color(.ripeAccentSoft))
    }
}

// MARK: - Preview

#Preview("InfoBanner") {
    VStack(spacing: RipeSpacing.s4) {
        InfoBanner(message: "We'll alert you when it drops below $89.99. Checked daily.")
        InfoBanner(
            message: "Selector lost — we'll keep trying for 3 days.",
            systemImage: "exclamationmark.triangle.fill"
        )
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("InfoBanner Dark") {
    InfoBanner(message: "We'll alert you when it drops below $89.99. Checked daily.")
        .padding(RipeSpacing.s5)
        .background(Color(.ripeBg))
        .preferredColorScheme(.dark)
}
