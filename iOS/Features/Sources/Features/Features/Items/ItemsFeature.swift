import ComposableArchitecture
import Foundation

// MARK: - ItemDetailFeature

@Reducer
public struct ItemDetailFeature {
    @ObservableState
    public struct State: Equatable, Identifiable {
        public var id: UUID {
            item.id
        }

        public var item: Item
        public var isDeleting: Bool = false
        public var isMarkingUsed: Bool = false
        public var isEditingReminder: Bool = false
        public var isEditing: Bool = false
        public var isSavingEdit: Bool = false

        public init(item: Item) {
            self.item = item
        }
    }

    public enum Action {
        case deleteButtonTapped
        case markUsedButtonTapped
        case editReminderTapped
        case deleteConfirmed
        case markUsedConfirmed
        case deleteSucceeded
        case markUsedSucceeded
        case operationFailed(String)
        case reminderUpdated(Item)
        case reminderEditDismissed
        case delegate(Delegate)
        case dismissTapped
        case editButtonTapped
        case cancelEditTapped
        case saveEditTapped(ItemIn)
        case editSaved(Item)
    }

    public enum Delegate {
        case itemDeleted
        case itemMarkedUsed
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .deleteButtonTapped:
                state.isDeleting = true
                return .run { [id = state.item.id] send in
                    do {
                        try await apiClient.deleteItem(id)
                        await send(.deleteSucceeded)
                    } catch {
                        await send(.operationFailed(error.localizedDescription))
                    }
                }

            case .markUsedButtonTapped:
                state.isMarkingUsed = true
                return .run { [id = state.item.id] send in
                    do {
                        try await apiClient.markItemUsed(id)
                        await send(.markUsedSucceeded)
                    } catch {
                        await send(.operationFailed(error.localizedDescription))
                    }
                }

            case .editReminderTapped:
                state.isEditingReminder = true
                return .none

            case .deleteConfirmed:
                return .none

            case .markUsedConfirmed:
                return .none

            case .deleteSucceeded:
                state.isDeleting = false
                return .merge(
                    .send(.delegate(.itemDeleted)),
                    .run { _ in await dismiss() }
                )

            case .markUsedSucceeded:
                state.isMarkingUsed = false
                return .merge(
                    .send(.delegate(.itemMarkedUsed)),
                    .run { _ in await dismiss() }
                )

            case .operationFailed:
                state.isDeleting = false
                state.isMarkingUsed = false
                state.isSavingEdit = false
                return .none

            case .dismissTapped:
                return .run { _ in await dismiss() }

            case .editButtonTapped:
                state.isEditing = true
                return .none

            case .cancelEditTapped:
                state.isEditing = false
                return .none

            case let .saveEditTapped(input):
                state.isSavingEdit = true
                return .run { [id = state.item.id] send in
                    do {
                        let updated = try await apiClient.updateItem(id, input)
                        await send(.editSaved(updated))
                    } catch {
                        await send(.operationFailed(error.localizedDescription))
                    }
                }

            case let .editSaved(updated):
                state.item = updated
                state.isEditing = false
                state.isSavingEdit = false
                return .none

            case let .reminderUpdated(updatedItem):
                state.item = updatedItem
                state.isEditingReminder = false
                return .none

            case .reminderEditDismissed:
                state.isEditingReminder = false
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

// MARK: - AddItemFeature

@Reducer
public struct AddItemFeature {
    public enum Step: Equatable {
        case chooseMethod
        case scanLabel
        case itemDetails(scannedDate: Date?, ocrString: String?)
        case reminder(Item)
        case saved(Item)
    }

    /// One pushed screen in the flow's `NavigationStack`. `chooseMethod` is the
    /// root and therefore has no route.
    public enum Route: Hashable {
        case scanLabel
        case itemDetails
        case reminder
        case saved
    }

    @ObservableState
    public struct State: Equatable {
        public var step: Step = .chooseMethod
        public var isSaving: Bool = false
        public var saveError: String?

