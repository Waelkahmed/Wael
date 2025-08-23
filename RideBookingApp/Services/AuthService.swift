import Foundation

protocol AuthServicing {
    func signIn(email: String, password: String) async throws -> User
}

enum AuthError: Error { case invalidCredentials }

final class AuthService: AuthServicing {
    func signIn(email: String, password: String) async throws -> User {
        do {
            return try await BackendClient.shared.login(email: email, password: password)
        } catch {
            throw AuthError.invalidCredentials
        }
    }
}