import ComposableArchitecture
import SwiftUI

/// Routes between the steps of the add-item flow based on `AddItemFeature.State.step`.
public struct AddItemFlowView: View {
    @Perception.Bindable var store: StoreOf<AddItemFeature>

    public init(store: StoreOf<AddItemFeature>) {
        self.store = store
    }

    // MARK: - Body

    public var body: some View {
        WithPerceptionTracking {
            stepContent
        }
    }
}

// MARK: - Subviews

extension AddItemFlowView {

    @ViewBuilder
    private var stepContent: some View {
        switch store.step {
        case .chooseMethod:
            ChooseMethodView(store: store)

        case .scanLabel:
            NavigationStack {
                ScanLabelView(store: store)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { store.send(.dismiss) }
                        }
                    }
            }

        case let .itemDetails(_, _):
            NavigationStack {
                ItemDetailsView(store: store)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { store.send(.dismiss) }
                        }
                    }
            }

        case let .reminder(draft):
            NavigationStack {
                ReminderView(store: store, draftItem: draft)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { store.send(.dismiss) }
                        }
                    }
            }

        case let .saved(item):
            NavigationStack {
                SavedView(store: store, savedItem: item)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddItemFlowView(store: Store(initialState: AddItemFeature.State()) { AddItemFeature() })
}
