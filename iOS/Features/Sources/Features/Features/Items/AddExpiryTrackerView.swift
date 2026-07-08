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
            NavigationStack(path: $store.navigationPath.sending(\.navigationPathChanged)) {
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

// MARK: - Preview

#Preview {
    AddExpiryTrackerView(store: Store(initialState: AddExpiryTrackerFeature.State()) { AddExpiryTrackerFeature() })
}
