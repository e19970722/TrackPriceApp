import ComposableArchitecture
@testable import Features
import XCTest

// MARK: - DatePatternParserTests

final class DatePatternParserTests: XCTestCase {
    func testParsesDDMMMYYYY() {
        let result = DatePatternParser.findDate(in: ["BEST BEFORE 15 JUN 2025"])
        XCTAssertNotNil(result)
        guard let (date, raw) = result else { return }
        let comps = Calendar.current.dateComponents([.day, .month, .year], from: date)
        XCTAssertEqual(comps.day, 15)
        XCTAssertEqual(comps.month, 6)
        XCTAssertEqual(comps.year, 2025)
        XCTAssertTrue(raw.contains("BEST BEFORE"))
    }

    func testParsesSlashFormat() {
        let result = DatePatternParser.findDate(in: ["EXP 12/31/2026"])
        XCTAssertNotNil(result)
        guard let (date, _) = result else { return }
        let comps = Calendar.current.dateComponents([.month, .year], from: date)
        XCTAssertEqual(comps.month, 12)
        XCTAssertEqual(comps.year, 2026)
    }

    func testParsesISO8601() {
        let result = DatePatternParser.findDate(in: ["USE BY 2027-03-01"])
        XCTAssertNotNil(result)
        guard let (date, _) = result else { return }
        let comps = Calendar.current.dateComponents([.month, .year], from: date)
        XCTAssertEqual(comps.month, 3)
        XCTAssertEqual(comps.year, 2027)
    }

    func testReturnsNilForNonDateStrings() {
        let result = DatePatternParser.findDate(in: ["Hello World", "No dates here", "12345"])
        XCTAssertNil(result)
    }

    func testFindsDateInMultiLineOCR() {
        let ocr = ["Ingredients: milk, cream", "BB 01 JAN 2028", "Store below 4C"]
        let result = DatePatternParser.findDate(in: ocr)
        XCTAssertNotNil(result)
    }
}

// MARK: - ItemModelTests

final class ItemModelTests: XCTestCase {
    private var futureItem: Item!
    private var expiringItem: Item!
    private var expiredItem: Item!

    override func setUp() {
        super.setUp()
        let now = Date()
        futureItem = Item(
            name: "Milk",
            bestBeforeDate: now.addingTimeInterval(30 * 86400),
            remindDaysBefore: 3
        )
        expiringItem = Item(
            name: "Yogurt",
            bestBeforeDate: now.addingTimeInterval(2 * 86400),
            remindDaysBefore: 3
        )
        expiredItem = Item(
            name: "Cheese",
            bestBeforeDate: now.addingTimeInterval(-1 * 86400),
            remindDaysBefore: 3
        )
    }

    func testFreshnessIsFreshWhenDaysLeftGreaterThanRemind() {
        XCTAssertEqual(futureItem.freshness, .fresh)
    }

    func testFreshnessIsExpiringWhenDaysLeftWithinRemindWindow() {
        XCTAssertEqual(expiringItem.freshness, .expiring)
    }

    func testFreshnessIsExpiredWhenDaysLeftNegative() {
        XCTAssertEqual(expiredItem.freshness, .expired)
    }

    func testDaysLeftIsPositiveForFutureDate() {
        XCTAssertGreaterThan(futureItem.daysLeft, 0)
    }

    func testDaysLeftIsNegativeForPastDate() {
        XCTAssertLessThan(expiredItem.daysLeft, 0)
    }

    func testRemindOnDateIsBeforeBestBefore() {
        XCTAssertLessThan(futureItem.remindOn, futureItem.bestBeforeDate)
    }

    func testLocationLabelUsesCustomWhenSet() {
        let item = Item(
            name: "Leftovers",
            location: .custom,
            locationCustom: "Wine fridge",
            bestBeforeDate: Date().addingTimeInterval(86400)
        )
        XCTAssertEqual(item.locationLabel, "Wine fridge")
    }

    func testLocationLabelFallsBackToDisplayName() {
        let item = Item(
            name: "Eggs",
            location: .fridge,
            bestBeforeDate: Date().addingTimeInterval(86400)
        )
        XCTAssertEqual(item.locationLabel, "Fridge")
    }
}

// MARK: - AddExpiryTrackerFeatureTests

@MainActor
final class AddExpiryTrackerFeatureTests: XCTestCase {
    func testScanLabelTappedAdvancesToScanStep() async {
        let store = TestStore(initialState: AddExpiryTrackerFeature.State()) {
            AddExpiryTrackerFeature()
        }
        await store.send(.scanLabelTapped) {
            $0.step = .scanLabel
        }
    }

