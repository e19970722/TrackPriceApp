import ComposableArchitecture
@testable import Features
import Foundation
import Testing

@MainActor
@Suite("AddTrackerFeature")
struct AddTrackerFeatureTests {
    // MARK: - Fixtures

    private func priceElement(price: Double, symbol: String = "$") -> ElementInfo {
        ElementInfo(
            interactions: [
                InteractionStep(
                    type: "click",
                    locator: ".price",
                    role: "price",
                    rawText: "\(symbol)\(price)",
                    currentPrice: price,
                    currencySymbol: symbol
                ),
            ],
            pageTitle: "Sony WH-1000XM5"
        )
    }

    private func sampleTracker() -> Tracker {
        Tracker(
            id: UUID(0),
            name: "Sony WH-1000XM5",
            url: "https://store.com/sony",
            currencySymbol: "$",
            targetPrice: 99,
            targetDirection: .below,
            status: .active,
            itemName: nil,
            itemImageUrl: nil,
            lastPrice: 129,
            lastCheckedAt: nil,
            checkInterval: 86400,
            nextCheckedAt: nil,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    // MARK: - Step transitions

    @Test("URL entry advances to the web view")
    func loadURLAdvancesToWebView() async {
        let store = TestStore(initialState: AddTrackerFeature.State()) {
            AddTrackerFeature()
        }
        await store.send(.urlInputChanged("store.com/product")) {
            $0.urlInput = "store.com/product"
        }
        await store.send(.loadURL) {
            $0.currentURL = URL(string: "https://store.com/product")
            $0.step = .webView
        }
    }

    @Test("Picking arms selection then routes to the confirm step")
    func pickElementThenConfirm() async {
        let info = priceElement(price: 129)
        let store = TestStore(initialState: webViewState()) {
            AddTrackerFeature()
        }
        await store.send(.pickElementTapped) { $0.isSelecting = true }
        await store.send(.elementPicked(info)) {
            $0.isSelecting = false
            $0.step = .confirmation(info)
        }
    }

    @Test("Cancelling selection disarms picking")
    func cancelSelection() async {
        var state = webViewState()
        state.isSelecting = true
        let store = TestStore(initialState: state) { AddTrackerFeature() }
        await store.send(.selectionCancelled) { $0.isSelecting = false }
    }

    @Test("Confirming the element prefills target setup")
    func confirmPrefillsTargetSetup() async {
        let info = priceElement(price: 129)
        let store = TestStore(initialState: confirmationState(info)) {
            AddTrackerFeature()
        }
        await store.send(.confirmationConfirmed) {
            $0.trackerName = "Sony WH-1000XM5"
            $0.targetPriceInput = "129.00"
            $0.step = .targetSetup(info)
        }
    }

    @Test("Rejecting the element returns to the web view")
    func rejectReturnsToWebView() async {
        let info = priceElement(price: 129)
        let store = TestStore(initialState: confirmationState(info)) {
            AddTrackerFeature()
        }
        await store.send(.confirmationRejected) { $0.step = .webView }
    }

    // MARK: - Save success

    @Test("Saving a non-met target creates the tracker and dismisses")
    func saveCreatesTracker() async {
        let info = priceElement(price: 129)
        var state = targetSetupState(info)
        state.targetPriceInput = "99.00"
        state.targetDirection = .below

        let created = sampleTracker()
        let store = TestStore(initialState: state) {
            AddTrackerFeature()
        } withDependencies: {
            $0.apiClient.createTracker = { _ in created }
        }
        let isDismissed = LockIsolated(false)
        store.dependencies.dismiss = DismissEffect { isDismissed.setValue(true) }

        await store.send(.saveTapped) { $0.isCreating = true }
        await store.receive(\.trackerCreated) { $0.isCreating = false }
        #expect(isDismissed.value)
    }

    // MARK: - Already-meets-target warning

    @Test("Target already met shows the warning instead of saving")
    func alreadyMetShowsWarning() async {
        let info = priceElement(price: 79)
        var state = targetSetupState(info)
        state.targetPriceInput = "99.00"
        state.targetDirection = .below

        let store = TestStore(initialState: state) { AddTrackerFeature() }
        await store.send(.saveTapped) { $0.showsAlreadyMetWarning = true }
    }

    @Test("Cancelling the warning dismisses it without saving")
    func cancelWarning() async {
        let info = priceElement(price: 79)
        var state = targetSetupState(info)
        state.targetPriceInput = "99.00"
        state.showsAlreadyMetWarning = true

        let store = TestStore(initialState: state) { AddTrackerFeature() }
        await store.send(.alreadyMetWarningCancelled) { $0.showsAlreadyMetWarning = false }
    }

    @Test("Confirming the warning proceeds to create the tracker")
    func confirmWarningSaves() async {
        let info = priceElement(price: 79)
        var state = targetSetupState(info)
        state.targetPriceInput = "99.00"
        state.showsAlreadyMetWarning = true

        let created = sampleTracker()
        let store = TestStore(initialState: state) {
            AddTrackerFeature()
        } withDependencies: {
            $0.apiClient.createTracker = { _ in created }
        }
        store.dependencies.dismiss = DismissEffect {}

        await store.send(.alreadyMetWarningConfirmed) {
            $0.showsAlreadyMetWarning = false
            $0.isCreating = true
        }
        await store.receive(\.trackerCreated) { $0.isCreating = false }
    }

    @Test("targetAlreadyMet reflects direction")
    func targetAlreadyMetComputed() {
        var below = targetSetupState(priceElement(price: 79))
        below.targetPriceInput = "99"
        below.targetDirection = .below
        #expect(below.targetAlreadyMet)

        var above = targetSetupState(priceElement(price: 120))
        above.targetPriceInput = "99"
        above.targetDirection = .above
        #expect(above.targetAlreadyMet)

        var notMet = targetSetupState(priceElement(price: 120))
        notMet.targetPriceInput = "99"
        notMet.targetDirection = .below
        #expect(!notMet.targetAlreadyMet)
    }

    // MARK: - State helpers

    private func webViewState() -> AddTrackerFeature.State {
        var state = AddTrackerFeature.State()
        state.step = .webView
        state.currentURL = URL(string: "https://store.com/product")
        return state
    }

    private func confirmationState(_ info: ElementInfo) -> AddTrackerFeature.State {
        var state = webViewState()
        state.step = .confirmation(info)
        return state
    }

    private func targetSetupState(_ info: ElementInfo) -> AddTrackerFeature.State {
        var state = AddTrackerFeature.State()
        state.currentURL = URL(string: "https://store.com/sony")
        state.step = .targetSetup(info)
        state.trackerName = "Sony WH-1000XM5"
        return state
    }
}
