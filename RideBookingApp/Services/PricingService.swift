import Foundation

struct PromoCode: Codable, Equatable, Identifiable {
    let id: String
    let code: String
    let percentOff: Double
}

final class PricingService {
    private let promos: [String: PromoCode] = [
        "SAVE10": PromoCode(id: "SAVE10", code: "SAVE10", percentOff: 0.10),
        "SAVE20": PromoCode(id: "SAVE20", code: "SAVE20", percentOff: 0.20)
    ]

    func estimateFare(distanceKm: Double, rideType: RideType, when date: Date, promoCode: String? = nil) -> Double {
        let base = rideType.baseFare + rideType.perKilometerRate * max(0, distanceKm)
        let surge = surgeMultiplier(for: date)
        var fare = base * surge
        if let code = promoCode?.uppercased(), let promo = promos[code] {
            fare *= (1.0 - promo.percentOff)
        }
        return fare.rounded(to: 2)
    }

    private func surgeMultiplier(for date: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: date)
        if (7...9).contains(hour) || (17...20).contains(hour) { return 1.25 }
        return 1.0
    }
}