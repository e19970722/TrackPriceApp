import ComposableArchitecture
import SwiftUI

// MARK: - AddPriceTrackerView

public struct AddPriceTrackerView: View {
    @Perception.Bindable var store: StoreOf<AddPriceTrackerFeature>

    public init(store: StoreOf<AddPriceTrackerFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: pathBinding) {
                URLEntryView(store: store)
                    .navigationDestination(for: AddPriceTrackerFeature.Route.self, destination: destinationView)
            }
        }
    }
}

// MARK: - Subviews

extension AddPriceTrackerView {
    private func destinationView(for route: AddPriceTrackerFeature.Route) -> some View {
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

extension AddPriceTrackerView {
    /// Drives the `NavigationStack` from `store.step`. Pushes are state-driven, so
    /// the setter only reacts when the user pops (path shrinks) via the system
    /// back button or interactive swipe, mapping the new depth to the matching
    /// reducer action to keep state in sync.
    private var pathBinding: Binding<[AddPriceTrackerFeature.Route]> {
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
    AddPriceTrackerView(store: Store(initialState: AddPriceTrackerFeature.State()) {
        AddPriceTrackerFeature()
    })
}
