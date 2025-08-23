import Foundation
import SwiftUI

@MainActor
final class AppSession: ObservableObject {
    @Published var currentUser: User?
    @Published var selectedTabIndex: Int = 0
    @Published var activeTrip: Trip?

    let tripStore: TripStore
    let paymentService: PaymentService
    let pricingService: PricingService
    let notificationHelper: LocalNotificationHelper
    let authService: AuthServicing

    init(
        tripStore: TripStore = TripStore(),
        paymentService: PaymentService = PaymentService(),
        pricingService: PricingService = PricingService(),
        notificationHelper: LocalNotificationHelper = LocalNotificationHelper(),
        authService: AuthServicing = AuthService()
    ) {
        self.tripStore = tripStore
        self.paymentService = paymentService
        self.pricingService = pricingService
        self.notificationHelper = notificationHelper
        self.authService = authService
        NotificationCenter.default.addObserver(forName: NSNotification.Name("apnsTokenUpdated"), object: nil, queue: .main) { [weak self] note in
            guard let token = note.object as? String else { return }
            Task { try? await BackendClient.shared.registerDevice(token: token) }
        }
    }

    var isAuthenticated: Bool { currentUser != nil }

    func signIn(email: String, password: String) async throws {
        let user = try await authService.signIn(email: email, password: password)
        currentUser = user
        if let token = UserDefaults.standard.string(forKey: "apns_token") {
            try? await BackendClient.shared.registerDevice(token: token)
        }
    }

    func signOut() {
        currentUser = nil
        activeTrip = nil
        TokenStore.shared.clear()
    }
}