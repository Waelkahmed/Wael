import Foundation

protocol AuthServicing {
    func signIn(email: String, password: String) async throws -> User
}

enum AuthError: Error { case invalidCredentials }

final class AuthService: AuthServicing {
    func signIn(email: String, password: String) async throws -> User {
        try await Task.sleep(nanoseconds: 300_000_000)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else { throw AuthError.invalidCredentials }
        return User(id: UUID().uuidString, name: "Rider", email: trimmedEmail)
    }
}