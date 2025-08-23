import Foundation
import CoreLocation

@MainActor
final class WebSocketDriverTrackingService: ObservableObject {
    @Published private(set) var drivers: [Driver] = []
    @Published private(set) var assignedDriver: Driver?

    private var webSocketTask: URLSessionWebSocketTask?

    func connect(baseURL: URL = BackendClient.shared.baseURL, userCoordinate: CLLocationCoordinate2D?) {
        disconnect()
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        comps.scheme = comps.scheme == "https" ? "wss" : "ws"
        comps.path = "/ws"
        guard let url = comps.url else { return }
        let task = URLSession.shared.webSocketTask(with: url)
        self.webSocketTask = task
        task.resume()
        receiveLoop()
        if let c = userCoordinate { subscribe(center: c) }
    }

    func subscribe(center: CLLocationCoordinate2D) {
        let msg: [String: Any] = ["type": "subscribe", "lat": center.latitude, "lon": center.longitude]
        if let data = try? JSONSerialization.data(withJSONObject: msg), let text = String(data: data, encoding: .utf8) {
            webSocketTask?.send(.string(text)) { _ in }
        }
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        drivers = []
        assignedDriver = nil
    }

    private func receiveLoop() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handle(text: text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) { self.handle(text: text) }
                @unknown default: break
                }
            case .failure:
                break
            }
            self.receiveLoop()
        }
    }

    private func handle(text: String) {
        guard let data = text.data(using: .utf8), let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        guard json["type"] as? String == "drivers", let arr = json["drivers"] as? [[String: Any]] else { return }
        let assignedId = json["assignedDriverId"] as? String
        let parsed: [Driver] = arr.compactMap { item in
            guard let id = item["id"] as? String, let lat = item["lat"] as? Double, let lon = item["lon"] as? Double else { return nil }
            return Driver(id: id, coordinate: .init(latitude: lat, longitude: lon))
        }
        drivers = parsed
        if let aid = assignedId { assignedDriver = parsed.first(where: { $0.id == aid }) }
    }
}