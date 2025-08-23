import Foundation

struct LoginResponse: Codable { let user: User; let accessToken: String; let refreshToken: String; let expiresIn: Int }

final class BackendClient {
    static let shared = BackendClient()
    var baseURL: URL = URL(string: "http://localhost:4000")!

    private var tokenStore: TokenStore { TokenStore.shared }

    func login(email: String, password: String) async throws -> User {
        var req = URLRequest(url: baseURL.appendingPathComponent("/auth/login"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["email": email, "password": password])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
        tokenStore.accessToken = decoded.accessToken
        tokenStore.refreshToken = decoded.refreshToken
        return decoded.user
    }

    func authorizedRequest(path: String, method: String = "GET", body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        if let body = body { req.httpBody = body; req.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        if let access = tokenStore.accessToken { req.setValue("Bearer \(access)", forHTTPHeaderField: "Authorization") }
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else { throw URLError(.badServerResponse) }
        if http.statusCode == 401, let refresh = tokenStore.refreshToken {
            var r = URLRequest(url: baseURL.appendingPathComponent("/auth/refresh"))
            r.httpMethod = "POST"
            r.setValue("application/json", forHTTPHeaderField: "Content-Type")
            r.httpBody = try JSONEncoder().encode(["refreshToken": refresh])
            let (rd, rr) = try await URLSession.shared.data(for: r)
            guard let rrh = rr as? HTTPURLResponse, (200..<300).contains(rrh.statusCode) else { throw URLError(.userAuthenticationRequired) }
            struct RefreshResp: Codable { let accessToken: String; let expiresIn: Int }
            let ref = try JSONDecoder().decode(RefreshResp.self, from: rd)
            tokenStore.accessToken = ref.accessToken
            return try await authorizedRequest(path: path, method: method, body: body)
        }
        return (data, http)
    }

    func registerDevice(token: String) async throws {
        let body = try JSONEncoder().encode(["token": token, "platform": "ios"])
        let (data, resp) = try await authorizedRequest(path: "/devices/register", method: "POST", body: body)
        guard (200..<300).contains(resp.statusCode) else { throw URLError(.badServerResponse) }
        _ = data
    }
}