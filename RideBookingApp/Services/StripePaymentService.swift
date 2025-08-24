import Foundation

struct PaymentIntent: Codable { let clientSecret: String; let amountCents: Int; let currency: String }

final class StripePaymentService {
    let baseURL: URL
    init(baseURL: URL = URL(string: "http://localhost:4000")!) { self.baseURL = baseURL }

    func createPaymentIntent(amountCents: Int, currency: String = "usd") async throws -> PaymentIntent {
        var request = URLRequest(url: baseURL.appendingPathComponent("/payments/intent"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["amountCents": amountCents, "currency": currency])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(PaymentIntent.self, from: data)
    }
}