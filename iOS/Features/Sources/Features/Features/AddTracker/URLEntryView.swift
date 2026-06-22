import ComposableArchitecture
import SwiftUI
import UIKit

// MARK: - URLEntryView

/// Frame 1 — URL entry. A modal header, display title + subtitle, a product URL
/// field with a globe icon and inline Paste chip, a hint, and a bottom dock with
/// the Next CTA.
struct URLEntryView: View {
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>
    @FocusState private var isURLFieldFocused: Bool

    // MARK: - Body

    var body: some View {
        WithPerceptionTracking {
            ZStack {
                backgroundLayer
                contentLayer
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isURLFieldFocused = true
                }
            }
        }
    }
}

// MARK: - Subviews

extension URLEntryView {
    private var backgroundLayer: some View {
        Color(.ripeBg).ignoresSafeArea()
    }

    private var contentLayer: some View {
        VStack(spacing: 0) {
            headerView
            scrollableContentView
            dockView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var headerView: some View {
        RipeModalHeader(
            title: L10n.AddTracker.navTitleAdd,
            leadingText: L10n.Common.cancel,
            onLeadingTap: { store.send(.dismiss) }
        )
    }

    private var scrollableContentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RipeSpacing.s6) {
                titleStackView
                urlFieldView
            }
            .padding(.horizontal, RipeSpacing.s5)
            .padding(.top, RipeSpacing.s2)
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var titleStackView: some View {
        VStack(alignment: .leading, spacing: RipeSpacing.s2) {
            Text(L10n.AddTracker.urlDisplayTitle)
                .customFont(.extrabold30)
                .foregroundStyle(Color(.ripeInk))
            Text(L10n.AddTracker.urlSubtitle)
                .customFont(.medium15)
                .foregroundStyle(Color(.ripeInk2))
        }
    }

    private var urlFieldView: some View {
        RipeField(label: L10n.AddTracker.urlFieldLabel, hint: L10n.AddTracker.urlHint) {
            RipeInputShell(isFocused: isURLFieldFocused) {
                urlInputRow
            }
        }
    }

    private var urlInputRow: some View {
        HStack(spacing: RipeSpacing.s2) {
            globeIconView
            urlTextField
            pasteChipView
        }
    }

    private var globeIconView: some View {
        Image(systemName: "globe")
            .iconFont(.md)
            .foregroundStyle(Color(.ripeInk3))
    }

    private var urlTextField: some View {
        TextField(L10n.AddTracker.urlPlaceholder, text: $store.urlInput.sending(\.urlInputChanged))
            .focused($isURLFieldFocused)
            .customFont(.semibold15)
            .foregroundStyle(Color(.ripeInk))
            .tint(Color(.ripeAccent))
            .keyboardType(.URL)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(.go)
            .onSubmit { store.send(.loadURL) }
    }

    private var pasteChipView: some View {
        Button(action: pasteFromClipboard) {
            Text(L10n.AddTracker.paste)
                .customFont(.semibold13)
                .foregroundStyle(Color(.ripeAccent))
                .padding(.horizontal, RipeSpacing.s3)
                .padding(.vertical, RipeSpacing.s1)
                .background(Capsule().fill(Color(.ripeAccentSoft)))
        }
        .buttonStyle(.plain)
    }

    private var dockView: some View {
        Dock {
            RipeButton(
                title: L10n.AddTracker.next,
                variant: .primary,
                size: .lg,
                trailingSystemImage: "arrow.right",
                fullWidth: true,
                cornerRadius: RipeRadius.card,
                action: { store.send(.loadURL) }
            )
        }
    }
}

// MARK: - Helpers

extension URLEntryView {
    private func pasteFromClipboard() {
        if let string = UIPasteboard.general.string {
            store.send(.urlInputChanged(string))
        }
    }
}

// MARK: - Preview

#Preview {
    URLEntryView(store: Store(initialState: AddTrackerFeature.State()) {
        AddTrackerFeature()
    })
}
