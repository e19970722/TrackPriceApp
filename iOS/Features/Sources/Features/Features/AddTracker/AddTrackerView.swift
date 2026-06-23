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
            NavigationStack(path: pathBinding) {
                URLEntryView(store: store)
                    .navigationDestination(for: AddTrackerFeature.Route.self, destination: destinationView)
            }
        }
    }
}

// MARK: - Subviews

extension AddTrackerView {
    private func destinationView(for route: AddTrackerFeature.Route) -> some View {
        WithPerceptionTracking {
            switch route {
            case .webView:
                WebBrowserView(store: store)
            case .targetSetup:
                SetTargetView(store: store)
            }
        }
    }
}

// MARK: - Helpers

extension AddTrackerView {
    /// Drives the `NavigationStack` from `store.step`. Pushes are state-driven, so
    /// the setter only reacts when the user pops (path shrinks) via the system
    /// back button or interactive swipe, mapping the new depth to the matching
    /// reducer action to keep state in sync.
    private var pathBinding: Binding<[AddTrackerFeature.Route]> {
        Binding(
            get: { store.navigationPath },
            set: { newPath in
                let oldDepth = store.navigationPath.count
                guard newPath.count < oldDepth else { return }
                switch newPath.count {
                case 1:
                    store.send(.confirmationRejected)
                case 0:
                    store.send(.backToURLEntry)
                default:
                    break
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    AddTrackerView(store: Store(initialState: AddTrackerFeature.State()) {
        AddTrackerFeature()
    })
}