        // itemDetails form fields
        public var itemName: String = ""
        public var quantity: String = "1"
        public var location: ItemLocation = .fridge
        public var locationCustom: String = ""
        public var bestBeforeDate: Date = .init()
        public var isDateFromScan: Bool = false
        public var isDatePickerPresented: Bool = false

        // reminder form fields
        public var remindDaysBefore: Int = 3
        public var remindOnDay: Bool = false

        public init() {}

        public init(
            itemName: String = "",
            quantity: String = "1",
            location: ItemLocation = .fridge,
            locationCustom: String = "",
            bestBeforeDate: Date = Date(),
            isDateFromScan: Bool = false,
            remindDaysBefore: Int = 3,
            remindOnDay: Bool = false
        ) {
            self.itemName = itemName
            self.quantity = quantity
            self.location = location
            self.locationCustom = locationCustom
            self.bestBeforeDate = bestBeforeDate
            self.isDateFromScan = isDateFromScan
            self.remindDaysBefore = remindDaysBefore
            self.remindOnDay = remindOnDay
        }

        /// Drives the flow's `NavigationStack`, derived purely from `step` (and
        /// `isDateFromScan` for the scan branch). `chooseMethod` is the root, so it
        /// maps to an empty path.
        public var navigationPath: [Route] {
            // The item-details screen sits one level deeper when reached via scan.
            let itemDetailsPath: [Route] = isDateFromScan ? [.scanLabel, .itemDetails] : [.itemDetails]
            switch step {
            case .chooseMethod:
                return []
            case .scanLabel:
                return [.scanLabel]
            case .itemDetails:
                return itemDetailsPath
            case .reminder:
                return itemDetailsPath + [.reminder]
            case .saved:
                return itemDetailsPath + [.reminder, .saved]
            }
        }

        /// The draft `Item` carried by the `.reminder` step, for the reminder destination.
        public var draftItem: Item? {
            guard case let .reminder(draft) = step else { return nil }
            return draft
        }

        /// The persisted `Item` carried by the `.saved` step, for the saved destination.
        public var savedItem: Item? {
            guard case let .saved(item) = step else { return nil }
            return item
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case scanLabelTapped
        case enterManuallyTapped
        case dateScanned(Date, ocrString: String)
        case scanAgainTapped
        case continueTapped
        case datePickerPresented(Bool)
        case bestBeforeDateChanged(Date)
        case remindDaysBeforeChanged(Int)
        case incrementQuantity
        case decrementQuantity
        case backTapped
        case saveItemTapped
        case itemSaved(Item)
        case saveFailed(String)
        case viewItemTapped(Item)
        case addAnotherTapped
        case dismiss
    }

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.dismiss) var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .scanLabelTapped:
                state.step = .scanLabel
                return .none

            case .enterManuallyTapped:
                state.step = .itemDetails(scannedDate: nil, ocrString: nil)
                return .none

            case let .dateScanned(date, ocrString):
                state.bestBeforeDate = date
                state.isDateFromScan = true
                state.step = .itemDetails(scannedDate: date, ocrString: ocrString)
                return .none

            case .scanAgainTapped:
                state.step = .scanLabel
                return .none

            case .continueTapped:
                let draft = Item(
                    name: state.itemName,
                    quantity: state.quantity.isEmpty ? nil : state.quantity,
                    location: state.location,
                    locationCustom: state.locationCustom.isEmpty ? nil : state.locationCustom,
                    bestBeforeDate: state.bestBeforeDate,
                    remindDaysBefore: state.remindDaysBefore,
                    remindOnDay: state.remindOnDay
                )
                state.step = .reminder(draft)
                return .none

            case let .datePickerPresented(isPresented):
                state.isDatePickerPresented = isPresented
                return .none

            case let .bestBeforeDateChanged(date):
                state.bestBeforeDate = date
                state.isDateFromScan = false
                return .none

            case let .remindDaysBeforeChanged(days):
                state.remindDaysBefore = days
                return .none

