import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: AppSession
    @State private var name: String = ""
    @State private var email: String = ""

    var body: some View {
        Form {
            Section("Account") {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                Button("Save") { save() }
            }

            Section("Payments") {
                if let user = session.currentUser {
                    let methods = session.paymentService.methods(for: user.id)
                    if methods.isEmpty {
                        Text("No payment methods").foregroundColor(.secondary)
                    } else {
                        ForEach(methods) { method in
                            HStack {
                                Text("\(method.brand.rawValue.uppercased()) **** \(method.last4)")
                                Spacer()
                                if method.isDefault { Text("Default").font(.caption).foregroundColor(.secondary) }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { session.paymentService.setDefault(methodId: method.id, for: user.id) }
                        }
                    }
                    Button("Add test card") {
                        let m = PaymentMethod(id: UUID().uuidString, brand: .visa, last4: String(Int.random(in: 1000...9999)), isDefault: true)
                        session.paymentService.addMethod(m, for: user.id)
                    }
                } else {
                    Text("Sign in to manage payments").foregroundColor(.secondary)
                }
            }

            Section {
                if session.isAuthenticated {
                    Button("Sign Out", role: .destructive) { session.signOut() }
                }
            }
        }
        .navigationTitle("Profile")
        .onAppear { sync() }
    }

    private func sync() {
        name = session.currentUser?.name ?? ""
        email = session.currentUser?.email ?? ""
    }

    private func save() {
        guard let user = session.currentUser else { return }
        session.currentUser = User(id: user.id, name: name, email: email)
    }
}