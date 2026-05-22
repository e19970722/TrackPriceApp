import ComposableArchitecture
import SwiftUI

public struct DevConsoleView: View {
    @Perception.Bindable var store: StoreOf<DevConsoleFeature>

    public init(store: StoreOf<DevConsoleFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Server") {
                    TextField("Base URL", text: $store.baseURL)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button("POST /dev/token") {
                        store.send(.fetchDevToken)
                    }
                }

                Section("JWT Token") {
                    TextField("Paste or fetch token above", text: $store.token, axis: .vertical)
                        .lineLimit(3)
                        .font(.caption.monospaced())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Request") {
                    HStack {
                        Picker("Method", selection: $store.customMethod) {
                            ForEach(["GET", "POST", "PATCH", "DELETE"], id: \.self) { Text($0) }
                        }
                        .pickerStyle(.segmented)
                    }
                    TextField("Path  e.g. /health", text: $store.customPath)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Body JSON (optional)", text: $store.customBody, axis: .vertical)
                        .lineLimit(4)
                        .font(.caption.monospaced())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button {
                        store.send(.runRequest)
                    } label: {
                        Label("Send", systemImage: "paperplane.fill")
                    }
                    .disabled(store.isLoading)
                }

                Section("Response") {
                    if store.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if store.response.isEmpty {
                        Text("—").foregroundStyle(.secondary)
                    } else {
                        ScrollView {
                            Text(store.response)
                                .font(.caption.monospaced())
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 300)
                        Button("Copy") {
                            UIPasteboard.general.string = store.response
                        }
                        .font(.caption)
                    }
                }
            }
            .navigationTitle("Dev Console")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
