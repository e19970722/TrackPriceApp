import ComposableArchitecture
import SwiftUI

struct AuthView: View {
    let store: StoreOf<AuthFeature>
    var body: some View {
        VStack(spacing: 16) {
            Text("TrackPrice").font(.largeTitle.bold())
            Button("Sign in with Apple") { store.send(.signInWithAppleTapped) }
            Button("Sign in with Google") { store.send(.signInWithGoogleTapped) }
        }
    }
}
