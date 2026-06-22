import SwiftUI

/// A floating dark banner overlaid near the bottom of the armed webview during
/// element selection (frame 3). Shows a cursor avatar, a title + instruction,
/// and a close affordance to cancel selection mode.
public struct SelectionModeBanner: View {
    let title: String
    let message: String
    let onClose: () -> Void

    public init(
        title: String,
        message: String,
        onClose: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.onClose = onClose
    }

    // MARK: - Body

    public var body: some View {
        bannerContainerView
    }
}

// MARK: - Subviews

extension SelectionModeBanner {
    private var bannerContainerView: some View {
        HStack(spacing: RipeSpacing.s3) {
            cursorAvatarView
            bannerTextStack
            Spacer(minLength: RipeSpacing.s2)
            closeButton
        }
        .padding(RipeSpacing.s3)
        .background(bannerBackgroundView)
        .padding(.horizontal, RipeSpacing.s5)
    }

    private var cursorAvatarView: some View {
        Image(systemName: "cursorarrow.rays")
            .iconFont(.md)
            .foregroundStyle(Color(.ripeAccentInk))
            .frame(width: 40, height: 40)
            .background(Circle().fill(Color(.ripeAccent)))
    }

    private var bannerTextStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .customFont(.bold15)
                .foregroundStyle(.white)
            Text(message)
                .customFont(.medium13)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .iconFont(.sm)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(.white.opacity(0.14)))
        }
        .buttonStyle(.plain)
    }

    private var bannerBackgroundView: some View {
        RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous)
            .fill(Color(red: 0.11, green: 0.10, blue: 0.09))
            .ripeShadow(.card)
    }
}

// MARK: - Preview

#Preview("SelectionModeBanner") {
    VStack {
        Spacer()
        SelectionModeBanner(
            title: "Selection Mode",
            message: "Tap the price you want to track",
            onClose: {}
        )
        .padding(.bottom, RipeSpacing.s7)
    }
    .background(Color(.ripeSurface2))
}
