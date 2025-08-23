import Foundation

enum RideType: String, CaseIterable, Identifiable, Codable {
    case standard
    case xl
    case luxury

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .xl: return "XL"
        case .luxury: return "Luxury"
        }
    }

    var emoji: String {
        switch self {
        case .standard: return "🚗"
        case .xl: return "🚙"
        case .luxury: return "🚘"
        }
    }

    var baseFare: Double {
        switch self {
        case .standard: return 3.0
        case .xl: return 5.0
        case .luxury: return 8.0
        }
    }

    var perKilometerRate: Double {
        switch self {
        case .standard: return 1.2
        case .xl: return 1.8
        case .luxury: return 3.0
        }
    }
}