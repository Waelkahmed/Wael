import Foundation

final class TokenStore {
    static let shared = TokenStore()
    private let accessKey = "access_token"
    private let refreshKey = "refresh_token"

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: accessKey) }
        set { if let v = newValue { UserDefaults.standard.set(v, forKey: accessKey) } else { UserDefaults.standard.removeObject(forKey: accessKey) } }
    }

    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: refreshKey) }
        set { if let v = newValue { UserDefaults.standard.set(v, forKey: refreshKey) } else { UserDefaults.standard.removeObject(forKey: refreshKey) } }
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
    }
}