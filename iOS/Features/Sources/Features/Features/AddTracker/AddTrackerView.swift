import ComposableArchitecture
import SwiftUI

// MARK: - AddTrackerView

public struct AddTrackerView: View {
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>

    public init(store: StoreOf<AddTrackerFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                stepContentView
                    .navigationTitle(navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            cancelButton
                        }
                    }
            }
        }
    }
}

// MARK: - Subviews

extension AddTrackerView {
    @ViewBuilder
    private var stepContentView: some View {
        switch store.step {
        case .urlEntry:
            URLEntryView(store: store)
        case .webView:
            WebBrowserView(store: store)
        case let .confirmation(info):
            ConfirmationView(info: info, store: store)
        case let .targetSetup(info):
            TargetSetupView(info: info, store: store)
        }
    }

    private var cancelButton: some View {
        Button(L10n.Common.cancel) { store.send(.dismiss) }
    }
}

// MARK: - Helpers

extension AddTrackerView {
    private var navigationTitle: String {
        switch store.step {
        case .urlEntry: L10n.AddTracker.navTitleAdd
        case .webView: L10n.AddTracker.navTitleBrowse
        case .confirmation: L10n.AddTracker.navTitleConfirm
        case .targetSetup: L10n.AddTracker.navTitleSetTarget
        }
    }
}

// MARK: - URLEntryView

private struct URLEntryView: View {
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>

    // MARK: - Body

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 24) {
                urlInputSection
                pasteFromClipboardButton
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Subviews

extension URLEntryView {
    private var urlInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.AddTracker.urlPrompt)
                .customFont(.bold17)
            urlInputRow
        }
    }

    private var urlInputRow: some View {
        HStack {
            TextField(L10n.AddTracker.urlPlaceholder, text: $store.urlInput.sending(\.urlInputChanged))
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            goButton
        }
    }

    private var goButton: some View {
        Button(L10n.AddTracker.goButton) {
            store.send(.loadURL)
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.urlInput.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private var pasteFromClipboardButton: some View {
        Button {
            Task {
                if let string = UIPasteboard.general.string {
                    store.send(.urlInputChanged(string))
                }
            }
        } label: {
            Label(L10n.AddTracker.pasteFromClipboard, systemImage: "doc.on.clipboard")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

// MARK: - WebBrowserView

private struct WebBrowserView: View {
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>

    // MARK: - Body

    var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .bottomTrailing) {
                webViewLayer
                if store.isLoadingPage {
                    loadingIndicator
                }
                pickerToggleButton
            }
        }
    }
}

// MARK: - Subviews

extension WebBrowserView {
    private var webViewLayer: some View {
        WebViewContainer(
            url: store.currentURL,
            isPickerActive: store.isPickerActive,
            onElementPicked: { info in store.send(.elementPicked(info)) },
            onNavigated: { url in store.send(.webViewNavigated(url)) },
            onLoadStateChanged: { isLoading in store.send(.pageLoadStateChanged(isLoading)) }
        )
        .ignoresSafeArea(edges: .bottom)
    }

    private var loadingIndicator: some View {
        ProgressView()
            .padding(8)
            .background(.regularMaterial)
            .clipShape(Circle())
            .padding()
    }

    private var pickerToggleButton: some View {
        Button {
            store.send(.pickerToggled)
        } label: {
            Label(
                store.isPickerActive ? "Cancel" : "Pick Element",
                systemImage: store.isPickerActive ? "xmark.circle.fill" : "cursorarrow.click"
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .tint(store.isPickerActive ? .red : .orange)
        .padding()
    }
}

// MARK: - ConfirmationView

private struct ConfirmationView: View {
    let info: ElementInfo
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>

    // MARK: - Body

    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 24) {
                selectedElementCard
                confirmationButtonStack
                Spacer()
            }
            .padding()
        }
    }
}

// MARK: - Subviews

