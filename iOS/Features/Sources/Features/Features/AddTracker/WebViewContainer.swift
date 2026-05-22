import SwiftUI
import WebKit

// MARK: - WebViewContainer

public struct WebViewContainer: UIViewRepresentable {
    let url: URL?
    let isPickerActive: Bool
    let onElementPicked: (ElementInfo) -> Void
    let onNavigated: (URL) -> Void
    let onLoadStateChanged: (Bool) -> Void

    public init(
        url: URL?,
        isPickerActive: Bool,
        onElementPicked: @escaping (ElementInfo) -> Void,
        onNavigated: @escaping (URL) -> Void,
        onLoadStateChanged: @escaping (Bool) -> Void
    ) {
        self.url = url
        self.isPickerActive = isPickerActive
        self.onElementPicked = onElementPicked
        self.onNavigated = onNavigated
        self.onLoadStateChanged = onLoadStateChanged
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            onElementPicked: onElementPicked,
            onNavigated: onNavigated,
            onLoadStateChanged: onLoadStateChanged
        )
    }

    public func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "elementPicked")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView

        if let url {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    public func updateUIView(_ webView: WKWebView, context: Context) {
        // Load new URL if it changed
        if let url, webView.url != url,
           context.coordinator.lastLoadedURL != url {
            context.coordinator.lastLoadedURL = url
            webView.load(URLRequest(url: url))
        }

        // Inject picker JS when toggled on
        let wasActive = context.coordinator.wasPickerActive
        if isPickerActive && !wasActive {
            context.coordinator.injectPickerScript(into: webView)
        }
        context.coordinator.wasPickerActive = isPickerActive
    }

    // MARK: - Coordinator

    public class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var webView: WKWebView?
        var lastLoadedURL: URL?
        var wasPickerActive: Bool = false

        let onElementPicked: (ElementInfo) -> Void
        let onNavigated: (URL) -> Void
        let onLoadStateChanged: (Bool) -> Void

        init(
            onElementPicked: @escaping (ElementInfo) -> Void,
            onNavigated: @escaping (URL) -> Void,
            onLoadStateChanged: @escaping (Bool) -> Void
        ) {
            self.onElementPicked = onElementPicked
            self.onNavigated = onNavigated
            self.onLoadStateChanged = onLoadStateChanged
        }

        func injectPickerScript(into webView: WKWebView) {
            webView.evaluateJavaScript(ElementPickerScript.javascript, completionHandler: nil)
        }

        // MARK: WKScriptMessageHandler

        public func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "elementPicked",
                  let body = message.body as? String,
                  let data = body.data(using: .utf8),
                  let payload = try? JSONDecoder().decode(ElementPickerPayload.self, from: data)
            else { return }

            let info = ElementInfo(
                cssSelector: payload.cssSelector,
                xpath: payload.xpath,
                rawText: payload.rawText,
                currentPrice: payload.currentPrice,
                currencySymbol: payload.currencySymbol
            )
            DispatchQueue.main.async {
                self.onElementPicked(info)
            }
        }

        // MARK: WKNavigationDelegate

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            onLoadStateChanged(true)
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoadStateChanged(false)
            if let url = webView.url {
                onNavigated(url)
            }
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            onLoadStateChanged(false)
        }

        public func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            onLoadStateChanged(false)
        }
    }
}

// MARK: - Decodable payload from JS

private struct ElementPickerPayload: Decodable {
    let cssSelector: String
    let xpath: String
    let rawText: String
    let currentPrice: Double?
    let currencySymbol: String
}
