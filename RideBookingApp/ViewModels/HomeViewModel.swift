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
    @Published var promoCode: String = ""

    @Published var bookingConfirmation: RideConfirmation?
    @Published var bookingError: String?
    @Published var isBooking: Bool = false

    @Published var drivers: [Driver] = []
    @Published var assignedDriver: Driver?

    let locationManager: LocationManager
    private let bookingService: RideBookingServicing
    private let searchCompleter: MKLocalSearchCompleter
    private let completerDelegate: SearchCompleterDelegate
    private let trackingService = DriverTrackingService()

    private var pricingService: PricingService { session.pricingService }
    private var tripStore: TripStore { session.tripStore }
    private var notificationHelper: LocalNotificationHelper { session.notificationHelper }

    private let session: AppSession = AppSession()

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
        trackingService.start(userCoordinate: locationManager.userLocation?.coordinate)
        startTrackingBindings()
    }

    private func startTrackingBindings() {
        // Simple polling bridge for this demo
        Timer.scheduledTimer(withTimeInterval: 2.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.drivers = self.trackingService.nearbyDrivers
                self.assignedDriver = self.trackingService.assignedDriver
            }
        }
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
        pricingService.estimateFare(distanceKm: distanceKilometers, rideType: rideType, when: Date(), promoCode: promoCode)
    }

    func bookRide() async {
        guard let destName = destinationName, let destCoord = destinationCoordinate else { return }
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
            notificationHelper.schedule(title: "Driver arriving", body: "ETA ~ \(confirmation.etaMinutes) min", after: 1)
            trackingService.start(userCoordinate: locationManager.userLocation?.coordinate)
            simulateDriverTracking(to: destCoord)
            commitTripIfCompleted(dropoffName: destName, dropoffCoordinate: destCoord)
        } catch {
            bookingError = "Booking failed. Please try again."
        }
    }

    private func commitTripIfCompleted(dropoffName: String, dropoffCoordinate: CLLocationCoordinate2D) {
        guard let start = locationManager.userLocation else { return }
        let trip = Trip(
            id: UUID().uuidString,
            pickupName: "Current Location",
            dropoffName: dropoffName,
            pickupCoordinate: start.coordinate,
            dropoffCoordinate: dropoffCoordinate,
            startDate: Date(),
            endDate: Date().addingTimeInterval(600),
            distanceKm: distanceKilometers,
            fare: fareEstimate,
            rideType: rideType,
            rating: nil,
            status: .completed
        )
        tripStore.add(trip)
    }

    private func simulateDriverTracking(to destination: CLLocationCoordinate2D) {
        notificationHelper.schedule(title: "Trip complete", body: "Hope you enjoyed the ride!", after: 8)
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