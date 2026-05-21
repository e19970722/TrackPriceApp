import ComposableArchitecture
import SwiftUI

public struct TrackerDetailView: View {
    let store: StoreOf<TrackerDetailFeature>
    public init(store: StoreOf<TrackerDetailFeature>) { self.store = store }
    public var body: some View { Text("Tracker Detail") }
}
