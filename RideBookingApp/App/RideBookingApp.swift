import SwiftUI

@main
struct RideBookingApp: App {
    @StateObject private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isAuthenticated {
                    MainTabsView()
                } else {
                    AuthView()
                }
            }
            .environmentObject(session)
        }
    }
}