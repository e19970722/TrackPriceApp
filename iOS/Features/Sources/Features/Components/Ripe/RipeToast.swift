import SwiftUI

/// A floating, danger-toned toast for surfacing a transient error (e.g. a failed
/// network request). It pairs a leading SF Symbol with a multiline message and
/// trailing controls: an always-present Close button and an optional Retry button.
///
/// ## Auto-dismiss
/// The toast **always** dismisses itself 3 seconds after appearing, regardless of
/// whether a Retry button is shown. The timer is owned by the component via a
/// `.task` modifier, so it is cancelled automatically if the view disappears early.
///
/// ## Callbacks
/// - `onDismiss` is invoked both by the auto-dismiss timer and by the Close (X) button.
/// - `onRetry`, when non-nil, renders the Retry button and is the only thing tapping
///   Retry triggers — Retry does **not** call `onDismiss`. If the caller wants the
///   toast to disappear on retry, it should dismiss it from its own `onRetry` handler.
public struct RipeToast: View {
    /// How long the toast stays on screen before auto-dismissing.
    public static let autoDismissDuration: Duration = .seconds(3)

    let message: String
    var systemImage: String
    var onDismiss: () -> Void
    var onRetry: (() -> Void)?

    public init(
        message: String,
        systemImage: String = "wifi.slash",
        onDismiss: @escaping () -> Void,
        onRetry: (() -> Void)? = nil
    ) {
        self.message = message
        self.systemImage = systemImage
        self.onDismiss = onDismiss
        self.onRetry = onRetry
    }

    // MARK: - Body

    public var body: some View {
        toastContainerView
            .task {
                try? await Task.sleep(for: Self.autoDismissDuration)
                guard !Task.isCancelled else { return }
                onDismiss()
            }
    }
}

// MARK: - Subviews

extension RipeToast {
    private var toastContainerView: some View {
        HStack(alignment: .top, spacing: RipeSpacing.s3) {
            toastIconView
            toastMessageText
            Spacer(minLength: RipeSpacing.s2)
            toastControlsView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RipeSpacing.s4)
        .background(Color(.ripeDangerSoft))
        .clipShape(RoundedRectangle(cornerRadius: RipeRadius.control, style: .continuous))
        .ripeShadow(.card)
    }

    private var toastIconView: some View {
        Image(systemName: systemImage)
            .iconFont(.bodyIcon)
            .foregroundStyle(Color(.ripeDanger))
    }

    private var toastMessageText: some View {
        Text(message)
            .customFont(.semibold15)
            .foregroundStyle(Color(.ripeInk))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var toastControlsView: some View {
        HStack(spacing: RipeSpacing.s2) {
            if let onRetry {
                retryButton(onRetry)
            }
            closeButton
        }
    }

    private func retryButton(_ action: @escaping () -> Void) -> some View {
        RipeButton(
            title: "Retry",
            variant: .danger,
            size: .sm,
            action: action
        )
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            closeIconView
        }
        .buttonStyle(.plain)
    }

    private var closeIconView: some View {
        Image(systemName: "xmark")
            .iconFont(.sm)
            .foregroundStyle(Color(.ripeInk2))
            .frame(width: 28, height: 28)
    }
}

// MARK: - Preview

#Preview("RipeToast") {
    VStack(spacing: RipeSpacing.s4) {
        RipeToast(
            message: "Could not connect to the server.",
            onDismiss: {}
        )
        RipeToast(
            message: "Could not connect to the server. Check your connection and try again.",
            onDismiss: {},
            onRetry: {}
        )
    }
    .padding(RipeSpacing.s5)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.ripeBg))
}
