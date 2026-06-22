import SwiftUI

/// A centered warning/confirmation dialog presented over a dimming scrim.
/// Shows an icon in a tinted circle, a title, a body, and a split
/// Cancel / confirm button row. Used for the already-meets-target warning
/// (frame 6 of the add-tracker flow).
public struct CenteredDialog: View {
    let systemImage: String
    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    public init(
        systemImage: String,
        title: String,
        message: String,
        cancelTitle: String,
        confirmTitle: String,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.cancelTitle = cancelTitle
        self.confirmTitle = confirmTitle
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    // MARK: - Body

    public var body: some View {
        dialogOverlayView
    }
}

// MARK: - Subviews

extension CenteredDialog {
    private var dialogOverlayView: some View {
        ZStack {
            scrimView
            dialogCardView
        }
    }

    private var scrimView: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture(perform: onCancel)
    }

    private var dialogCardView: some View {
        VStack(spacing: RipeSpacing.s4) {
            iconBadgeView
            titleText
            messageText
            buttonRowView
        }
        .padding(RipeSpacing.s5)
        .frame(maxWidth: 340)
        .background(cardBackgroundView)
        .padding(.horizontal, RipeSpacing.s6)
    }

    private var iconBadgeView: some View {
        Image(systemName: systemImage)
            .iconFont(.lg)
            .foregroundStyle(Color(.ripeWarn))
            .frame(width: 56, height: 56)
            .background(Circle().fill(Color(.ripeWarnSoft)))
    }

    private var titleText: some View {
        Text(title)
            .customFont(.bold19)
            .foregroundStyle(Color(.ripeInk))
            .multilineTextAlignment(.center)
    }

    private var messageText: some View {
        Text(message)
            .customFont(.medium13)
            .foregroundStyle(Color(.ripeInk2))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var buttonRowView: some View {
        HStack(spacing: RipeSpacing.s3) {
            RipeButton(
                title: cancelTitle,
                variant: .secondary,
                size: .md,
                fullWidth: true,
                action: onCancel
            )
            RipeButton(
                title: confirmTitle,
                variant: .primary,
                size: .md,
                fullWidth: true,
                action: onConfirm
            )
        }
    }

    private var cardBackgroundView: some View {
        RoundedRectangle(cornerRadius: RipeRadius.card, style: .continuous)
            .fill(Color(.ripeSurface))
            .ripeShadow(.card)
    }
}

// MARK: - Preview

#Preview("CenteredDialog") {
    CenteredDialog(
        systemImage: "target",
        title: "Already meets target",
        message: "The current price ($79.00) already meets your target of $89.99. Save anyway?",
        cancelTitle: "Cancel",
        confirmTitle: "Save anyway",
        onCancel: {},
        onConfirm: {}
    )
    .background(Color(.ripeBg))
}

#Preview("CenteredDialog Dark") {
    CenteredDialog(
        systemImage: "target",
        title: "Already meets target",
        message: "The current price ($79.00) already meets your target of $89.99. Save anyway?",
        cancelTitle: "Cancel",
        confirmTitle: "Save anyway",
        onCancel: {},
        onConfirm: {}
    )
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
