import SafariServices
import SwiftUI

/// SwiftUI wrapper around `SFSafariViewController` for in-app web pages.
public struct SafariView: UIViewControllerRepresentable {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func makeUIViewController(context _: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    public func updateUIViewController(_: SFSafariViewController, context _: Context) {}
}
