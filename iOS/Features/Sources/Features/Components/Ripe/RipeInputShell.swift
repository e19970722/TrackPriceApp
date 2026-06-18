import SwiftUI

/// Styled input container. The caller provides the inner content (icon, text, chevron, etc.)
/// This shell handles all border, background, and focus-ring styling.
public struct RipeInputShell<Content: View>: View {
    let isFocused: Bool
    @ViewBuilder let content: () -> Content

    public init(
        isFocused: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isFocused = isFocused
        self.content = content
    }

    // MARK: - Body

    public var body: some View {
        inputShellContainerView
    }
}

// MARK: - Subviews

extension RipeInputShell {
    private var inputShellContainerView: some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 52)
            .background(shellBackgroundView)
            .overlay(shellBorderView)
    }

    private var shellBackgroundView: some View {
        RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous)
            .fill(Color(.ripeSurface))
    }

    @ViewBuilder
    private var shellBorderView: some View {
        if isFocused {
            focusedBorderView
        } else {
            defaultBorderView
        }
    }

    private var defaultBorderView: some View {
        RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous)
            .strokeBorder(Color(.ripeLine), lineWidth: 1.5)
    }

    private var focusedBorderView: some View {
        RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous)
            .strokeBorder(Color(.ripeAccent), lineWidth: 1.5)
            .shadow(color: Color(.ripeAccentSoft), radius: 3, x: 0, y: 0)
    }
}

// MARK: - Preview

#Preview("RipeInputShell") {
    VStack(spacing: RipeSpacing.s4) {
        RipeInputShell {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color(.ripeInk3))
                Text("Search products...")
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk3))
                Spacer()
            }
        }
        RipeInputShell(isFocused: true) {
            HStack {
                Image(systemName: "link")
                    .foregroundStyle(Color(.ripeAccent))
                Text("https://example.com/product")
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk))
                Spacer()
            }
        }
        RipeInputShell {
            HStack {
                Text("Select category")
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk3))
                Spacer()
                Image(systemName: "chevron.right")
                    .iconFont(.sm)
                    .foregroundStyle(Color(.ripeInk3))
            }
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("RipeInputShell Dark") {
    VStack(spacing: RipeSpacing.s4) {
        RipeInputShell {
            HStack {
                Text("Product name")
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk))
                Spacer()
            }
        }
        RipeInputShell(isFocused: true) {
            HStack {
                Text("Focused state")
                    .customFont(.semibold15)
                    .foregroundStyle(Color(.ripeInk))
                Spacer()
            }
        }
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
