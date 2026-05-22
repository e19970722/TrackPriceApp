import ComposableArchitecture
import Foundation

@Reducer
public struct DevConsoleFeature {
    @ObservableState
    public struct State: Equatable {
        public var baseURL: String = "http://localhost:8000"
        public var token: String = ""
        public var customPath: String = "/health"
        public var customMethod: String = "GET"
        public var customBody: String = ""
        public var response: String = ""
        public var isLoading: Bool = false

        public init() {}
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case fetchDevToken
        case runRequest
        case responseReceived(String)
        case setLoading(Bool)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .fetchDevToken:
                let baseURL = state.baseURL
                state.isLoading = true
                state.response = ""
                return .run { send in
                    let result = await devRequest("POST", baseURL: baseURL, path: "/dev/token", body: nil, token: nil)
                    await send(.responseReceived(result))
                    await send(.setLoading(false))
                }

            case .runRequest:
                let baseURL = state.baseURL
                let path = state.customPath
                let method = state.customMethod
                let body = state.customBody.isEmpty ? nil : state.customBody
                let token = state.token.isEmpty ? nil : state.token
                state.isLoading = true
                state.response = ""
                return .run { send in
                    let result = await devRequest(method, baseURL: baseURL, path: path, body: body, token: token)
                    await send(.responseReceived(result))
                    await send(.setLoading(false))
                }

            case let .responseReceived(text):
                state.response = text
                // Auto-extract token if this looks like an auth response
                if let data = text.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let t = json["token"] as? String {
                    state.token = t
                }
                return .none

            case let .setLoading(loading):
                state.isLoading = loading
                return .none
            }
        }
    }
}

private func devRequest(
    _ method: String,
    baseURL: String,
    path: String,
    body: String?,
    token: String?
) async -> String {
    guard let base = URL(string: baseURL), let url = URL(string: path, relativeTo: base) else {
        return "Error: invalid URL \(baseURL)\(path)"
    }
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
    if let body { request.httpBody = body.data(using: .utf8) }
    request.timeoutInterval = 10

    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let pretty = prettyJSON(data) ?? String(decoding: data, as: UTF8.self)
        return "HTTP \(status)\n\n\(pretty)"
    } catch {
        return "Error: \(error.localizedDescription)"
    }
}

private func prettyJSON(_ data: Data) -> String? {
    guard let obj = try? JSONSerialization.jsonObject(with: data),
          let pretty = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
    else { return nil }
    return String(decoding: pretty, as: UTF8.self)
}
