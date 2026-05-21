import ComposableArchitecture
import SwiftUI

public struct TrackerListView: View {
    let store: StoreOf<TrackerListFeature>
    public init(store: StoreOf<TrackerListFeature>) { self.store = store }
    public var body: some View {
        NavigationStack {
            Text("Tracker List")
                .navigationTitle("My Trackers")
        }
        .onAppear { store.send(.onAppear) }
    }
}
