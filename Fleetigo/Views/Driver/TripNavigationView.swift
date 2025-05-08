import SwiftUI
import MapKit
import CoreLocation

struct TripNavigationView: View {
    @State private var isAtStartLocation = false
    @State private var routeExists = false
    @State private var calculatedRoute: MKRoute?
    @State private var navigateToPostChecklist = false
    let consignmentId: UUID?
    let vehichleId: UUID?
    let driverId: UUID?

    @State private var tripStarted = false
    @State private var locationManager = CLLocationManager()
    @State private var currentLocation: CLLocation? // State variable to hold current location


    // Add properties to receive coordinates
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?


    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#B1CEFF"), location: 0.0),
                        .init(color: Color.white, location: 0.20)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .top)

                VStack {
                    // Use the passed coordinates when instantiating MapView
                    if routeExists, let startCoord = startCoordinate, let endCoord = endCoordinate {
                         TripMapView(startCoordinate: startCoord, endCoordinate: endCoord, route: calculatedRoute)
                            .frame(maxHeight: .infinity)
                    } else {
                        Text("Could not display map or route.") // Handle case where coordinates are nil
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxHeight: .infinity)
                    }

                    Button(action: {
                        startTrip()
                    }) {
                        Text("Start Trip")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isAtStartLocation ? Color(hex: "#4E8FFF") : Color.gray.opacity(0.4))
                            .cornerRadius(12)
                    }
                    .padding()
                    .disabled(!isAtStartLocation) // Disable button if not at start location

                    NavigationLink(destination: PostTripChecklistView(consignmentId: consignmentId, vehichleId: vehichleId, driverId: driverId), isActive: $navigateToPostChecklist) { // Assuming PostTripChecklistView exists
                        EmptyView()
                    }
                }
            }
            .navigationTitle("Trip Navigation")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                setupLocationManager()
                // Check location and calculate route only if coordinates are available
                if startCoordinate != nil && endCoordinate != nil {
                     checkDriverLocation()
                     calculateRoute()
                } else {
                    // Handle the case where coordinates were not passed or are nil
                    print("Start or end coordinate is nil in TripNavigationView. Cannot calculate route or check location.")
                    routeExists = false // Ensure map doesn't show an invalid route
                    isAtStartLocation = false // Disable start button
                }
            }
             .onDisappear {
                // Stop location updates when the view disappears
                locationManager.stopUpdatingLocation()
                // Clean up observer if it wasn't removed on arrival
                NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
             }
        }
    }

    private func setupLocationManager() {
        locationManager.delegate = LocationDelegate { newLocation in
            self.currentLocation = newLocation
            // Potentially re-check location when it updates if needed,
            // but for simplicity, initial check onAppear might suffice for button state
            if tripStarted {
                 checkIfArrivedAtDestination() // Only check arrival if trip has started
            } else {
                 checkDriverLocation() // Re-check if at start location while waiting to start
            }
        }
        locationManager.requestWhenInUseAuthorization()
        // Start updating location only when the view appears
        locationManager.startUpdatingLocation()
    }

    // Use the passed startCoordinate property
    private func checkDriverLocation() {
        guard let currentLocation = currentLocation, let startCoord = startCoordinate else {
             isAtStartLocation = false
             print("Cannot check driver location: Current location or start coordinate is nil.")
             return
        }
        let startLocationCLL = CLLocation(latitude: startCoord.latitude, longitude: startCoord.longitude)
        let distance = currentLocation.distance(from: startLocationCLL)
        print("Distance to start: \(distance) meters")
        // Consider a small tolerance (e.g., 100 meters)
        isAtStartLocation = distance <= 100
    }

    // Use the passed startCoordinate and endCoordinate properties
    private func calculateRoute() {
        guard let startCoord = startCoordinate, let endCoord = endCoordinate else {
            routeExists = false
            print("Cannot calculate route: Start or end coordinate is nil.")
            return
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoord))
        request.transportType = .automobile // Specify road travel

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let route = response?.routes.first, error == nil {
                DispatchQueue.main.async {
                    self.calculatedRoute = route
                    self.routeExists = true
                    print("Route calculated successfully.")
                }
            } else {
                 DispatchQueue.main.async {
                    self.routeExists = false
                    print("Failed to calculate route: \(error?.localizedDescription ?? "Unknown error")")
                 }
            }
        }
    }

    private func startTrip() {
        tripStarted = true
        setupAppReturnObserver()
        openAppleMapsForNavigation()
        // Location updates continue to check for arrival
    }

    // Existing App Return Observer logic seems okay for the simulated end
    private func setupAppReturnObserver() {
         // Remove any previous observer to avoid duplicates
         NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)

         NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
             if self.tripStarted { // Check tripStarted flag
                 self.tripStarted = false // Mark trip as ended upon returning
                 self.locationManager.stopUpdatingLocation() // Stop location updates
                 self.navigateToPostChecklist = true // Navigate to post-checklist
                 // Remove this specific observer after it triggers
                 NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
             }
         }
     }


    // Use the passed startCoordinate and endCoordinate properties
    private func openAppleMapsForNavigation() {
         guard let endCoord = endCoordinate else { // We only need the destination to open navigation
              print("Cannot open maps: End coordinate is nil.")
             return
         }

         // Open Apple Maps for navigation from current location to the end coordinate
         let destinationMapItem = MKMapItem(placemark: MKPlacemark(coordinate: endCoord))
         let launchOptions = [
             MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving,
             MKLaunchOptionsShowsTrafficKey: true // Optional: Show traffic
         ] as [String : Any] // Cast to [String: Any]

         destinationMapItem.openInMaps(launchOptions: launchOptions)
     }


    // Use the passed endCoordinate property
    private func checkIfArrivedAtDestination() {
        guard let currentLocation = currentLocation, let endCoord = endCoordinate else {
             print("Cannot check arrival: Current location or end coordinate is nil.")
            return // Cannot check arrival if location or end coordinate is missing
        }
        let destination = CLLocation(latitude: endCoord.latitude, longitude: endCoord.longitude)

        let distance = currentLocation.distance(from: destination)
        print("Distance to destination: \(distance) meters")

        // Define an arrival threshold (e.g., 100 meters)
        let arrivalThreshold: CLLocationDistance = 100

        if distance <= arrivalThreshold {
            print("Driver has arrived at destination.")
            tripStarted = false // Mark trip as ended
            locationManager.stopUpdatingLocation() // Stop location updates
            navigateToPostChecklist = true // Navigate to post-checklist
             // Remove the observer here as the trip is ended
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }
}

