import ComposableArchitecture
import Foundation

// MARK: - ElementInfo

public struct ElementInfo: Equatable {
    public var interactions: [InteractionStep]
    public var itemImageUrl: String?
    public var pageTitle: String?

    public init(interactions: [InteractionStep], itemImageUrl: String? = nil, pageTitle: String? = nil) {
        self.interactions = interactions
        self.itemImageUrl = itemImageUrl
        self.pageTitle = pageTitle
    }

    public var rawText: String? {
        interactions.last(where: { $0.role == "price" })?.rawText
    }

    public var currentPrice: Double? {
        interactions.last(where: { $0.role == "price" })?.currentPrice
    }

    public var currencySymbol: String {
        interactions.last(where: { $0.role == "price" })?.currencySymbol ?? ""
    }
}

// MARK: - AddTrackerFeature

@Reducer
public struct AddTrackerFeature {
    /// The screen currently shown in the flow.
    /// - `webView` browses the page; `isSelecting` arms element picking (frame 3).
    /// - `confirmation` is rendered as a sheet over the webview (frame 4).
    public enum Step: Equatable {
        case urlEntry
        case webView
        case confirmation(ElementInfo)
        case targetSetup(ElementInfo)
    }

    @ObservableState
    public struct State: Equatable {
        public var step: Step = .urlEntry
        public var urlInput: String = ""
        public var currentURL: URL?
        public var isLoadingPage: Bool = false
        public var isSelecting: Bool = false

        // Target setup fields
        public var trackerName: String = ""
        public var targetPriceInput: String = ""
        public var targetDirection: TargetDirection = .below

        /// Already-meets-target warning (frame 6)
        public var showsAlreadyMetWarning: Bool = false

        // Creation status
        public var isCreating: Bool = false
        public var creationError: String?

        public init() {}

        /// The element confirmed during target setup, if any.
        public var confirmedElement: ElementInfo? {
            switch step {
            case let .confirmation(info), let .targetSetup(info): info
            default: nil
            }
        }

        /// The current price detected for the confirmed element.
        public var currentPrice: Double? {
            confirmedElement?.currentPrice
        }

        /// Whether the current price already satisfies the chosen target/direction.
        public var targetAlreadyMet: Bool {
            guard let current = currentPrice, let target = Double(targetPriceInput) else {
                return false
            }
            switch targetDirection {
            case .below: return current <= target
            case .above: return current >= target
            }
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case urlInputChanged(String)
        case loadURL
        case webViewNavigated(URL)
        case pageLoadStateChanged(Bool)
        case pickElementTapped
        case selectionCancelled
        case elementPicked(ElementInfo)
        case confirmationConfirmed
        case confirmationRejected
        case saveTapped
        case alreadyMetWarningCancelled
        case alreadyMetWarningConfirmed
        case trackerCreated(Tracker)
        case creationFailed(String)
        case dismiss
    }

    public init() {}

    @Dependency(\.apiClient) var apiClient
    @Dependency(\.dismiss) var dismiss

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .urlInputChanged(input):
                state.urlInput = input
                return .none

            case .loadURL:
                let raw = state.urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !raw.isEmpty else { return .none }
                let withScheme = raw.lowercased().hasPrefix("http") ? raw : "https://\(raw)"
                guard let url = URL(string: withScheme) else { return .none }
                state.currentURL = url
                state.step = .webView
                return .none

            case let .webViewNavigated(url):
                state.currentURL = url
                return .none

            case let .pageLoadStateChanged(isLoading):
                state.isLoadingPage = isLoading
                return .none

            case .pickElementTapped:
                state.isSelecting = true
                return .none

            case .selectionCancelled:
                state.isSelecting = false
                return .none

            case let .elementPicked(info):
                state.isSelecting = false
                state.step = .confirmation(info)
                return .none

            case .confirmationConfirmed:
                guard case let .confirmation(info) = state.step else { return .none }
                state.trackerName = info.pageTitle ?? ""
                state.targetPriceInput = info.currentPrice.map { String(format: "%.2f", $0) } ?? ""
                state.step = .targetSetup(info)
                return .none

            case .confirmationRejected:
                state.step = .webView
                return .none

            case .saveTapped:
                guard Double(state.targetPriceInput) != nil else { return .none }
                if state.targetAlreadyMet {
                    state.showsAlreadyMetWarning = true
                    return .none
                }
                return performCreate(&state)

            case .alreadyMetWarningCancelled:
                state.showsAlreadyMetWarning = false
                return .none

            case .alreadyMetWarningConfirmed:
                state.showsAlreadyMetWarning = false
                return performCreate(&state)

            case .trackerCreated:
                state.isCreating = false
                return .run { _ in await dismiss() }

            case let .creationFailed(message):
                state.isCreating = false
                state.creationError = message
                return .none

            case .dismiss:
                return .run { _ in await dismiss() }
            }
        }
    }

    // MARK: - Helpers

    private func performCreate(_ state: inout State) -> Effect<Action> {
        guard case let .targetSetup(info) = state.step,
              let targetPrice = Double(state.targetPriceInput),
              let currentURL = state.currentURL
        else {
            return .none
        }
        let name = state.trackerName.isEmpty
            ? (info.pageTitle ?? currentURL.host ?? "Tracker")
            : state.trackerName
        let request = CreateTrackerRequest(
            url: currentURL.absoluteString,
            name: name,
            interactions: info.interactions,
            currencySymbol: info.currencySymbol,
            confirmedPrice: info.currentPrice ?? targetPrice,
            targetPrice: targetPrice,
            targetDirection: state.targetDirection,
            itemImageUrl: info.itemImageUrl
        )
        state.isCreating = true
        state.creationError = nil
        return .run { send in
            do {
                let tracker = try await apiClient.createTracker(request)
                await send(.trackerCreated(tracker))
            } catch {
                await send(.creationFailed(error.localizedDescription))
            }
        }
    }
}
