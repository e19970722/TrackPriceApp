import ComposableArchitecture
import SwiftUI

public struct SettingsView: View {
    @Perception.Bindable var store: StoreOf<SettingsFeature>

    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            NavigationView {
                List {
                    // Account section
                    Section("Account") {
                        if !store.userEmail.isEmpty {
                            HStack {
                                Text("Email")
                                Spacer()
                                Text(store.userEmail)
                                    .foregroundColor(.secondary)
                            }
                        }
                        if !store.authProvider.isEmpty {
                            HStack {
                                Text("Signed in with")
                                Spacer()
                                Text(store.authProvider.capitalized)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Notifications section
                    Section("Notifications") {
                        Button("Notification Settings") {
                            store.send(.openNotificationSettings)
                        }
                    }

                    // Sign out
                    Section {
                        Button(role: .destructive) {
                            store.send(.signOutTapped)
                        } label: {
                            Text("Sign Out")
                        }
                    }

                    // App info
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(store.appVersion)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("Settings")
            }
            .confirmationDialog(
                "Sign out of TrackPrice?",
                isPresented: Binding(
                    get: { store.isSignOutConfirmationPresented },
                    set: { _ in store.send(.signOutCancelled) }
                ),
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    store.send(.signOutConfirmed)
                }
                Button("Cancel", role: .cancel) {
                    store.send(.signOutCancelled)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(store: Store(initialState: SettingsFeature.State()) {
        SettingsFeature()
    })
}