    func testEnterManuallyTappedAdvancesToItemDetails() async {
        let store = TestStore(initialState: AddExpiryTrackerFeature.State()) {
            AddExpiryTrackerFeature()
        }
        await store.send(.enterManuallyTapped) {
            $0.step = .itemDetails(scannedDate: nil, ocrString: nil)
        }
    }

    func testDateScannedPopulatesStateAndAdvances() async {
        let scannedDate = Date(timeIntervalSinceReferenceDate: 1_000_000)
        var initial = AddExpiryTrackerFeature.State()
        initial.step = .scanLabel
        let store = TestStore(initialState: initial) {
            AddExpiryTrackerFeature()
        }
        await store.send(.dateScanned(scannedDate, ocrString: "BB 01 JAN 2027")) {
            $0.bestBeforeDate = scannedDate
            $0.isDateFromScan = true
            $0.step = .itemDetails(scannedDate: scannedDate, ocrString: "BB 01 JAN 2027")
        }
    }

    func testScanAgainReturnsToScanStep() async {
        var initial = AddExpiryTrackerFeature.State()
        initial.step = .itemDetails(scannedDate: nil, ocrString: nil)
        let store = TestStore(initialState: initial) {
            AddExpiryTrackerFeature()
        }
        await store.send(.scanAgainTapped) {
            $0.step = .scanLabel
        }
    }

    func testContinueTappedBuildsReminderStep() async {
        let bestBefore = Date(timeIntervalSinceReferenceDate: 2_000_000)
        var initial = AddExpiryTrackerFeature.State(
            itemName: "Milk",
            quantity: "1 litre",
            location: .fridge,
            bestBeforeDate: bestBefore
        )
        initial.step = .itemDetails(scannedDate: nil, ocrString: nil)

        let store = TestStore(initialState: initial) {
            AddExpiryTrackerFeature()
        }
        // The reducer creates an Item with addedDate: Date() which varies at runtime.
        // Turn off exhaustive state checking and assert only the meaningful fields.
        store.exhaustivity = .off

        await store.send(.continueTapped)
        XCTAssertEqual(store.state.itemName, "Milk")
        if case let .reminder(draft) = store.state.step {
            XCTAssertEqual(draft.name, "Milk")
            XCTAssertEqual(draft.quantity, "1 litre")
            XCTAssertEqual(draft.location, .fridge)
            XCTAssertEqual(draft.bestBeforeDate, bestBefore)
        } else {
            XCTFail("Expected .reminder step, got \(store.state.step)")
        }
    }

    func testRemindDaysBeforeChangedUpdatesState() async {
        let store = TestStore(initialState: AddExpiryTrackerFeature.State()) {
            AddExpiryTrackerFeature()
        }
        await store.send(.remindDaysBeforeChanged(7)) {
            $0.remindDaysBefore = 7
        }
    }

    func testBestBeforeDateChangedUpdatesStateAndClearsScanFlag() async {
        let newDate = Date(timeIntervalSinceReferenceDate: 4_000_000)
        var initial = AddExpiryTrackerFeature.State(isDateFromScan: true)
        initial.step = .itemDetails(scannedDate: Date(), ocrString: "BB")

        let store = TestStore(initialState: initial) {
            AddExpiryTrackerFeature()
        }

        await store.send(.bestBeforeDateChanged(newDate)) {
            $0.bestBeforeDate = newDate
            $0.isDateFromScan = false
        }
    }

    func testSaveItemCallsAPIAndAdvancesToSaved() async {
        let bestBefore = Date(timeIntervalSinceReferenceDate: 3_000_000)
        let savedItem = Item(
            id: UUID(),
            name: "Yogurt",
            location: .fridge,
            bestBeforeDate: bestBefore
        )

        var initial = AddExpiryTrackerFeature.State(itemName: "Yogurt", bestBeforeDate: bestBefore)
        let draft = Item(name: "Yogurt", location: .fridge, bestBeforeDate: bestBefore)
        initial.step = .reminder(draft)

        let store = TestStore(initialState: initial) {
            AddExpiryTrackerFeature()
        } withDependencies: {
            $0.apiClient.createItem = { _ in savedItem }
        }

        await store.send(.saveItemTapped) {
            $0.isSaving = true
            $0.saveError = nil
        }
        await store.receive(\.itemSaved) {
            $0.isSaving = false
            $0.step = .saved(savedItem)
        }
    }

