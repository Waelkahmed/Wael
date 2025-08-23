import Foundation
import CoreLocation

struct Driver: Identifiable, Equatable {
    let id: String
    var coordinate: CLLocationCoordinate2D
}

@MainActor
final class DriverTrackingService: ObservableObject {
    @Published private(set) var nearbyDrivers: [Driver] = []
    @Published private(set) var assignedDriver: Driver?

    private var timer: Timer?

    func start(userCoordinate: CLLocationCoordinate2D?) {
        stop()
        guard let coord = userCoordinate else { return }
        nearbyDrivers = (0..<5).map { i in
            let jitterLat = (Double.random(in: -0.01...0.01))
            let jitterLon = (Double.random(in: -0.01...0.01))
            return Driver(id: "d\(i)", coordinate: CLLocationCoordinate2D(latitude: coord.latitude + jitterLat, longitude: coord.longitude + jitterLon))
        }
        assignedDriver = nearbyDrivers.randomElement()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.tick()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        nearbyDrivers = nearbyDrivers.map { driver in
            var c = driver.coordinate
            c.latitude += Double.random(in: -0.0005...0.0005)
            c.longitude += Double.random(in: -0.0005...0.0005)
            return Driver(id: driver.id, coordinate: c)
        }
        if let assigned = assignedDriver {
            var c = assigned.coordinate
            c.latitude += Double.random(in: -0.0007...0.0007)
            c.longitude += Double.random(in: -0.0007...0.0007)
            assignedDriver = Driver(id: assigned.id, coordinate: c)
        }
    }
}