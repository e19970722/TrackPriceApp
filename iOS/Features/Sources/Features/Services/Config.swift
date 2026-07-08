import Foundation

enum Config {
    static var apiBaseURL: URL {
        guard let urlString = Bundle.main.infoDictionary?["API_BASE_URL"] as? String,
              let url = URL(string: urlString) else {
            return URL(string: "http://127.0.0.1:8000")!
        }
        return url
    }

    /// Placeholder — swap in the real support address before release.
    static let supportEmail = "support@trackprice.app"

    /// Placeholder — swap in the real privacy policy URL before release.
    static let privacyPolicyURL = URL(string: "https://trackprice.app/privacy")!
}
