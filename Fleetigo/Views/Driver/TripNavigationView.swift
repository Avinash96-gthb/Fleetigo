// TripNavigationView.swift
import SwiftUI
import MapKit
import CoreLocation

// --- Extensions (MKMapRect, MKPolyline) should be accessible here ---
// (Assuming they are defined elsewhere or included at the top as before)

struct TripNavigationView: View {
    // --- Passed Properties ---
    let consignmentId: UUID?
    let vehicleId: UUID?
    let driverId: UUID? // Logged-in driver's user ID (e.g., from auth.users or driver_profiles PK)
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?

    // --- Internal State ---
    @StateObject private var locationTracker = LocationTracker()
    @State private var currentTripDBId: UUID? // Actual trip_id from 'trips' table (PK)
    @State private var optimalRoute: MKRoute?
    @State private var optimalRoutePolyline: MKPolyline?
    @State private var routeExists = false

    @State private var isAtStartLocation = false
    @State private var tripStarted = false // True when driver presses "Start Trip"
    @State private var navigateToPostChecklist = false
    
    @State private var showDeviationAlert = false
    @State private var deviationMessage = ""
    @Environment(\.dismiss) var dismiss

    // --- Constants ---
    private let deviationThreshold: CLLocationDistance = 500.0
    private let startLocationThreshold: CLLocationDistance = 15000000000000000000000.0
    private let arrivalThreshold: CLLocationDistance = 10000000000000000000000000000.0

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient // Extracted background

                // Main Content VStack
                VStack(spacing: 0) {
                    mapAreaView // Extracted Map Area
                        .frame(maxHeight: .infinity) // Keep map taking space

                    bottomControlsView // Extracted Bottom Controls
                }

