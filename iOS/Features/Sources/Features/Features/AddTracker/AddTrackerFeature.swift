import ComposableArchitecture
import Foundation

// MARK: - ElementInfo

public struct ElementInfo: Equatable {
    public var cssSelector: String
    public var xpath: String
    public var rawText: String
    public var currentPrice: Double?
    public var currencySymbol: String

    public init(cssSelector: String, xpath: String, rawText: String,
                currentPrice: Double?, currencySymbol: String) {
        self.cssSelector = cssSelector
        self.xpath = xpath
        self.rawText = rawText
        self.currentPrice = currentPrice
        self.currencySymbol = currencySymbol
    }
}

// MARK: - AddTrackerFeature

@Reducer
public struct AddTrackerFeature {

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
        public var isPickerActive: Bool = false

        // Target setup fields
        public var trackerName: String = ""
        public var targetPriceInput: String = ""
        public var targetDirection: Tracker.TargetDirection = .below

        // Creation status
        public var isCreating: Bool = false
        public var creationError: String?

        public init() {}
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case urlInputChanged(String)
        case loadURL
        case webViewNavigated(URL)
        case pageLoadStateChanged(Bool)
        case pickerToggled
        case elementPicked(ElementInfo)
        case confirmationConfirmed
        case confirmationRejected
        case targetSetupSubmitted(CreateTrackerRequest)
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

            case .pickerToggled:
                state.isPickerActive.toggle()
                return .none

            case let .elementPicked(info):
                state.isPickerActive = false
                state.step = .confirmation(info)
                return .none

            case .confirmationConfirmed:
                guard case let .confirmation(info) = state.step else { return .none }
                state.trackerName = state.currentURL?.host ?? ""
                state.targetPriceInput = info.currentPrice.map { String($0) } ?? ""
                state.step = .targetSetup(info)
                return .none

            case .confirmationRejected:
                state.step = .webView
                return .none

            case let .targetSetupSubmitted(request):
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
}
