import SwiftUI

@main
struct RideBookingApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RideBookingView(viewModel: RideBookingViewModel(service: RideBookingService()))
            }
        }
    }
}