                // Hidden Navigation Link (Keep outside the main layout structure if needed)
                NavigationLink(
                    destination: PostTripChecklistView(consignmentId: consignmentId, vehichleId: vehicleId, driverId: driverId),
                    isActive: $navigateToPostChecklist
                ) { EmptyView() }.hidden()
            }
            .navigationTitle("Trip Navigation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { navigationToolbar } // Extracted Toolbar
            .onAppear {
                print("TripNavigationView appeared. DriverID: \(driverId?.uuidString ?? "NIL"), StartCoord: \(startCoordinate != nil), EndCoord: \(endCoordinate != nil)")
                print("TripNavigationView.onAppear: Received StartCoord: \(startCoordinate?.latitude ?? -999), \(startCoordinate?.longitude ?? -999)")
                    print("TripNavigationView.onAppear: Received EndCoord: \(endCoordinate?.latitude ?? -999), \(endCoordinate?.longitude ?? -999)")
                    // **** END LOGGING ****
                    print("TripNavigationView appeared. DriverID: \(driverId?.uuidString ?? "NIL"), StartCoord: \(startCoordinate != nil), EndCoord: \(endCoordinate != nil)")
                locationTracker.requestAuthorization()
                Task { await loadInitialTripDataAndRoute() }
            }
            .onDisappear(perform: handleDisappear) // Extracted logic
            .onReceive(locationTracker.$currentLocation, perform: handleLocationUpdate) // Extracted logic
            .alert("Route Deviation", isPresented: $showDeviationAlert) {
                Button("OK", role: .cancel) { showDeviationAlert = false }
            } message: { Text(deviationMessage) }
        }
    }

    // MARK: - Computed View Properties (Refactored Body Parts)

    /// Renders the background gradient.
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "#B1CEFF").opacity(0.7), location: 0.0),
                .init(color: Color.white, location: 0.30)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .top)
    }

    /// Conditionally renders the MapView or relevant messages.
    @ViewBuilder // Use ViewBuilder for conditional logic returning `some View`
    private var mapAreaView: some View {
        if routeExists, let startCoord = startCoordinate, let endCoord = endCoordinate {
            TripMapView(
                startCoordinate: startCoord,
                endCoordinate: endCoord,
                route: optimalRoute,
                userLocation: locationTracker.currentLocation?.coordinate
            )
        } else if startCoordinate == nil || endCoordinate == nil {
            VStack { Spacer(); Text("Route information unavailable.").foregroundColor(.gray).padding(); Spacer() }
        } else { // Coordinates exist, but route might still be calculating
            VStack { Spacer(); ProgressView("Calculating route...").padding(); Spacer() }
        }
    }

    /// Renders the bottom bar with route info and the Start/Progress button.
    private var bottomControlsView: some View {
        VStack(spacing: 5) {
            if let currentLoc = locationTracker.currentLocation,
                let optRoute = optimalRoute,
                routeExists {
                RouteInfoBar(currentLocation: currentLoc, route: optRoute, destinationCoordinate: endCoordinate)
                    .padding(.top, 8)
            }

            Button(action: handleStartTripButtonPressed) {
                Text(tripStarted ? "Trip In Progress (View in Maps)" : "Start Trip")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(tripStarted ? Color.gray : (isAtStartLocation ? Color(hex: "#4E8FFF") : Color.gray.opacity(0.6)))
                    .cornerRadius(12)
            }
            .disabled(tripStarted ? false : !isAtStartLocation)
            .padding(.horizontal)
            .padding(.bottom, tripStarted ? 0 : 8) // Remove bottom padding if tripStarted
            .padding(.top, 8)

            if tripStarted { // Show "End Trip" button only if tripStarted is true
                Button(action: handleEndTripButtonPressed) {
                    Label("End Trip", systemImage: "flag.checkered.circle.fill")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red) // Distinct color for ending
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(.thinMaterial)
    }
    
    
    /// Configures the navigation bar toolbar items.
    private var navigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { dismiss() } label: { Image(systemName: "xmark") }
        }
        // Add other toolbar items if needed
    }

    // MARK: - Core Logic Functions (Remain the same)

    func loadInitialTripDataAndRoute() async {
         guard let currentDriverId = self.driverId else {
             print("TripNavigationView Error: Driver ID is nil. Cannot load trip data.")
             await MainActor.run { self.routeExists = false; self.isAtStartLocation = false }
             return
         }
         print("TripNavigationView: Loading initial data for driver \(currentDriverId)")

         do {
             if let ongoingTrip = try await SupabaseManager.shared.fetchTrip(byDriverID: currentDriverId) {
                  guard let tripDatabaseId = ongoingTrip.id else { // Use correct PK field name
                      print("TripNavigationView Error: Fetched trip object is missing its database ID (trip_id).")
                      await MainActor.run { self.routeExists = false; self.isAtStartLocation = false }
                      return
                  }
                 self.currentTripDBId = tripDatabaseId
                 
                 print("TripNavigationView: Found ongoing trip with DB ID: \(tripDatabaseId)")

                 if self.startCoordinate != nil && self.endCoordinate != nil {
                     print("TripNavigationView: Coordinates available. Starting location tracker and route calculation.")
                     locationTracker.startTracking(tripId: tripDatabaseId, driverId: currentDriverId)
                     await calculateAndStoreOptimalRoute()
                 } else {
                     print("TripNavigationView Error: Start or End coordinates are nil. Cannot show map/route.")
                     await MainActor.run { self.routeExists = false }
                 }
             } else {
                 print("TripNavigationView: No ongoing trip found for driver \(currentDriverId).")
                 await MainActor.run { self.routeExists = false; self.isAtStartLocation = false }
             }
         } catch {
             print("TripNavigationView: Error fetching trip by driver ID: \(error)")
             await MainActor.run { self.routeExists = false; self.isAtStartLocation = false }
         }
     }

    func handleStartTripButtonPressed() {
        if tripStarted {
            print("TripNavigationView: Re-opening Apple Maps for navigation.")
            openAppleMapsForNavigation()
            return
        }
        guard isAtStartLocation else {
             print("TripNavigationView: Cannot start trip. Driver is not at the start location.")
             return
        }
        guard let tripID = self.currentTripDBId, let currentDriverId = self.driverId else {
            print("TripNavigationView Error: Cannot start trip - Missing TripID or DriverID.")
            return
        }
        
        print("TripNavigationView: Attempting to start trip \(tripID)...")
        Task {
            do {
                try await SupabaseManager.shared.updateTripStatus(tripId: tripID, newStatus: "ongoing")
                print("TripNavigationView: Trip status updated to ongoing in DB.")
                await MainActor.run {
                    self.tripStarted = true
                    self.locationTracker.activateTripTracking()
                    print("TripNavigationView: Local state updated. Location tracking active.")
                    setupAppReturnObserver()
                    openAppleMapsForNavigation()
                }
            } catch {
                print("TripNavigationView Error: Failed to update trip status to ongoing: \(error)")
            }
        }
    }
    
    func checkIfAtStartLocation(currentLocation: CLLocation) {
        guard let startCoord = startCoordinate, !tripStarted else {
             if !tripStarted { DispatchQueue.main.async { self.isAtStartLocation = false } }
            return
        }
        let startCLLocation = CLLocation(latitude: startCoord.latitude, longitude: startCoord.longitude)
        let distance = currentLocation.distance(from: startCLLocation)
        let isCloseEnough = distance <= startLocationThreshold
        
        if self.isAtStartLocation != isCloseEnough {
            DispatchQueue.main.async { self.isAtStartLocation = isCloseEnough }
            print("TripNavigationView: Driver is \(isCloseEnough ? "at" : "not at") start location (Distance: \(distance)m).")
        }
    }
    
    func calculateAndStoreOptimalRoute() async {
        guard let startCoord = startCoordinate, let endCoord = endCoordinate else {
            await MainActor.run { routeExists = false }
            print("TripNavigationView Error: Cannot calculate route - Start or end coordinate is nil.")
            return
        }
        print("TripNavigationView: Calculating optimal route...")

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoord))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false

        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            await MainActor.run {
                if let route = response.routes.first {
                        self.optimalRoute = route
                        self.optimalRoutePolyline = route.polyline
                        self.routeExists = true
                        print("TripNavigationView: Optimal route calculated.")
                } else {
                    self.routeExists = false
                    print("TripNavigationView: No routes found by MKDirections.")
                }
            }
        } catch {
            await MainActor.run { routeExists = false }
            print("TripNavigationView Error: Failed to calculate route: \(error.localizedDescription)")
            if let mkError = error as? MKError, mkError.code == .placemarkNotFound || mkError.code == .directionsNotFound {
                 print("TripNavigationView: Could not find directions between points.")
            }
        }
    }
    
    func handleEndTripButtonPressed() {
            print("TripNavigationView: Manual 'End Trip' button pressed.")
            guard tripStarted else {
                print("TripNavigationView: Trip not started, cannot end.")
                return
            }

            // Perform the same actions as arriving at the destination
            Task {
                await MainActor.run {
                    self.tripStarted = false
                    self.locationTracker.isTripActive = false
                    self.locationTracker.stopTracking()
                    self.navigateToPostChecklist = true
                }

                NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)

                if let tripID = self.currentTripDBId {
                    do {
                        // Update status to completed (or maybe a different status like 'ended_manually'?)
                        try await SupabaseManager.shared.updateTripStatus(tripId: tripID, newStatus: "completed") // Or "ended_manually"
                        print("TripNavigationView: Trip \(tripID) status updated to 'completed' via manual end.")
                        
                        // Optionally trigger the revenue calculation and status updates here as well,
                        // similar to what `TripManager.endCurrentTrip` does.
                        // This might involve passing necessary info back or having TripManager handle it.
                        // For now, just updating status. You might need to call a TripManager function.
                        // Example: await tripManager.finalizeTrip(tripId: tripID, driverId: driverId, vehicleId: vehicleId)

                    } catch {
                        print("TripNavigationView Error: Failed to update trip \(tripID) status on manual end: \(error)")
                        // Handle error
                    }
                } else {
                    print("TripNavigationView Warning: Manual end trip, but currentTripDBId was nil.")
                }
            }
        }

    func checkRouteDeviation(currentLocation: CLLocation) {
        guard let optimalPoly = self.optimalRoutePolyline,
              let tripID = self.currentTripDBId,
              let currentDriverId = self.driverId,
              tripStarted else { return }

        var smallestDistanceToVertex: CLLocationDistance = .greatestFiniteMagnitude
        var closestVertexOnRoute: CLLocationCoordinate2D? = nil
        let points = optimalPoly.points()
        guard optimalPoly.pointCount > 0 else { return }

        for i in 0..<optimalPoly.pointCount {
            let vertexMapPoint = points[i]
            let vertexLocation = CLLocation(latitude: vertexMapPoint.coordinate.latitude, longitude: vertexMapPoint.coordinate.longitude)
            let distance = currentLocation.distance(from: vertexLocation)
            if distance < smallestDistanceToVertex {
                smallestDistanceToVertex = distance
                closestVertexOnRoute = vertexMapPoint.coordinate
            }
        }

        if smallestDistanceToVertex > deviationThreshold {
            let message = "Significant deviation from route detected (~ \(Int(smallestDistanceToVertex))m)."
            if self.deviationMessage != message {
                print("⚠️ ROUTE DEVIATION! Distance: \(smallestDistanceToVertex)m")
                DispatchQueue.main.async {
                    self.deviationMessage = message
                    self.showDeviationAlert = true
                }
                let warning = RouteDeviationWarning(
                                // id: nil <- Let Supabase generate the UUID primary key
                                trip_id: tripID,                              // The ID of the current trip record
                                driver_id: currentDriverId,                   // The ID of the current driver
                                consignment_id: self.consignmentId,           // The ID of the consignment being tracked
                                deviation_latitude: currentLocation.coordinate.latitude,  // Driver's current latitude
                                deviation_longitude: currentLocation.coordinate.longitude, // Driver's current longitude
                                optimal_route_point_latitude: closestVertexOnRoute?.latitude, // Latitude of the closest point ON THE ROUTE (vertex in this case)
                                optimal_route_point_longitude: closestVertexOnRoute?.longitude,// Longitude of the closest point ON THE ROUTE (vertex in this case)
                                distance_from_route: smallestDistanceToVertex, // The calculated distance from the route (using vertex distance here)
                                timestamp: Date(),                            // The time the deviation was detected
                                acknowledged_by_admin_at: nil,                // Not acknowledged yet
                                acknowledged_by_driver_at: nil,               // Not acknowledged yet
                                details: "Driver deviated approx. \(Int(smallestDistanceToVertex))m from route near point (\(closestVertexOnRoute?.latitude ?? 0), \(closestVertexOnRoute?.longitude ?? 0))." // Optional extra info
                            )
                Task { try? await SupabaseManager.shared.insertRouteDeviationWarning(warning: warning) }
            }
        } else {
            if !deviationMessage.isEmpty { DispatchQueue.main.async { self.deviationMessage = "" } }
        }
    }
    
    func openAppleMapsForNavigation() {
        guard let endCoord = endCoordinate else {
            print("TripNavigationView Error: Cannot open Apple Maps - Destination coordinate is nil.")
            return
        }
        print("TripNavigationView: Preparing to open Apple Maps for coordinate: \(endCoord.latitude), \(endCoord.longitude)") // Log before
        
        let destinationPlacemark = MKPlacemark(coordinate: endCoord)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        destinationMapItem.name = "Trip Destination"
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsShowsTrafficKey: true] as [String : Any]
        
        // Open Apple Maps
        // This function returns a Bool indicating if Maps could be opened, but doesn't throw
        let didOpen = MKMapItem.openMaps(
            with: [destinationMapItem],
            launchOptions: launchOptions
        )
        
        print("TripNavigationView: MKMapItem.openMaps called. Did attempt to open? \(didOpen)") // Log after
    }
    
    private func setupAppReturnObserver() {
            // Remove previous observer first to prevent duplicates
            NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
            
            // Add new observer
            NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
                // Access self properties directly within the closure (safe for structs here)
                guard self.tripStarted else { return } // Only act if trip was in progress
                print("TripNavigationView: App became active during trip.")
                
                // Option 1: Immediately check for arrival (might be redundant if onReceive is working)
                // if let currentLocation = self.locationTracker.currentLocation {
                //     self.checkIfArrivedAtDestination(currentLocation: currentLocation)
                // }

                 
                
//                // Option 3 (If using this as a HACK to end trip on simulator):
//                 print("TripNavigationView: Simulating trip end because app returned.")
//                 Task { await MainActor.run { self.handleEndTripButtonPressed() } }
                
            }
            print("TripNavigationView: App return observer set up.")
        }

    func checkIfArrivedAtDestination(currentLocation: CLLocation) {
            // Ensure trip is started and we have an end coordinate
            guard let endCoord = endCoordinate, tripStarted else { return }

            let destination = CLLocation(latitude: endCoord.latitude, longitude: endCoord.longitude)
            let distanceToDestination = currentLocation.distance(from: destination)

            // Print distance for debugging, but maybe less frequently
            // print("TripNavigationView: Distance to destination: \(distanceToDestination)m")

            // Check if within arrival threshold
            if distanceToDestination <= arrivalThreshold {
                print("TripNavigationView: Driver has arrived at destination (within \(arrivalThreshold)m).")
                
                // Prevent duplicate execution if already processing arrival
                guard tripStarted else { return } // Check tripStarted again inside Task block if needed

                // Use a Task to perform async operations (DB update) and UI updates
                Task {
                    // Stop tracking and update UI on main thread first
                    await MainActor.run {
                        self.tripStarted = false                 // Mark trip as locally ended
                        self.locationTracker.isTripActive = false // Tell tracker to stop sending locations
                        self.locationTracker.stopTracking()      // Stop CoreLocation updates
                        self.navigateToPostChecklist = true      // Trigger navigation
                        print("TripNavigationView: Stopped tracking and initiated navigation to PostChecklist.")
                    }
                    
                    // Clean up app return observer
                    NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)

                    // Update trip status in database
                    if let tripID = self.currentTripDBId {
                        do {
                            try await SupabaseManager.shared.updateTripStatus(tripId: tripID, newStatus: "completed")
                            print("TripNavigationView: Trip \(tripID) status updated to completed in DB.")
                            
                            // **** IMPORTANT: Trigger Full End-of-Trip Logic ****
                            // This is where you should call the logic that calculates revenue,
                            // updates driver/vehicle/consignment statuses back to available/completed.
                            // This likely belongs in TripManager.
                            if let drivId = self.driverId, let vehId = self.vehicleId {
                                 print("TripNavigationView: Triggering final trip processing in TripManager.")
                                 // Assuming TripManager has a function like this:
                                 // await TripManager.shared.finalizeTrip(tripId: tripID, driverId: drivId, vehicleId: vehId, consignmentId: consignmentId)
                                 // Or maybe just notify TripManager that the trip ended, and it handles the rest.
                                 // For now, we only updated the trip status itself. Add calls to TripManager/SupabaseManager as needed.
                                 
                                 // Example: Update driver/vehicle status directly (less ideal than TripManager handling it)
                                  Task { try? await SupabaseManager.shared.updateDriverStatus(driverId: drivId, newStatus: "Available") }
                                  Task { try? await SupabaseManager.shared.updateVehicleStatus(vehicleId: vehId, newStatus: .available) }
                                  if let consId = self.consignmentId {
                                       Task { try? await SupabaseManager.shared.updateConsignmentStatus(consignmentId: consId, newStatus: .completed) } // Assuming ConsignmentStatus enum
                                  }


                            } else {
                                 print("TripNavigationView Warning: Missing driverId or vehicleId, cannot fully finalize trip statuses.")
                            }
                            
                        } catch {
                            print("TripNavigationView Error: Failed to update trip \(tripID) status to completed: \(error)")
                            // TODO: Handle potential failure (e.g., retry logic, offline queue)
                        }
                    } else {
                         print("TripNavigationView Warning: Arrived at destination, but currentTripDBId was nil. Cannot update DB status.")
                    }
                }
            }
        }




    // MARK: - Extracted Modifier/Observer Logic Handlers

    private func handleDisappear() {
        print("TripNavigationView disappeared.")
        locationTracker.deactivateTripTracking()
        locationTracker.stopTracking()
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private func handleLocationUpdate(_ newLocation: CLLocation?) {
        guard let location = newLocation else { return }
        if !tripStarted {
            checkIfAtStartLocation(currentLocation: location)
        } else {
            checkIfArrivedAtDestination(currentLocation: location)
            if tripStarted { // Check again as arrival might have set it to false
                 checkRouteDeviation(currentLocation: location)
            }
        }
    }
}