    func testSaveItemHandlesNetworkError() async {
        struct FakeError: Error, LocalizedError {
            var errorDescription: String? {
                "Network down"
            }
        }

        var initial = AddExpiryTrackerFeature.State(itemName: "Milk")
        let draft = Item(name: "Milk", location: .fridge, bestBeforeDate: Date().addingTimeInterval(86400))
        initial.step = .reminder(draft)

        let store = TestStore(initialState: initial) {
            AddExpiryTrackerFeature()
        } withDependencies: {
            $0.apiClient.createItem = { _ in throw FakeError() }
        }

        await store.send(.saveItemTapped) {
            $0.isSaving = true
        }
        await store.receive(\.saveFailed) {
            $0.isSaving = false
            $0.saveError = "Network down"
        }
    }

    func testAddAnotherResetsState() async {
        let item = Item(name: "Eggs", location: .fridge, bestBeforeDate: Date().addingTimeInterval(86400))
        var initial = AddExpiryTrackerFeature.State(itemName: "Eggs")
        initial.step = .saved(item)

        let store = TestStore(initialState: initial) {
            AddExpiryTrackerFeature()
        }
        // bestBeforeDate is set to Date() inside the reducer.
        // Use non-exhaustive mode to assert only the stable parts of the reset.
        store.exhaustivity = .off
        await store.send(.addAnotherTapped)
        XCTAssertEqual(store.state.step, .chooseMethod)
        XCTAssertEqual(store.state.itemName, "")
        XCTAssertEqual(store.state.location, .fridge)
        XCTAssertFalse(store.state.isSaving)
    }
}

// MARK: - AddItemFeatureNavigationPathTests

@MainActor
final class AddItemFeatureNavigationPathTests: XCTestCase {
    private func state(step: AddItemFeature.Step, isDateFromScan: Bool = false) -> AddItemFeature.State {
        var state = AddItemFeature.State(isDateFromScan: isDateFromScan)
        state.step = step
        return state
    }

    func testChooseMethodMapsToEmptyPath() {
        XCTAssertEqual(state(step: .chooseMethod).navigationPath, [])
    }

    func testScanLabelMapsToScanLabelPath() {
        XCTAssertEqual(state(step: .scanLabel).navigationPath, [.scanLabel])
    }

    func testItemDetailsManualEntryMapsToItemDetailsPath() {
        let path = state(step: .itemDetails(scannedDate: nil, ocrString: nil), isDateFromScan: false).navigationPath
        XCTAssertEqual(path, [.itemDetails])
    }

    func testItemDetailsFromScanMapsToScanThenItemDetailsPath() {
        let path = state(step: .itemDetails(scannedDate: Date(), ocrString: "BB"), isDateFromScan: true).navigationPath
        XCTAssertEqual(path, [.scanLabel, .itemDetails])
    }

    func testReminderManualEntryMapsToItemDetailsThenReminderPath() {
        let draft = Item(name: "Milk", bestBeforeDate: Date().addingTimeInterval(86400))
        let path = state(step: .reminder(draft), isDateFromScan: false).navigationPath
        XCTAssertEqual(path, [.itemDetails, .reminder])
    }

    func testReminderFromScanMapsToScanItemDetailsReminderPath() {
        let draft = Item(name: "Milk", bestBeforeDate: Date().addingTimeInterval(86400))
        let path = state(step: .reminder(draft), isDateFromScan: true).navigationPath
        XCTAssertEqual(path, [.scanLabel, .itemDetails, .reminder])
    }

    func testSavedManualEntryMapsToFullPath() {
        let item = Item(name: "Eggs", bestBeforeDate: Date().addingTimeInterval(86400))
        let path = state(step: .saved(item), isDateFromScan: false).navigationPath
        XCTAssertEqual(path, [.itemDetails, .reminder, .saved])
    }

    func testSavedFromScanMapsToFullPathWithScan() {
        let item = Item(name: "Eggs", bestBeforeDate: Date().addingTimeInterval(86400))
        let path = state(step: .saved(item), isDateFromScan: true).navigationPath
        XCTAssertEqual(path, [.scanLabel, .itemDetails, .reminder, .saved])
    }

    func testDraftItemAccessorReturnsReminderDraft() {
        let draft = Item(name: "Milk", bestBeforeDate: Date().addingTimeInterval(86400))
        XCTAssertEqual(state(step: .reminder(draft)).draftItem, draft)
        XCTAssertNil(state(step: .chooseMethod).draftItem)
    }

