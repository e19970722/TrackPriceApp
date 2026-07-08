import Perception
import SwiftUI

/// A surface card with automatic light/dark styling.
/// Light mode: soft shadow. Dark mode: 1pt line stroke, no shadow.
/// Stores `content` as an escaping closure evaluated in `body` (an untracked scope),
/// so `body` wraps itself in `WithPerceptionTracking` to keep store reads inside tracked.
public struct RipeCard<Content: View>: View {
    var padding: CGFloat
    @ViewBuilder var content: () -> Content

    public init(
        padding: CGFloat = RipeSpacing.s4,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.padding = padding
        self.content = content
    }

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            cardContainerView
        }
    }
}

// MARK: - Subviews

extension RipeCard {
    private var cardContainerView: some View {
        content()
            .padding(padding)
            .background(cardBackgroundView)
    }

    @ViewBuilder
    private var cardBackgroundView: some View {
        if colorScheme == .dark {
            darkModeBackground
        } else {
            lightModeBackground
        }
    }

    private var lightModeBackground: some View {
        RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous)
            .fill(Color(.ripeSurface))
            .ripeShadow(.soft)
    }

    private var darkModeBackground: some View {
        RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous)
            .fill(Color(.ripeSurface))
            .overlay(
                RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous)
                    .strokeBorder(Color(.ripeLine), lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview("RipeCard") {
    VStack(spacing: RipeSpacing.s4) {
        RipeCard {
            VStack(alignment: .leading, spacing: RipeSpacing.s2) {
                Text("Light Mode Card")
                    .customFont(.bold19)
                    .foregroundStyle(Color(.ripeInk))
                Text("Soft shadow, ripeSurface background.")
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk2))
            }
        }

        RipeCard(padding: RipeSpacing.s3) {
            Text("Custom padding card")
                .customFont(.semibold13)
                .foregroundStyle(Color(.ripeInk))
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("RipeCard Dark") {
    VStack(spacing: RipeSpacing.s4) {
        RipeCard {
            VStack(alignment: .leading, spacing: RipeSpacing.s2) {
                Text("Dark Mode Card")
                    .customFont(.bold19)
                    .foregroundStyle(Color(.ripeInk))
                Text("Line stroke, no shadow.")
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk2))
            }
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
