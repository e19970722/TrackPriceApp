import ComposableArchitecture
import SwiftUI

struct TrackerListView: View {
    let store: StoreOf<TrackerListFeature>
    var body: some View {
        NavigationStack {
            Text("Tracker List")
                .navigationTitle("My Trackers")
        }
        .onAppear { store.send(.onAppear) }
    }
}
