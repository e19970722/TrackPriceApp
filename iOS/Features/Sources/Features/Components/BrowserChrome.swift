import SwiftUI

/// A minimal browser address bar shown above the embedded webview during the
/// add-tracker flow (frames 2–4). Displays a lock glyph and the current page's
/// host, with an optional reload affordance.
public struct BrowserChrome: View {
    let host: String
    var isLoading: Bool
    var onReload: (() -> Void)?

    public init(
        host: String,
        isLoading: Bool = false,
        onReload: (() -> Void)? = nil
    ) {
        self.host = host
        self.isLoading = isLoading
        self.onReload = onReload
    }

    // MARK: - Body

    public var body: some View {
        chromeContainerView
    }
}

// MARK: - Subviews

extension BrowserChrome {
    private var chromeContainerView: some View {
        HStack(spacing: RipeSpacing.s2) {
            lockIconView
            hostTextView
            Spacer(minLength: RipeSpacing.s2)
            trailingAccessoryView
        }
        .padding(.horizontal, RipeSpacing.s4)
        .frame(height: 44)
        .background(addressPillView)
        .padding(.horizontal, RipeSpacing.s4)
        .padding(.vertical, RipeSpacing.s2)
        .background(Color(.ripeBg))
    }

    private var lockIconView: some View {
        Image(systemName: "lock.fill")
            .iconFont(.sm)
            .foregroundStyle(Color(.ripeInk3))
    }

    private var hostTextView: some View {
        Text(host)
            .customFont(.semibold13)
            .foregroundStyle(Color(.ripeInk2))
            .lineLimit(1)
            .truncationMode(.middle)
    }

    @ViewBuilder
    private var trailingAccessoryView: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
        } else if let onReload {
            reloadButton(onReload)
        }
    }

    private func reloadButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "arrow.clockwise")
                .iconFont(.sm)
                .foregroundStyle(Color(.ripeInk2))
        }
        .buttonStyle(.plain)
    }

    private var addressPillView: some View {
        RoundedRectangle(cornerRadius: RipeRadius.sm, style: .continuous)
            .fill(Color(.ripeSurface2))
    }
}

// MARK: - Preview

#Preview("BrowserChrome") {
    VStack(spacing: 0) {
        BrowserChrome(host: "store.com", onReload: {})
        BrowserChrome(host: "www.amazon.com", isLoading: true)
        Spacer()
    }
    .background(Color(.ripeBg))
}

#Preview("BrowserChrome Dark") {
    VStack(spacing: 0) {
        BrowserChrome(host: "store.com", onReload: {})
        Spacer()
    }
    .background(Color(.ripeBg))
    .preferredColorScheme(.dark)
}
