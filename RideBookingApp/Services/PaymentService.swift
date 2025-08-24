import Foundation

final class PaymentService {
    private var userIdToMethods: [String: [PaymentMethod]] = [:]

    func methods(for userId: String) -> [PaymentMethod] {
        userIdToMethods[userId] ?? []
    }

    func addMethod(_ method: PaymentMethod, for userId: String) {
        var list = userIdToMethods[userId] ?? []
        if method.isDefault { list = list.map { PaymentMethod(id: $0.id, brand: $0.brand, last4: $0.last4, isDefault: false) } }
        list.append(method)
        userIdToMethods[userId] = list
    }

    func setDefault(methodId: String, for userId: String) {
        let list = (userIdToMethods[userId] ?? []).map { m in
            PaymentMethod(id: m.id, brand: m.brand, last4: m.last4, isDefault: m.id == methodId)
        }
        userIdToMethods[userId] = list
    }
}