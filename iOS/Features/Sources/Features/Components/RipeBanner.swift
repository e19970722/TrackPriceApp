import SwiftUI

/// A soft-tinted callout used to surface a hint, rule summary, or warning, with a
/// leading SF Symbol and a multiline message. The `Tone` controls the icon color
/// and background tint.
public struct RipeBanner: View {
    public enum Tone {
        case info
        case warning
        case danger

        var iconColor: Color {
            switch self {
            case .info, .warning: Color(.ripeWarn)
            case .danger: Color(.ripeDanger)
            }
        }

        var backgroundColor: Color {
            switch self {
            case .info, .warning: Color(.ripeWarnSoft)
            case .danger: Color(.ripeDangerSoft)
            }
        }
    }

    let message: String
    var systemImage: String
    var tone: Tone

    public init(message: String, systemImage: String = "bell.fill", tone: Tone = .info) {
        self.message = message
        self.systemImage = systemImage
        self.tone = tone
    }

    // MARK: - Body

    public var body: some View {
        bannerContainerView
    }
}

// MARK: - Subviews

extension RipeBanner {
    private var bannerContainerView: some View {
        HStack(alignment: .center, spacing: RipeSpacing.s3) {
            bannerIconView
            bannerMessageText
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RipeSpacing.s4)
        .background(tone.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: RipeRadius.control, style: .continuous))
    }

    private var bannerIconView: some View {
        Image(systemName: systemImage)
            .iconFont(.bodyIcon)
            .foregroundStyle(tone.iconColor)
    }

    private var bannerMessageText: some View {
        Text(message)
            .customFont(.semibold15)
            .foregroundStyle(Color(.ripeInk))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Preview

#Preview("RipeBanner") {
    VStack(spacing: RipeSpacing.s4) {
        RipeBanner(message: "We'll alert you when it drops below $89.99. Checked daily.", tone: .info)
        RipeBanner(
            message: "Heads up — this reminder is set close to the best-before date.",
            systemImage: "exclamationmark.triangle.fill",
            tone: .warning
        )
        RipeBanner(
            message: "This reminder is in the past and won't fire.",
            systemImage: "exclamationmark.octagon.fill",
            tone: .danger
        )
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}
