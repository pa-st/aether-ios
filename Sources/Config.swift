import Foundation

final class AppSettings: ObservableObject {
    @Published var baseURL: String {
        didSet { UserDefaults.standard.set(baseURL, forKey: Self.baseURLKey) }
    }
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: Self.apiKeyKey) }
    }

    static let baseURLKey = "aether.baseURL"
    static let apiKeyKey = "aether.apiKey"
    static let defaultBaseURL = "http://10.10.10.11:8787"

    init() {
        let saved = UserDefaults.standard.string(forKey: Self.baseURLKey)
        self.baseURL = (saved?.isEmpty == false) ? saved! : Self.defaultBaseURL
        self.apiKey = UserDefaults.standard.string(forKey: Self.apiKeyKey) ?? ""
    }

    /// Trimmed base URL with no trailing slash, falling back to the default.
    var normalizedBaseURL: String {
        var s = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { s = Self.defaultBaseURL }
        while s.hasSuffix("/") { s.removeLast() }
        return s
    }
}
