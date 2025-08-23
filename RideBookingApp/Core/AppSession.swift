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
    }

    var isAuthenticated: Bool { currentUser != nil }

    func signIn(email: String, password: String) async throws {
        let user = try await authService.signIn(email: email, password: password)
        currentUser = user
    }

    func signOut() {
        currentUser = nil
        activeTrip = nil
    }
}