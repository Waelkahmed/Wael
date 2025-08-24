import Foundation

struct RideRequest: Codable {
    let pickup: String
    let dropoff: String
    let date: Date
    let distanceKm: Double
    let type: RideType
}

struct RideConfirmation: Codable, Identifiable {
    let id: String
    let etaMinutes: Int
    let quotedFare: Double
}

protocol RideBookingServicing {
    func bookRide(request: RideRequest) async throws -> RideConfirmation
}

final class RideBookingService: RideBookingServicing {
    func bookRide(request: RideRequest) async throws -> RideConfirmation {
        try await Task.sleep(nanoseconds: 700_000_000)
        let base = request.type.baseFare + request.type.perKilometerRate * request.distanceKm
        let surge = surgeMultiplier(for: request.date)
        let fare = (base * surge).rounded(to: 2)
        return RideConfirmation(id: UUID().uuidString, etaMinutes: Int.random(in: 3...8), quotedFare: fare)
    }

    private func surgeMultiplier(for date: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: date)
        if (7...9).contains(hour) || (17...20).contains(hour) { return 1.25 }
        return 1.0
    }
}

extension Double {
    func rounded(to places: Int) -> Double {
        guard places >= 0 else { return self }
        let power = pow(10.0, Double(places))
        return (self * power).rounded() / power
    }
}