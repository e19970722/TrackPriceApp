import ComposableArchitecture
import SwiftUI

/// Routes between the steps of the add-item flow based on `AddExpiryTrackerFeature.State.step`.
public struct AddExpiryTrackerView: View {
    @Perception.Bindable var store: StoreOf<AddExpiryTrackerFeature>

    public init(store: StoreOf<AddExpiryTrackerFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            NavigationStack(path: pathBinding) {
                ChooseMethodView(store: store)
                    .navigationDestination(for: AddExpiryTrackerFeature.Route.self, destination: destinationView)
            }
        }
    }
}

// MARK: - Subviews

extension AddExpiryTrackerView {
    private func destinationView(for route: AddExpiryTrackerFeature.Route) -> some View {
        WithPerceptionTracking {
            switch route {
            case .scanLabel:
                ScanLabelView(store: store)

            case .itemDetails:
                ItemDetailsView(store: store)

            case .reminder:
                reminderDestination

            case .saved:
                savedDestination
            }
        }
    }

    @ViewBuilder
    private var reminderDestination: some View {
        if let draft = store.draftItem {
            ReminderView(store: store, draftItem: draft)
        }
    }

    @ViewBuilder
    private var savedDestination: some View {
        if let item = store.savedItem {
            SavedView(store: store, savedItem: item)
                .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Helpers

extension AddExpiryTrackerView {
    /// Drives the `NavigationStack` from `store.step`. Pushes are state-driven, so
    /// the setter only reacts when the user pops (path shrinks) via the system back
    /// button or interactive swipe: a single-level pop maps to `.backTapped` (which
    /// moves the step one level back), and a pop straight to the root dismisses the
    /// flow.
    private var pathBinding: Binding<[AddExpiryTrackerFeature.Route]> {
        Binding(
            get: { store.navigationPath },
            set: { newPath in
                let oldDepth = store.navigationPath.count
                guard newPath.count < oldDepth else { return }
                if newPath.isEmpty {
                    store.send(.dismiss)
                } else {
                    store.send(.backTapped)
                }
            }
        )
    }
}

// MARK: - Preview

#Preview {
    AddExpiryTrackerView(store: Store(initialState: AddExpiryTrackerFeature.State()) { AddExpiryTrackerFeature() })
}
