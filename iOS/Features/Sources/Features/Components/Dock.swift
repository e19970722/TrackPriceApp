import SwiftUI

/// A pinned bottom action container with a top gradient fade that blends the
/// dock into the scrolling content above it. Used at the bottom of flow screens
/// to host primary CTAs (Next, Pick element, Save, …).
public struct Dock<Content: View>: View {
    var helperText: String?
    @ViewBuilder var content: () -> Content

    public init(
        helperText: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.helperText = helperText
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        dockContainerView
    }
}

// MARK: - Subviews

extension Dock {
    private var dockContainerView: some View {
        VStack(spacing: RipeSpacing.s3) {
            if let helperText {
                helperTextView(helperText)
            }
            content()
        }
        .padding(.horizontal, RipeSpacing.s5)
        .padding(.top, RipeSpacing.s4)
        .padding(.bottom, RipeSpacing.s5)
        .frame(maxWidth: .infinity)
        .background(dockBackgroundView)
    }

    private func helperTextView(_ text: String) -> some View {
        Text(text)
            .customFont(.medium13)
            .foregroundStyle(Color(.ripeInk3))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var dockBackgroundView: some View {
        ZStack(alignment: .top) {
            Color(.ripeBg)
            fadeGradientView
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var fadeGradientView: some View {
        LinearGradient(
            colors: [Color(.ripeBg).opacity(0), Color(.ripeBg)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 24)
        .offset(y: -24)
    }
}

// MARK: - Preview

#Preview("Dock") {
    VStack {
        Spacer()
        Dock {
            RipeButton(
                title: "Next",
                size: .lg,
                trailingSystemImage: "arrow.right",
                fullWidth: true,
                cornerRadius: RipeRadius.card,
                action: {}
            )
        }
    }
    .background(Color(.ripeBg))
}

#Preview("Dock with helper") {
    VStack {
        Spacer()
        Dock(helperText: "Browse to the right page, then tap to start picking.") {
            RipeButton(
                title: "Pick element",
                size: .lg,
                systemImage: "cursorarrow.rays",
                fullWidth: true,
                cornerRadius: RipeRadius.card,
                action: {}
            )
        }
    }
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
