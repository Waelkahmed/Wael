import Foundation

@MainActor
final class TripStore: ObservableObject {
    @Published private(set) var trips: [Trip] = []

    func add(_ trip: Trip) { trips.insert(trip, at: 0) }

    func rateTrip(id: String, rating: Int) {
        guard let idx = trips.firstIndex(where: { $0.id == id }) else { return }
        trips[idx].rating = rating
    }

    func cancelTrip(id: String) {
        guard let idx = trips.firstIndex(where: { $0.id == id }) else { return }
        trips[idx].status = .canceled
    }
}