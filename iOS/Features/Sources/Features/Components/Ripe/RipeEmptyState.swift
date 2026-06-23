import SwiftUI

/// The full-screen empty-state illustration used when a list has no content.
///
/// A centered column: a tinted illustration tile with a subtle diagonal-stripe
/// texture and a centered icon, a display title, and a multiline body. An
/// optional call-to-action button can be supplied; when omitted, no button is
/// rendered (e.g. screens that already host a FAB).
///
/// Generic component — it does NOT add `WithPerceptionTracking`; the caller is
/// responsible for wrapping its own state reads.
public struct RipeEmptyState: View {
    private let icon: String
    private let title: String
    private let message: String
    private let ctaTitle: String?
    private let ctaAction: (() -> Void)?

    public init(
        icon: String,
        title: String,
        message: String,
        ctaTitle: String? = nil,
        ctaAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.ctaTitle = ctaTitle
        self.ctaAction = ctaAction
    }

    // MARK: - Body

    public var body: some View {
        contentColumn
    }
}

// MARK: - Subviews

extension RipeEmptyState {
    private var contentColumn: some View {
        VStack(spacing: RipeEmptyStateLayout.verticalSpacing) {
            illustrationTile
            textColumn
            ctaButton
        }
        .frame(maxWidth: .infinity, minHeight: RipeEmptyStateLayout.minHeight)
        .padding(.horizontal, RipeSpacing.s5)
    }

    private var illustrationTile: some View {
        iconView
            .frame(
                width: RipeEmptyStateLayout.tileSize,
                height: RipeEmptyStateLayout.tileSize
            )
            .background(tileBackground)
            .overlay(tileStripes)
            .clipShape(tileShape)
    }

    private var iconView: some View {
        Image(systemName: icon)
            .iconFont(size: RipeEmptyStateLayout.iconSize, weight: .regular)
            .foregroundStyle(Color(.ripeAccent))
    }

    private var tileBackground: some View {
        tileShape.fill(Color(.ripeAccentSoft))
    }

    private var tileStripes: some View {
        DiagonalStripes(color: Color(.ripeInk).opacity(0.045))
    }

    private var tileShape: RoundedRectangle {
        RoundedRectangle(
            cornerRadius: RipeEmptyStateLayout.tileRadius,
            style: .continuous
        )
    }

    private var textColumn: some View {
        VStack(spacing: RipeEmptyStateLayout.textSpacing) {
            titleText
            messageText
        }
    }

    private var titleText: some View {
        Text(title)
            .customFont(.extrabold22)
            .foregroundStyle(Color(.ripeInk))
            .multilineTextAlignment(.center)
    }

    private var messageText: some View {
        Text(message)
            .customFont(.medium15)
            .foregroundStyle(Color(.ripeInk3))
            .multilineTextAlignment(.center)
            .lineSpacing(RipeEmptyStateLayout.bodyLineSpacing)
            .frame(maxWidth: RipeEmptyStateLayout.bodyMaxWidth)
    }

    @ViewBuilder
    private var ctaButton: some View {
        if let ctaTitle, let ctaAction {
            RipeButton(title: ctaTitle, action: ctaAction)
        }
    }
}

// MARK: - Preview

#Preview("Prices") {
    RipeEmptyState(
        icon: "tag",
        title: "No price tracks yet",
        message: "Paste a product link and pick the price on the page — "
            + "we'll watch it and ping you when it drops. Tap + to start."
    )
    .background(Color(.ripeBg))
}

#Preview("Expire Dates") {
    RipeEmptyState(
        icon: "clock",
        title: "No expiry tracks yet",
        message: "Add an item with its expiry date and we'll remind you "
            + "before it goes off. Tap + to start."
    )
    .background(Color(.ripeBg))
}