// TripMapView struct remains mostly the same, but ensure it handles optional coordinates if needed
// (It currently takes non-optional, so the checks in TripNavigationView are important before passing)
struct TripMapView: UIViewRepresentable {
    let startCoordinate: CLLocationCoordinate2D // These must be non-nil when passed from TripNavigationView
    let endCoordinate: CLLocationCoordinate2D   // These must be non-nil when passed from TripNavigationView
    let route: MKRoute?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations)

        let startAnnotation = MKPointAnnotation()
        startAnnotation.coordinate = startCoordinate
        startAnnotation.title = "Start"
        let endAnnotation = MKPointAnnotation()
        endAnnotation.coordinate = endCoordinate
        endAnnotation.title = "End"
        uiView.addAnnotations([startAnnotation, endAnnotation])

        if let route = route {
            uiView.addOverlay(route.polyline, level: .aboveRoads)
            let rect = route.polyline.boundingMapRect
            // Adjust the map region to fit the route or annotations
             let annotationsRect = MKMapRect(origin: MKMapPoint(startCoordinate), size: MKMapSize()).union(MKMapRect(origin: MKMapPoint(endCoordinate), size: MKMapSize()))
             let combinedRect = rect.union(annotationsRect) // Include annotations in the zoom calculation
             uiView.setVisibleMapRect(combinedRect, edgePadding: UIEdgeInsets(top: 80, left: 50, bottom: 120, right: 50), animated: true) // Add padding
        } else {
            // If no route, show both annotations and zoom to fit them
            let annotationsRect = MKMapRect(origin: MKMapPoint(startCoordinate), size: MKMapSize()).union(MKMapRect(origin: MKMapPoint(endCoordinate), size: MKMapSize()))
             uiView.setVisibleMapRect(annotationsRect, edgePadding: UIEdgeInsets(top: 80, left: 50, bottom: 120, right: 50), animated: true) // Add padding
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 4.0
            // Optional: Add a dashed line for alternate routes or something else
            // renderer.lineDashPattern = [2, 5]
            return renderer
        }

    }
}

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    var onUpdate: (CLLocation) -> Void

    init(onUpdate: @escaping (CLLocation) -> Void) {
        self.onUpdate = onUpdate
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            onUpdate(location)
        }
    }

     func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
         print("Location Manager failed with error: \(error.localizedDescription)")
         // Handle location errors, e.g., insufficient permissions
     }

     func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
         // Handle location authorization changes if necessary
         switch manager.authorizationStatus {
         case .authorizedWhenInUse, .authorizedAlways:
             print("Location authorization granted.")
             // If authorization was just granted, you might want to start updating location
             // manager.startUpdatingLocation()
         case .denied, .restricted:
             print("Location authorization denied or restricted.")
             // Inform the user they need to grant location access
         case .notDetermined:
             print("Location authorization not determined.")
             // The requestWhenInUseAuthorization() call should handle this
         @unknown default:
             break
         }
     }
}


