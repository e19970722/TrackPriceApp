import ComposableArchitecture
import SwiftUI

public struct SettingsView: View {
    let store: StoreOf<SettingsFeature>
    public init(store: StoreOf<SettingsFeature>) { self.store = store }
    public var body: some View {
        Button("Sign Out") { store.send(.signOutTapped) }
    }
}
