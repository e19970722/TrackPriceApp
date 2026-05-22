import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>
    @State private var showDevConsole = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            switch store.authStatus {
            case .unauthenticated:
                AuthView(store: Store(initialState: AuthFeature.State()) { AuthFeature() })
            case .authenticated:
                TrackerListView(store: Store(initialState: TrackerListFeature.State()) { TrackerListFeature() })
            }

            #if DEBUG
            Button {
                showDevConsole = true
            } label: {
                Image(systemName: "hammer.fill")
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .padding(.top, 56)
            .padding(.trailing, 16)
            .sheet(isPresented: $showDevConsole) {
                DevConsoleView(
                    store: Store(initialState: DevConsoleFeature.State()) { DevConsoleFeature() }
                )
            }
            #endif
        }
    }
}