// --- Helper Views (RouteInfoBar, TripMapView) ---
// (Ensure these are defined as provided in previous responses)
// struct RouteInfoBar: View { ... }
// struct TripMapView: UIViewRepresentable { ... }

// Helper View for Route Info
struct RouteInfoBar: View {
    let currentLocation: CLLocation
    let route: MKRoute
    let destinationCoordinate: CLLocationCoordinate2D?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Route: \(route.name)")
                .font(.caption.weight(.semibold))
            
            HStack {
                Text("Distance: \(String(format: "%.1f", route.distance / 1000)) km")
                Spacer()
                Text("Time: \(formatTimeInterval(route.expectedTravelTime))")
            }
            .font(.caption)
            
            if let destCoord = destinationCoordinate {
                let remainingDistance = currentLocation.distance(from: CLLocation(latitude: destCoord.latitude, longitude: destCoord.longitude))
                Text("To Destination: \(String(format: "%.1f", remainingDistance / 1000)) km")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: interval) ?? ""
    }
}


// TripMapView (ensure it takes optional userLocation)
struct TripMapView: UIViewRepresentable {
    let startCoordinate: CLLocationCoordinate2D
    let endCoordinate: CLLocationCoordinate2D
    let route: MKRoute?
    let userLocation: CLLocationCoordinate2D? // Driver's current location pin

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        // mapView.showsUserLocation = true // We'll use a custom annotation for the driver
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        
        // Filter out previous custom annotations before adding new ones
        let customAnnotations = uiView.annotations.filter { !($0 is MKUserLocation) }
        uiView.removeAnnotations(customAnnotations)

