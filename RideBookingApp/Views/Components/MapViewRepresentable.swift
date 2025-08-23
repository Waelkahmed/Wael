import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    let userLocation: CLLocation?
    let destinationCoordinate: CLLocationCoordinate2D?
    let routePolyline: MKPolyline?
    var drivers: [Driver] = []
    var assignedDriver: Driver?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        mapView.pointOfInterestFilter = .includingAll
        mapView.isRotateEnabled = false
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Annotations
        let toRemove = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(toRemove)
        if let dest = destinationCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = dest
            annotation.title = "Destination"
            mapView.addAnnotation(annotation)
        }
        for d in drivers {
            let a = MKPointAnnotation()
            a.coordinate = d.coordinate
            a.title = assignedDriver?.id == d.id ? "Your Driver" : "Driver"
            mapView.addAnnotation(a)
        }

        // Overlays
        mapView.removeOverlays(mapView.overlays)
        if let polyline = routePolyline {
            mapView.addOverlay(polyline)
            let rect = polyline.boundingMapRect
            let padding = UIEdgeInsets(top: 80, left: 40, bottom: 260, right: 40)
            mapView.setVisibleMapRect(rect, edgePadding: padding, animated: true)
        } else if let current = userLocation {
            let region = MKCoordinateRegion(center: current.coordinate, latitudinalMeters: 1200, longitudinalMeters: 1200)
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 6
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}