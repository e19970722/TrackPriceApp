import SwiftUI

/// The visual style of a `RipeButton`.
public enum RipeButtonVariant {
    case primary
    case secondary
    case ghost
    case outline
}

/// The size of a `RipeButton`, controlling height and font size.
public enum RipeButtonSize {
    case sm
    case md
    case lg
}

/// A pill-shaped button following the Ripe design system.
public struct RipeButton: View {
    let title: String
    var variant: RipeButtonVariant
    var size: RipeButtonSize
    var systemImage: String?
    var trailingSystemImage: String?
    var fullWidth: Bool
    var action: () -> Void

    public init(
        title: String,
        variant: RipeButtonVariant = .primary,
        size: RipeButtonSize = .md,
        systemImage: String? = nil,
        trailingSystemImage: String? = nil,
        fullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.size = size
        self.systemImage = systemImage
        self.trailingSystemImage = trailingSystemImage
        self.fullWidth = fullWidth
        self.action = action
    }

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    public var body: some View {
        Button(action: action) {
            buttonLabelView
        }
        .buttonStyle(ripeButtonStyle)
    }
}

// MARK: - Subviews

extension RipeButton {

    private var buttonLabelView: some View {
        HStack(spacing: RipeSpacing.s2) {
            if let systemImage {
                leadingIconView(systemImage)
            }
            buttonTitleText
            if let trailingSystemImage {
                trailingIconView(trailingSystemImage)
            }
        }
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .frame(height: buttonHeight)
        .padding(.horizontal, horizontalPadding)
        .background(buttonBackgroundView)
        .foregroundStyle(foregroundColor)
        .overlay(outlineStrokeView)
    }

    private func leadingIconView(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: iconSize, weight: .semibold))
    }

    private var buttonTitleText: some View {
        Text(title)
            .font(labelFont)
            .fontWeight(.semibold)
    }

    private func trailingIconView(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: iconSize, weight: .semibold))
    }

    private var buttonBackgroundView: some View {
        Capsule()
            .fill(backgroundColor)
            .ripeShadow(backgroundShadow)
    }

    @ViewBuilder
    private var outlineStrokeView: some View {
        if variant == .outline {
            Capsule()
                .strokeBorder(Color(.ripeLine), lineWidth: 1.5)
        }
    }

    private var ripeButtonStyle: some PrimitiveButtonStyle {
        PlainButtonStyle()
    }
}

// MARK: - Helpers

extension RipeButton {

    private var buttonHeight: CGFloat {
        switch size {
        case .sm: return 38
        case .md: return 46
        case .lg: return 54
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .sm: return RipeSpacing.s3
        case .md: return RipeSpacing.s4
        case .lg: return RipeSpacing.s5
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .sm: return 13
        case .md: return 15
        case .lg: return 17
        }
    }

    private var labelFont: Font {
        switch size {
        case .sm: return RipeFont.label(13)
        case .md: return RipeFont.label(15)
        case .lg: return RipeFont.label(17)
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:   return Color(.ripeAccent)
        case .secondary: return Color(.ripeSurface2)
        case .ghost:     return .clear
        case .outline:   return .clear
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:   return Color(.ripeAccentInk)
        case .secondary: return Color(.ripeInk)
        case .ghost:     return Color(.ripeAccent)
        case .outline:   return Color(.ripeInk)
        }
    }

    private var backgroundShadow: RipeShadow {
        guard variant == .primary, colorScheme == .light else {
            return RipeShadow(color: .clear, radius: 0, x: 0, y: 0)
        }
        return .soft
    }
}

// MARK: - Preview

#Preview("RipeButton") {
    VStack(spacing: RipeSpacing.s3) {
        RipeButton(title: "Primary", action: {})
        RipeButton(title: "Secondary", variant: .secondary, action: {})
        RipeButton(title: "Ghost", variant: .ghost, action: {})
        RipeButton(title: "Outline", variant: .outline, action: {})
        RipeButton(title: "Primary Small", size: .sm, action: {})
        RipeButton(title: "Primary Large", size: .lg, action: {})
        RipeButton(title: "With Icon", systemImage: "cart.fill", action: {})
        RipeButton(
            title: "Full Width",
            trailingSystemImage: "arrow.right",
            fullWidth: true,
            action: {}
        )
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}

#Preview("RipeButton Dark") {
    VStack(spacing: RipeSpacing.s3) {
        RipeButton(title: "Primary", action: {})
        RipeButton(title: "Secondary", variant: .secondary, action: {})
        RipeButton(title: "Ghost", variant: .ghost, action: {})
        RipeButton(title: "Outline", variant: .outline, action: {})
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