        // Start and End Annotations
        let startAnnotation = MKPointAnnotation()
        startAnnotation.coordinate = startCoordinate
        startAnnotation.title = "Start"
        let endAnnotation = MKPointAnnotation()
        endAnnotation.coordinate = endCoordinate
        endAnnotation.title = "End"
        uiView.addAnnotations([startAnnotation, endAnnotation])

        // Driver's Current Location Annotation
        if let userLoc = userLocation {
            let driverAnnotation = MKPointAnnotation()
            driverAnnotation.coordinate = userLoc
            driverAnnotation.title = "Driver" // Use a distinct title for custom pin
            uiView.addAnnotation(driverAnnotation)
        }
        
        // Route Polyline
        if let routePolyline = route?.polyline {
            uiView.addOverlay(routePolyline, level: .aboveRoads)
        }
        
        // Zoom Logic
        var coordinatesToConsider = [startCoordinate, endCoordinate]
        if let userLoc = userLocation {
            coordinatesToConsider.append(userLoc)
        }
        
        if !coordinatesToConsider.isEmpty {
            let mapRect = MKMapRect.boundingMapRect(for: coordinatesToConsider)
            uiView.setVisibleMapRect(mapRect.paddedBy(percent: 0.4), animated: true)
        } else if let routePolyline = route?.polyline { // Fallback to route bounds if no specific points
            uiView.setVisibleMapRect(routePolyline.boundingMapRect.paddedBy(percent: 0.2), animated: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

            var identifier = "LocationPin"
            var markerColor: UIColor? = .systemBlue // Default
            var glyphImage: UIImage? = nil
            var glyphText: String? = nil

            if annotation.title == "Start" {
                identifier = "StartPin"
                markerColor = .systemGreen
                glyphImage = UIImage(systemName: "flag.fill")
            } else if annotation.title == "End" {
                identifier = "EndPin"
                markerColor = .systemRed
                glyphImage = UIImage(systemName: "flag.checkered")
            } else if annotation.title == "Driver" {
                identifier = "DriverPin"
                // Custom view for driver
                let pinView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                let truckImage = UIImage(systemName: "truck.box.fill")?
                                    .withTintColor(.white, renderingMode: .alwaysOriginal)
                let size = CGSize(width: 30, height: 30)
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                UIColor.purple.setFill() // Background color for the circle
                UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
                truckImage?.draw(in: CGRect(x: 5, y: 5, width: 20, height: 20)) // Adjust position
                let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()

                pinView.image = finalImage
                pinView.canShowCallout = false // Or true if you want callout
                return pinView
            }

            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.markerTintColor = markerColor
            annotationView?.glyphImage = glyphImage
            annotationView?.glyphText = glyphText
            
            return annotationView
        }
    }
}

extension MKMapRect {
    static func boundingMapRect(for coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
        var rect = MKMapRect.null
        for coordinate in coordinates {
            let point = MKMapPoint(coordinate)
            // Ensure the rect is initialized before unioning if it's the first point
            if rect.isNull {
                rect = MKMapRect(x: point.x, y: point.y, width: 0, height: 0)
            } else {
                rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
            }
        }
        return rect
    }

    func paddedBy(percent: Double) -> MKMapRect {
        guard !self.isNull else { return .null } // Handle null rect
        let paddingWidth = self.size.width * percent
        let paddingHeight = self.size.height * percent
        return self.insetBy(dx: -paddingWidth / 2, dy: -paddingHeight / 2)
    }
}

extension MKPolyline { // Also ensure this is accessible
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](
            repeating: kCLLocationCoordinate2DInvalid,
            count: self.pointCount
        )
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        return coords.filter { CLLocationCoordinate2DIsValid($0) }
    }
}