            case .incrementQuantity:
                let current = Int(state.quantity) ?? 1
                state.quantity = String(current + 1)
                return .none

            case .decrementQuantity:
                let current = Int(state.quantity) ?? 1
                state.quantity = String(max(1, current - 1))
                return .none

            case .backTapped:
                switch state.step {
                case .itemDetails:
                    state.step = state.isDateFromScan ? .scanLabel : .chooseMethod
                case .reminder:
                    state.step = .itemDetails(
                        scannedDate: state.isDateFromScan ? state.bestBeforeDate : nil,
                        ocrString: nil
                    )
                default:
                    break
                }
                return .none

            case .saveItemTapped:
                state.isSaving = true
                state.saveError = nil
                let input = ItemIn(
                    name: state.itemName,
                    quantity: state.quantity.isEmpty ? nil : state.quantity,
                    location: state.location,
                    locationCustom: state.locationCustom.isEmpty ? nil : state.locationCustom,
                    bestBeforeDate: state.bestBeforeDate.dateOnly,
                    remindDaysBefore: state.remindDaysBefore,
                    remindOnDay: state.remindOnDay
                )
                return .run { send in
                    do {
                        let saved = try await apiClient.createItem(input)
                        await send(.itemSaved(saved))
                    } catch {
                        await send(.saveFailed(error.localizedDescription))
                    }
                }

            case let .itemSaved(item):
                state.isSaving = false
                state.step = .saved(item)
                return .none

            case let .saveFailed(message):
                state.isSaving = false
                state.saveError = message
                return .none

            case .viewItemTapped:
                return .none

            case .addAnotherTapped:
                state = State()
                return .none

            case .dismiss:
                return .run { _ in await dismiss() }
            }
        }
    }
}

// MARK: - ItemsFeature

@Reducer
public struct ItemsFeature {
    @ObservableState
    public struct State: Equatable {
        public var items: [Item] = []
        public var isLoading: Bool = false
        public var errorMessage: String?
        @Presents public var addItem: AddItemFeature.State?
        @Presents public var selectedItem: ItemDetailFeature.State?

        public init() {}

        public init(items: [Item]) {
            self.items = items
        }
    }

    public enum Action {
        case onAppear
        case fetchItems
        case itemsLoaded([Item])
        case loadFailed(String)
        case addItemButtonTapped
        case addItem(PresentationAction<AddItemFeature.Action>)
        case itemRowTapped(Item)
        case selectedItem(PresentationAction<ItemDetailFeature.Action>)
    }

    @Dependency(\.apiClient) var apiClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear, .fetchItems:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let items = try await apiClient.fetchItems()
                        await send(.itemsLoaded(items))
                    } catch {
                        await send(.loadFailed(error.localizedDescription))
                    }
                }

            case let .itemsLoaded(items):
                state.isLoading = false
                state.items = items
                return .none

            case let .loadFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case .addItemButtonTapped:
                state.addItem = AddItemFeature.State()
                return .none

            case .addItem(.presented(.dismiss)):
                state.addItem = nil
                return .none

            case .addItem(.presented(.itemSaved)):
                return .send(.fetchItems)

            case let .addItem(.presented(.viewItemTapped(item))):
                state.addItem = nil
                state.selectedItem = ItemDetailFeature.State(item: item)
                return .send(.fetchItems)

            case .addItem:
                return .none

            case let .itemRowTapped(item):
                state.selectedItem = ItemDetailFeature.State(item: item)
                return .none

            case .selectedItem(.presented(.delegate(.itemDeleted))),
                 .selectedItem(.presented(.delegate(.itemMarkedUsed))):
                state.selectedItem = nil
                return .send(.fetchItems)

            case .selectedItem:
                return .none
            }
        }
        .ifLet(\.$addItem, action: \.addItem) {
            AddItemFeature()
        }
        .ifLet(\.$selectedItem, action: \.selectedItem) {
            ItemDetailFeature()
        }
    }
}
