import Foundation
import SwiftUI
import MapKit
import CoreLocation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []

    @Published var destinationName: String?
    @Published var destinationCoordinate: CLLocationCoordinate2D?

    @Published var route: MKRoute?
    @Published var isCalculatingRoute: Bool = false

    @Published var etaText: String = ""
    @Published var distanceKilometers: Double = 0

    @Published var rideType: RideType = .standard

    @Published var bookingConfirmation: RideConfirmation?
    @Published var bookingError: String?
    @Published var isBooking: Bool = false

    let locationManager: LocationManager
    private let bookingService: RideBookingServicing
    private let searchCompleter: MKLocalSearchCompleter
    private let completerDelegate: SearchCompleterDelegate

    init(locationManager: LocationManager = LocationManager(), bookingService: RideBookingServicing = RideBookingService()) {
        self.locationManager = locationManager
        self.bookingService = bookingService
        self.searchCompleter = MKLocalSearchCompleter()
        self.completerDelegate = SearchCompleterDelegate { [weak self] completions in
            Task { @MainActor in
                self?.suggestions = completions
            }
        }
        self.searchCompleter.delegate = completerDelegate
        self.searchCompleter.resultTypes = [.address, .pointOfInterest]
    }

    func onAppear() {
        locationManager.requestAuthorization()
    }

    func onSearchQueryChange(_ text: String) {
        searchQuery = text
        updateCompleterRegionIfNeeded()
        searchCompleter.queryFragment = text
    }

    private func updateCompleterRegionIfNeeded() {
        if let coord = locationManager.userLocation?.coordinate {
            searchCompleter.region = MKCoordinateRegion(center: coord, latitudinalMeters: 12000, longitudinalMeters: 12000)
        }
    }

    func selectSuggestion(_ completion: MKLocalSearchCompletion) {
        Task { await resolve(completion) }
    }

    private func resolve(_ completion: MKLocalSearchCompletion) async {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            guard let item = response.mapItems.first else { return }
            destinationName = item.name
            destinationCoordinate = item.placemark.coordinate
            await calculateRoute()
        } catch {
            print("Search error: \(error.localizedDescription)")
        }
    }

    func calculateRoute() async {
        guard let user = locationManager.userLocation?.coordinate, let dest = destinationCoordinate else { return }
        isCalculatingRoute = true
        defer { isCalculatingRoute = false }

        let req = MKDirections.Request()
        req.source = MKMapItem(placemark: MKPlacemark(coordinate: user))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: dest))
        req.transportType = .automobile

        do {
            let result = try await MKDirections(request: req).calculate()
            guard let first = result.routes.first else { return }
            self.route = first
            self.distanceKilometers = first.distance / 1000.0
            self.etaText = Self.formatETA(first.expectedTravelTime)
        } catch {
            print("Route error: \(error.localizedDescription)")
        }
    }

    static func formatETA(_ seconds: TimeInterval) -> String {
        let minutes = Int(round(seconds / 60))
        return "\(minutes) min"
    }

    var fareEstimate: Double {
        let base = rideType.baseFare + rideType.perKilometerRate * max(distanceKilometers, 0)
        let surge = surgeMultiplier(for: Date())
        return (base * surge).rounded(to: 2)
    }

    func bookRide() async {
        guard let destName = destinationName else { return }
        isBooking = true
        defer { isBooking = false }
        let request = RideRequest(
            pickup: "Current Location",
            dropoff: destName,
            date: Date(),
            distanceKm: distanceKilometers,
            type: rideType
        )
        do {
            let confirmation = try await bookingService.bookRide(request: request)
            bookingConfirmation = confirmation
        } catch {
            bookingError = "Booking failed. Please try again."
        }
    }

    private func surgeMultiplier(for date: Date) -> Double {
        let hour = Calendar.current.component(.hour, from: date)
        if (7...9).contains(hour) || (17...20).contains(hour) { return 1.25 }
        return 1.0
    }
}

final class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let onUpdate: ([MKLocalSearchCompletion]) -> Void

    init(onUpdate: @escaping ([MKLocalSearchCompletion]) -> Void) {
        self.onUpdate = onUpdate
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        onUpdate(completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onUpdate([])
    }
}