    func testSavedItemAccessorReturnsSavedItem() {
        let item = Item(name: "Eggs", bestBeforeDate: Date().addingTimeInterval(86400))
        XCTAssertEqual(state(step: .saved(item)).savedItem, item)
        XCTAssertNil(state(step: .chooseMethod).savedItem)
    }
}

// MARK: - ItemsFeatureTests

@MainActor
final class ItemsFeatureTests: XCTestCase {
    func testOnAppearFetchesItems() async {
        let items = [
            Item(name: "Milk", bestBeforeDate: Date().addingTimeInterval(7 * 86400)),
            Item(name: "Eggs", bestBeforeDate: Date().addingTimeInterval(14 * 86400)),
        ]
        let store = TestStore(initialState: ItemsFeature.State()) {
            ItemsFeature()
        } withDependencies: {
            $0.apiClient.fetchItems = { items }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
            $0.errorMessage = nil
        }
        await store.receive(\.itemsLoaded) {
            $0.isLoading = false
            $0.items = items
        }
    }

    func testOnAppearSetsErrorOnFailure() async {
        struct FakeError: Error, LocalizedError {
            var errorDescription: String? {
                "Server error"
            }
        }

        let store = TestStore(initialState: ItemsFeature.State()) {
            ItemsFeature()
        } withDependencies: {
            $0.apiClient.fetchItems = { throw FakeError() }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.loadFailed) {
            $0.isLoading = false
            $0.errorMessage = "Server error"
        }
    }

    func testAddItemButtonTappedPresentsAddFlow() async {
        let store = TestStore(initialState: ItemsFeature.State()) {
            ItemsFeature()
        }
        // AddExpiryTrackerFeature.State() captures Date() for bestBeforeDate inside the reducer.
        // Use non-exhaustive mode and assert that addItem becomes non-nil.
        store.exhaustivity = .off
        await store.send(.addItemButtonTapped)
        XCTAssertNotNil(store.state.addItem)
        XCTAssertEqual(store.state.addItem?.step, .chooseMethod)
    }

    func testItemRowTappedPresentsDetail() async {
        let item = Item(name: "Yogurt", bestBeforeDate: Date().addingTimeInterval(3 * 86400))
        var initial = ItemsFeature.State()
        initial.items = [item]
        let store = TestStore(initialState: initial) {
            ItemsFeature()
        }
        await store.send(.itemRowTapped(item)) {
            $0.selectedItem = ItemDetailFeature.State(item: item)
        }
    }
}

// MARK: - ItemDetailFeatureTests

@MainActor
final class ItemDetailFeatureTests: XCTestCase {
    func testDeleteButtonTappedCallsAPIAndDismisses() async {
        let item = Item(name: "Cheese", bestBeforeDate: Date().addingTimeInterval(-86400))

        let store = TestStore(initialState: ItemDetailFeature.State(item: item)) {
            ItemDetailFeature()
        } withDependencies: {
            $0.apiClient.deleteItem = { _ in }
            $0.dismiss = DismissEffect {}
        }

        await store.send(.deleteButtonTapped) {
            $0.isDeleting = true
        }
        await store.receive(\.deleteSucceeded) {
            $0.isDeleting = false
        }
        // Delegate action emitted before dismiss
        await store.receive(\.delegate)
    }

    func testMarkUsedButtonTappedCallsAPIAndDismisses() async {
        let item = Item(name: "Leftovers", bestBeforeDate: Date().addingTimeInterval(86400))

        let store = TestStore(initialState: ItemDetailFeature.State(item: item)) {
            ItemDetailFeature()
        } withDependencies: {
            $0.apiClient.markItemUsed = { _ in }
            $0.dismiss = DismissEffect {}
        }

        await store.send(.markUsedButtonTapped) {
            $0.isMarkingUsed = true
        }
        await store.receive(\.markUsedSucceeded) {
            $0.isMarkingUsed = false
        }
        await store.receive(\.delegate)
    }

    func testDeleteFailureClearsLoadingState() async {
        struct FakeError: Error, LocalizedError {
            var errorDescription: String? {
                "Delete failed"
            }
        }
        let item = Item(name: "Milk", bestBeforeDate: Date())

        let store = TestStore(initialState: ItemDetailFeature.State(item: item)) {
            ItemDetailFeature()
        } withDependencies: {
            $0.apiClient.deleteItem = { _ in throw FakeError() }
        }

        await store.send(.deleteButtonTapped) {
            $0.isDeleting = true
        }
        await store.receive(\.operationFailed) {
            $0.isDeleting = false
        }
    }
}
