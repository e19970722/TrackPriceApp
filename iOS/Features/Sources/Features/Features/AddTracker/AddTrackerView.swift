import ComposableArchitecture
import SwiftUI

// MARK: - AddTrackerView

public struct AddTrackerView: View {
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>

    public init(store: StoreOf<AddTrackerFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Group {
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
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { store.send(.dismiss) }
                }
            }
        }
    }

    private var navigationTitle: String {
        switch store.step {
        case .urlEntry: return "Add Tracker"
        case .webView: return "Browse"
        case .confirmation: return "Confirm Element"
        case .targetSetup: return "Set Target"
        }
    }
}

// MARK: - URLEntryView

private struct URLEntryView: View {
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter a product URL")
                    .font(.headline)
                HStack {
                    TextField("https://example.com/product", text: $store.urlInput.sending(\.urlInputChanged))
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Button("Go") {
                        store.send(.loadURL)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.urlInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Button {
                Task {
                    if let string = UIPasteboard.general.string {
                        store.send(.urlInputChanged(string))
                    }
                }
            } label: {
                Label("Paste from clipboard", systemImage: "doc.on.clipboard")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
    }
}

// MARK: - WebBrowserView

private struct WebBrowserView: View {
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            WebViewContainer(
                url: store.currentURL,
                isPickerActive: store.isPickerActive,
                onElementPicked: { info in store.send(.elementPicked(info)) },
                onNavigated: { url in store.send(.webViewNavigated(url)) },
                onLoadStateChanged: { isLoading in store.send(.pageLoadStateChanged(isLoading)) }
            )
            .ignoresSafeArea(edges: .bottom)

            if store.isLoadingPage {
                ProgressView()
                    .padding(8)
                    .background(.regularMaterial)
                    .clipShape(Circle())
                    .padding()
            }

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
}

// MARK: - ConfirmationView

private struct ConfirmationView: View {
    let info: ElementInfo
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Is this the right element?")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected text")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(info.rawText.isEmpty ? "(no text)" : info.rawText)
                        .font(.title2)
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let price = info.currentPrice {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Parsed price: \(info.currencySymbol)\(String(format: "%.2f", price))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("No price detected — you can enter it manually")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)

            VStack(spacing: 12) {
                Button {
                    store.send(.confirmationConfirmed)
                } label: {
                    Label("Looks correct", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    store.send(.confirmationRejected)
                } label: {
                    Label("Re-select", systemImage: "arrow.uturn.backward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - TargetSetupView

private struct TargetSetupView: View {
    let info: ElementInfo
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>

    var body: some View {
        Form {
            Section("Tracker Name") {
                TextField("e.g. Sony WH-1000XM5", text: $store.trackerName)
            }

            Section("Target Price") {
                HStack {
                    Text(info.currencySymbol.isEmpty ? "$" : info.currencySymbol)
                        .foregroundStyle(.secondary)
                    TextField("0.00", text: $store.targetPriceInput)
                        .keyboardType(.decimalPad)
                }
            }

            Section("Alert me when price is") {
                Picker("Direction", selection: $store.targetDirection) {
                    Text("Below target").tag(Tracker.TargetDirection.below)
                    Text("Above target").tag(Tracker.TargetDirection.above)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            if let error = store.creationError {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            Section {
                Button {
                    guard let targetPrice = Double(store.targetPriceInput),
                          let currentURL = store.currentURL else { return }
                    let request = CreateTrackerRequest(
                        url: currentURL.absoluteString,
                        name: store.trackerName.isEmpty
                            ? (currentURL.host ?? "Tracker")
                            : store.trackerName,
                        cssSelector: info.cssSelector,
                        xpath: info.xpath,
                        currencySymbol: info.currencySymbol,
                        confirmedPrice: info.currentPrice ?? targetPrice,
                        targetPrice: targetPrice,
                        targetDirection: store.targetDirection
                    )
                    store.send(.targetSetupSubmitted(request))
                } label: {
                    if store.isCreating {
                        HStack {
                            ProgressView()
                            Text("Creating…")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text("Create Tracker")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .disabled(store.isCreating || store.targetPriceInput.isEmpty)
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
