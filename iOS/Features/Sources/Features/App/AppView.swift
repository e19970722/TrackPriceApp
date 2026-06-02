import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Perception.Bindable var store: StoreOf<AppFeature>

    // MARK: - Body

    var body: some View {
        WithPerceptionTracking {
            Group {
                switch store.authStatus {
                case .unauthenticated:
                    unauthenticatedView
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
}

// MARK: - Subviews

extension AppView {

    private var unauthenticatedView: some View {
        ZStack(alignment: .bottom) {
            AuthView(store: store.scope(state: \.auth, action: \.auth))
            #if DEBUG
            devLoginButton
            #endif
        }
    }

    #if DEBUG
    private var devLoginButton: some View {
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
    }
    #endif

    @ViewBuilder
    private var authenticatedView: some View {
        WithPerceptionTracking {
            TabView {
                HomeView(store: Store(initialState: HomeFeature.State()) { HomeFeature() })
                    .toolbarBackground(Color(.ripeSurface), for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
                    .tabItem { Label("Home", systemImage: "house") }
                TrackerListView(store: Store(initialState: TrackerListFeature.State()) { TrackerListFeature() })
                    .toolbarBackground(Color(.ripeSurface), for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
                    .tabItem { Label("Tracks", systemImage: "tag") }
                ItemsView(store: Store(initialState: ItemsFeature.State()) { ItemsFeature() })
                    .toolbarBackground(Color(.ripeSurface), for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
                    .tabItem { Label("Items", systemImage: "refrigerator") }
                SettingsView(store: store.scope(state: \.settings, action: \.settings))
                    .toolbarBackground(Color(.ripeSurface), for: .tabBar)
                    .toolbarBackground(.visible, for: .tabBar)
                    .tabItem { Label("Profile", systemImage: "person") }
            }
            .tint(Color(.ripeAccent))
        }
    }
}
