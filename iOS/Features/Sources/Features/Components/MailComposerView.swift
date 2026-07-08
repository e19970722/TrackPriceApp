import MessageUI
import SwiftUI

/// SwiftUI wrapper around `MFMailComposeViewController`.
/// Check `MailComposerView.canSendMail` before presenting; fall back to a
/// `mailto:` URL when the device has no configured mail account.
public struct MailComposerView: UIViewControllerRepresentable {
    private let recipient: String
    private let subject: String
    private let onDismiss: () -> Void

    public init(recipient: String, subject: String, onDismiss: @escaping () -> Void) {
        self.recipient = recipient
        self.subject = subject
        self.onDismiss = onDismiss
    }

    public static var canSendMail: Bool {
        MFMailComposeViewController.canSendMail()
    }

    public func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([recipient])
        controller.setSubject(subject)
        return controller
    }

    public func updateUIViewController(_: MFMailComposeViewController, context _: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    public final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        private let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        public func mailComposeController(
            _: MFMailComposeViewController,
            didFinishWith _: MFMailComposeResult,
            error _: Error?
        ) {
            onDismiss()
        }
    }
}
