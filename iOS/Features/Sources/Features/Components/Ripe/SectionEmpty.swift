import SwiftUI

/// A compact empty-state placeholder row for a Home section.
///
/// Renders a dashed, transparent-fill container with a leading accent-tinted
/// icon tile (with a subtle diagonal stripe texture) and a short hint message.
/// Callers wrap this in `WithPerceptionTracking` when reading observable state.
public struct SectionEmpty: View {
    let systemImage: String
    let text: String
    let height: CGFloat

    public init(
        systemImage: String,
        text: String,
        height: CGFloat = RipeSectionEmpty.defaultHeight
    ) {
        self.systemImage = systemImage
        self.text = text
        self.height = height
    }

    // MARK: - Body

    public var body: some View {
        emptyRow
    }
}

// MARK: - Subviews

extension SectionEmpty {
    private var emptyRow: some View {
        HStack(spacing: RipeSectionEmpty.gap) {
            iconTile
            messageText
            Spacer(minLength: 0)
        }
        .padding(.horizontal, RipeSectionEmpty.horizontalPadding)
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .background(containerBackground)
    }

    private var iconTile: some View {
        Image(systemName: systemImage)
            .iconFont(size: RipeSectionEmpty.iconSize, weight: .semibold)
            .foregroundStyle(Color(.ripeAccent))
            .frame(width: RipeSectionEmpty.tileSize, height: RipeSectionEmpty.tileSize)
            .background(iconTileBackground)
            .overlay(iconTileStripes)
            .clipShape(
                RoundedRectangle(cornerRadius: RipeSectionEmpty.tileRadius, style: .continuous)
            )
    }

    private var iconTileBackground: some View {
        RoundedRectangle(cornerRadius: RipeSectionEmpty.tileRadius, style: .continuous)
            .fill(Color(.ripeAccentSoft))
    }

    private var iconTileStripes: some View {
        DiagonalStripes(
            color: Color(.ripeInk).opacity(0.05),
            stripeWidth: 3,
            gap: 5
        )
    }

    private var messageText: some View {
        Text(text)
            .customFont(.medium13)
            .lineSpacing(RipeSectionEmpty.lineSpacing)
            .foregroundStyle(Color(.ripeInk3))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var containerBackground: some View {
        RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous)
            .fill(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous)
                    .strokeBorder(
                        Color(.ripeLine),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 5])
                    )
            )
    }
}

// MARK: - Preview

#Preview("SectionEmpty") {
    VStack(spacing: RipeSpacing.s4) {
        SectionEmpty(
            systemImage: "sparkles",
            text: "Follow markets to see what's trending up or down.",
            height: RipeSectionEmpty.trendHeight
        )
        SectionEmpty(
            systemImage: "clock",
            text: "Add an expiry date and items running out soon land here."
        )
        SectionEmpty(
            systemImage: "tag",
            text: "Set a target price and we'll flag the moment it's hit."
        )
    }
    .padding(RipeSpacing.s5)
    .background(Color(.ripeBg))
}
