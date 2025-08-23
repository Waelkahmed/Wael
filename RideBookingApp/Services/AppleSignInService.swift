import Foundation

final class AppleSignInService {
    func signInWithApple(identityToken: String) async throws -> User {
        var req = URLRequest(url: BackendClient.shared.baseURL.appendingPathComponent("/auth/apple"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(["identityToken": identityToken])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { throw URLError(.badServerResponse) }
        struct Resp: Codable { let user: User; let accessToken: String; let refreshToken: String }
        let decoded = try JSONDecoder().decode(Resp.self, from: data)
        TokenStore.shared.accessToken = decoded.accessToken
        TokenStore.shared.refreshToken = decoded.refreshToken
        return decoded.user
    }
}