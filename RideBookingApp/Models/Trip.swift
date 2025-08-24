import Foundation
import CoreLocation

enum TripStatus: String, Codable { case completed, canceled }

struct Trip: Identifiable, Codable, Equatable {
    let id: String
    let pickupName: String
    let dropoffName: String
    let pickupCoordinate: CLLocationCoordinate2D
    let dropoffCoordinate: CLLocationCoordinate2D
    let startDate: Date
    let endDate: Date
    let distanceKm: Double
    let fare: Double
    let rideType: RideType
    var rating: Int?
    var status: TripStatus
}

extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(latitude)
        try container.encode(longitude)
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let lat = try container.decode(CLLocationDegrees.self)
        let lon = try container.decode(CLLocationDegrees.self)
        self.init(latitude: lat, longitude: lon)
    }
}