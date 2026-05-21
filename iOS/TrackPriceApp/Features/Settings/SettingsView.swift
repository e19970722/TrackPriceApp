import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>
    var body: some View {
        Button("Sign Out") { store.send(.signOutTapped) }
    }
}
