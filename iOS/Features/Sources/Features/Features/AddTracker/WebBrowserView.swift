import ComposableArchitecture
import SwiftUI

// MARK: - WebBrowserView

/// Frames 2–4. Hosts the embedded webview with browser chrome, a bottom dock to
/// arm element picking (frame 2), the floating selection-mode banner once armed
/// (frame 3), and the confirm-price bottom sheet once an element is picked
/// (frame 4).
struct WebBrowserView: View {
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>

    // MARK: - Body

    var body: some View {
        WithPerceptionTracking {
            ZStack {
                backgroundLayer
                contentLayer
                if store.isSelecting {
                    selectionBannerOverlay
                }
            }
            .sheet(isPresented: confirmationSheetBinding) {
                confirmationSheetContent
            }
        }
    }
}

// MARK: - Subviews

extension WebBrowserView {
    private var backgroundLayer: some View {
        Color(.ripeBg).ignoresSafeArea()
    }

    private var contentLayer: some View {
        VStack(spacing: 0) {
            headerView
            browserChromeView
            webViewLayer
            if !store.isSelecting {
                dockView
            }
        }
    }

    private var headerView: some View {
        RipeModalHeader(
            title: L10n.AddTracker.navTitleBrowse,
            leadingText: L10n.Common.cancel,
            onLeadingTap: { store.send(.dismiss) }
        )
    }

    private var browserChromeView: some View {
        BrowserChrome(
            host: store.currentURL?.host ?? "",
            isLoading: store.isLoadingPage
        )
    }

    private var webViewLayer: some View {
        WebViewContainer(
            url: store.currentURL,
            isPickerActive: store.isSelecting,
            onElementPicked: { info in store.send(.elementPicked(info)) },
            onNavigated: { url in store.send(.webViewNavigated(url)) },
            onLoadStateChanged: { isLoading in store.send(.pageLoadStateChanged(isLoading)) }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var dockView: some View {
        Dock(helperText: L10n.AddTracker.browseHelper) {
            RipeButton(
                title: L10n.AddTracker.pickElement,
                variant: .primary,
                size: .lg,
                systemImage: "cursorarrow.rays",
                fullWidth: true,
                cornerRadius: RipeRadius.card,
                action: { store.send(.pickElementTapped) }
            )
        }
    }

    private var selectionBannerOverlay: some View {
        VStack {
            Spacer()
            SelectionModeBanner(
                title: L10n.AddTracker.selectionModeTitle,
                message: L10n.AddTracker.selectionModeBody,
                onClose: { store.send(.selectionCancelled) }
            )
            .padding(.bottom, RipeSpacing.s7)
        }
    }

    private var confirmationSheetContent: some View {
        WithPerceptionTracking {
            if case let .confirmation(info) = store.step {
                confirmSheet(for: info)
            }
        }
    }

    private func confirmSheet(for info: ElementInfo) -> some View {
        ConfirmPriceSheet(
            rawText: info.rawText,
            currencySymbol: info.currencySymbol,
            detectedPrice: info.currentPrice,
            onUsePrice: { store.send(.confirmationConfirmed) },
            onPickAgain: { store.send(.confirmationRejected) }
        )
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Helpers

extension WebBrowserView {
    private var confirmationSheetBinding: Binding<Bool> {
        Binding(
            get: {
                if case .confirmation = store.step { return true }
                return false
            },
            set: { isPresented in
                if !isPresented, case .confirmation = store.step {
                    store.send(.confirmationRejected)
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    WebBrowserView(store: Store(
        initialState: {
            var state = AddTrackerFeature.State()
            state.step = .webView
            state.currentURL = URL(string: "https://store.com/product")
            return state
        }()
    ) {
        AddTrackerFeature()
    })
}
