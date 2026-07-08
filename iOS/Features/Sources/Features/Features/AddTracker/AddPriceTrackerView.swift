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
            NavigationStack(path: $store.navigationPath.sending(\.navigationPathChanged)) {
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

// MARK: - Preview

#Preview {
    AddPriceTrackerView(store: Store(initialState: AddPriceTrackerFeature.State()) {
        AddPriceTrackerFeature()
    })
}
