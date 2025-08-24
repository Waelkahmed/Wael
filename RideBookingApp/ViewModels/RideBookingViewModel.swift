import Foundation
import SwiftUI

@MainActor
final class RideBookingViewModel: ObservableObject {
    @Published var pickupLocationText: String = ""
    @Published var dropoffLocationText: String = ""
    @Published var rideDate: Date = Date()

    @Published var rideType: RideType = .standard
    @Published var estimatedDistanceKilometers: Double = 8.0

    @Published var isBookingInProgress: Bool = false
    @Published var bookingConfirmation: RideConfirmation?
    @Published var errorMessage: String?

    var isFormValid: Bool {
        let pickup = pickupLocationText.trimmingCharacters(in: .whitespacesAndNewlines)
        let dropoff = dropoffLocationText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !pickup.isEmpty && !dropoff.isEmpty && estimatedDistanceKilometers > 0.2
    }

    var fareEstimate: Double {
        let base = rideType.baseFare + rideType.perKilometerRate * estimatedDistanceKilometers
        let surge = surgeMultiplier(for: rideDate)
        return (base * surge).rounded(to: 2)
    }

    private let service: RideBookingServicing

    init(service: RideBookingServicing) {
        self.service = service
    }

    func bookRide() async {
        guard isFormValid else {
            errorMessage = "Please fill all fields and set a valid distance."
            return
        }
        isBookingInProgress = true
        defer { isBookingInProgress = false }

        let request = RideRequest(
            pickup: pickupLocationText,
            dropoff: dropoffLocationText,
            date: rideDate,
            distanceKm: estimatedDistanceKilometers,
            type: rideType
        )

        do {
            let confirmation = try await service.bookRide(request: request)
            bookingConfirmation = confirmation
        } catch {
            errorMessage = "Failed to book ride. Please try again."
        }
    }

    private func surgeMultiplier(for date: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: date)
        if (7...9).contains(hour) || (17...20).contains(hour) { return 1.25 }
        return 1.0
    }
}