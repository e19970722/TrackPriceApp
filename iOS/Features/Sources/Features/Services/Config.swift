import Foundation

enum Config {
    static var apiBaseURL: URL {
        guard let urlString = Bundle.main.infoDictionary?["API_BASE_URL"] as? String,
              let url = URL(string: urlString) else {
            return URL(string: "http://localhost:8000")!
        }
        return url
    }
}
