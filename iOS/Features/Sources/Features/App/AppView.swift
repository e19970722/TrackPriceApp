import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Perception.Bindable var store: StoreOf<AppFeature>

    var body: some View {
        WithPerceptionTracking {
            Group {
                switch store.authStatus {
                case .unauthenticated:
                    AuthView(store: store.scope(state: \.auth, action: \.auth))
                case .authenticated:
                    authenticatedView
                }
            }
            .onAppear {
                store.send(.checkAuthStatus)
            }
        }
    }

    @ViewBuilder
    private var authenticatedView: some View {
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
            .sheet(
                isPresented: Binding(
                    get: { store.isSettingsPresented },
                    set: { isPresented in
                        if !isPresented { store.send(.settingsDismissed) }
                    }
                )
            ) {
                SettingsView(store: store.scope(state: \.settings, action: \.settings))
            }
    }
}
