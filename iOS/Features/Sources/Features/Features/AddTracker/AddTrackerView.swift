import ComposableArchitecture
import SwiftUI

public struct AddTrackerView: View {
    let store: StoreOf<AddTrackerFeature>
    public init(store: StoreOf<AddTrackerFeature>) { self.store = store }
    public var body: some View { Text("Add Tracker") }
}