extension ConfirmationView {
    private var selectedElementCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.AddTracker.confirmTitle)
                .customFont(.bold17)
            selectedTextSection
            parsedPriceRow
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
    }

    private var selectedTextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.AddTracker.selectedText)
                .customFont(.medium12)
                .foregroundStyle(.secondary)
            Text(info.rawText.map { $0.isEmpty ? "(no text)" : $0 } ?? "(no text)")
                .customFont(.extrabold22)
                .bold()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var parsedPriceRow: some View {
        Group {
            if let price = info.currentPrice {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(L10n.AddTracker.parsedPrice("\(info.currencySymbol)\(String(format: "%.2f", price))"))
                        .customFont(.medium15)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(L10n.AddTracker.noPriceDetected)
                        .customFont(.medium15)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var confirmationButtonStack: some View {
        VStack(spacing: 12) {
            confirmButton
            reSelectButton
        }
    }

    private var confirmButton: some View {
        Button {
            store.send(.confirmationConfirmed)
        } label: {
            Label(L10n.AddTracker.looksCorrect, systemImage: "checkmark")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
    }

    private var reSelectButton: some View {
        Button {
            store.send(.confirmationRejected)
        } label: {
            Label(L10n.AddTracker.reSelect, systemImage: "arrow.uturn.backward")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

// MARK: - TargetSetupView

private struct TargetSetupView: View {
    let info: ElementInfo
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>

    // MARK: - Body

    var body: some View {
        WithPerceptionTracking {
            Form {
                trackerNameSection
                targetPriceSection
                directionSection
                if let error = store.creationError {
                    errorSection(message: error)
                }
                submitSection
            }
        }
    }
}

// MARK: - Subviews

extension TargetSetupView {
    private var trackerNameSection: some View {
        Section("Tracker Name") {
            TextField("e.g. Sony WH-1000XM5", text: $store.trackerName)
        }
    }

    private var targetPriceSection: some View {
        Section("Target Price") {
            HStack {
                Text(info.currencySymbol.isEmpty ? "$" : info.currencySymbol)
                    .foregroundStyle(.secondary)
                TextField("0.00", text: $store.targetPriceInput)
                    .keyboardType(.decimalPad)
            }
        }
    }

    private var directionSection: some View {
        Section("Alert me when price is") {
            Picker("Direction", selection: $store.targetDirection) {
                Text(L10n.AddTracker.belowTarget).tag(TargetDirection.below)
                Text(L10n.AddTracker.aboveTarget).tag(TargetDirection.above)
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }

    private func errorSection(message: String) -> some View {
        Section {
            Text(message)
                .foregroundStyle(.red)
                .customFont(.medium12)
        }
    }

    private var submitSection: some View {
        Section {
            Button {
                guard let targetPrice = Double(store.targetPriceInput),
                      let currentURL = store.currentURL else { return }
                let request = CreateTrackerRequest(
                    url: currentURL.absoluteString,
                    name: store.trackerName.isEmpty
                        ? (info.pageTitle ?? currentURL.host ?? "Tracker")
                        : store.trackerName,
                    interactions: info.interactions,
                    currencySymbol: info.currencySymbol,
                    confirmedPrice: info.currentPrice ?? targetPrice,
                    targetPrice: targetPrice,
                    targetDirection: store.targetDirection,
                    itemImageUrl: info.itemImageUrl
                )
                store.send(.targetSetupSubmitted(request))
            } label: {
                createTrackerButtonLabel
            }
            .disabled(store.isCreating || store.targetPriceInput.isEmpty)
        }
    }

    private var createTrackerButtonLabel: some View {
        Group {
            if store.isCreating {
                HStack {
                    ProgressView()
                    Text(L10n.AddTracker.creating)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Text(L10n.AddTracker.createTracker)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddTrackerView(store: Store(initialState: AddTrackerFeature.State()) {
        AddTrackerFeature()
    })
}
