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
                    TrackerListView(store: Store(initialState: TrackerListFeature.State()) { TrackerListFeature() })
                }
            }
            .onAppear {
                store.send(.checkAuthStatus)
            }
        }
    }
}
