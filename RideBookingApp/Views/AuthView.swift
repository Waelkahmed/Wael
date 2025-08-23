import SwiftUI

struct AuthView: View {
    @EnvironmentObject var session: AppSession
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var error: String?
    @State private var isSigningIn: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome").font(.largeTitle).bold()
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textFieldStyle(.roundedBorder)
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            if let error = error { Text(error).foregroundColor(.red) }

            Button {
                Task { await signIn() }
            } label: {
                if isSigningIn { ProgressView() } else { Text("Sign In").frame(maxWidth: .infinity) }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSigningIn)
        }
        .padding()
    }

    private func signIn() async {
        isSigningIn = true
        defer { isSigningIn = false }
        do {
            try await session.signIn(email: email, password: password)
        } catch {
            self.error = "Invalid credentials"
        }
    }
}