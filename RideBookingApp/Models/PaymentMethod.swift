import Foundation

enum CardBrand: String, Codable, CaseIterable, Identifiable { case visa, mastercard, amex, discover; var id: String { rawValue } }

struct PaymentMethod: Codable, Identifiable, Equatable {
    let id: String
    var brand: CardBrand
    var last4: String
    var isDefault: Bool
}