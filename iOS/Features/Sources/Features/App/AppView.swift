import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Perception.Bindable var store: StoreOf<AppFeature>

    var body: some View {
        WithPerceptionTracking {
            Group {
                switch store.authStatus {
                case .unauthenticated:
                    ZStack(alignment: .bottom) {
                        AuthView(store: store.scope(state: \.auth, action: \.auth))
                        #if DEBUG
                        Button("Dev Login") {
                            store.send(.checkAuthStatus)
                        }
                        .font(.footnote)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Color.orange.opacity(0.85))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                        #endif
                    }
                case .authenticated:
                    authenticatedView
                }
            }
            .onAppear {
                store.send(.checkAuthStatus)
            }
            .onReceive(NotificationCenter.default.publisher(for: .apnsTokenReceived)) { notification in
                guard let token = notification.userInfo?["token"] as? String else { return }
                store.send(.deviceTokenReceived(token))
            }
        }
    }

    @ViewBuilder
    private var authenticatedView: some View {
        WithPerceptionTracking {
            TrackerListView(store: Store(initialState: TrackerListFeature.State()) { TrackerListFeature() })
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            store.send(.settingsButtonTapped)
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
                .sheet(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
                    SettingsView(store: settingsStore)
                }
        }
    }
}
