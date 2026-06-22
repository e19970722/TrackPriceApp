import ComposableArchitecture
import SwiftUI

// MARK: - AddTrackerView

public struct AddTrackerView: View {
    @Perception.Bindable var store: StoreOf<AddTrackerFeature>

    public init(store: StoreOf<AddTrackerFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                stepContentView
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}

// MARK: - Subviews

extension AddTrackerView {
    @ViewBuilder
    private var stepContentView: some View {
        switch store.step {
        case .urlEntry:
            URLEntryView(store: store)
        case .webView, .confirmation:
            WebBrowserView(store: store)
        case .targetSetup:
            SetTargetView(store: store)
        }
    }
}

// MARK: - Preview

#Preview {
    AddTrackerView(store: Store(initialState: AddTrackerFeature.State()) {
        AddTrackerFeature()
    })
}
