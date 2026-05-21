import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        switch store.authStatus {
        case .unauthenticated:
            AuthView(store: Store(initialState: AuthFeature.State()) { AuthFeature() })
        case .authenticated:
            TrackerListView(store: Store(initialState: TrackerListFeature.State()) { TrackerListFeature() })
        }
    }
}
