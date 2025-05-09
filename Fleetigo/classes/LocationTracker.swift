// LocationTracker.swift (Simplified for Foreground/Brief Background Only)
import CoreLocation
import Combine
import UIKit

class LocationTracker: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus

    private var tripId: UUID?
    private var driverId: UUID?
    @Published var isTripActive: Bool = false // Still useful to control DB updates

    private var locationSendTimer: Timer?
    private let locationSendInterval: TimeInterval = 5.0 // Increased interval slightly (5s)

    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation // Good accuracy needed
        locationManager.distanceFilter = 20 // Update if moved 20 meters - less frequent than 10m

        // --- REMOVED Background Properties ---
        // locationManager.allowsBackgroundLocationUpdates = false // Default is false
        // locationManager.pausesLocationUpdatesAutomatically = true // Default is true
        // --- REMOVED Background Properties ---
        
        print("LocationTracker initialized (Foreground Mode). Current auth status: \(authorizationStatus.rawValue)")
    }

    // Request 'When In Use' - Sufficient for foreground tracking
    func requestAuthorization() {
        if authorizationStatus == .notDetermined {
            print("LocationTracker: Requesting 'When In Use' authorization.")
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .denied || authorizationStatus == .restricted {
             print("LocationTracker: Authorization denied or restricted.")
             // TODO: Guide user to settings
        }
    }

    func startTracking(tripId: UUID, driverId: UUID) {
        self.tripId = tripId
        self.driverId = driverId
        
        requestAuthorization()

        // Start updates if authorized (WhenInUse or Always)
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
            print("LocationTracker: Started CoreLocation updates for trip \(tripId).")
            // Timer will be started by activateTripTracking
        } else {
            print("LocationTracker: Cannot start tracking, authorization status is: \(authorizationStatus.rawValue)")
        }
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationSendTimer?.invalidate()
        locationSendTimer = nil
        // Reset active state when explicitly stopped
        Task { await MainActor.run { self.isTripActive = false } }
        print("LocationTracker: Stopped CoreLocation updates.")
    }

    // Call this from TripNavigationView when the "Start Trip" button is pressed
    func activateTripTracking() {
        guard self.tripId != nil, self.driverId != nil else { return }
        print("LocationTracker: Activating trip tracking (Supabase updates).")
        Task { await MainActor.run { self.isTripActive = true } } // Update state on main thread
        setupLocationSendTimer() // Start sending updates
    }

    // Call this from TripNavigationView when trip ends or view disappears
    func deactivateTripTracking() {
        print("LocationTracker: Deactivating trip tracking (Supabase updates).")
        Task { await MainActor.run { self.isTripActive = false } } // Update state on main thread
        locationSendTimer?.invalidate()
        locationSendTimer = nil
    }

    private func setupLocationSendTimer() {
        locationSendTimer?.invalidate()
        locationSendTimer = Timer.scheduledTimer(withTimeInterval: locationSendInterval, repeats: true) { [weak self] _ in
            // Only send if trip is marked active AND we have a location
            guard let self = self, self.isTripActive, let location = self.currentLocation else { return }
            
            Task { await self.sendLocationToSupabase(coordinate: location.coordinate) }
        }
        print("LocationTracker: Supabase update timer started (Interval: \(locationSendInterval)s).")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        // Throttle UI updates slightly if needed, though @Published handles some batching
        DispatchQueue.main.async {
            self.currentLocation = newLocation
        }
        // Location sending is handled by the timer now
    }

    func sendLocationToSupabase(coordinate: CLLocationCoordinate2D) async {
        guard let tripID = self.tripId, let drivID = self.driverId else { return }
        // Use the simplified DriverLocation struct (without speed/accuracy)
        let driverLocationRecord = DriverLocation(tripId: tripID, driverId: drivID, coordinate: coordinate, timestamp: Date())
        do {
            try await SupabaseManager.shared.insertDriverLocation(location: driverLocationRecord)
             // print("Location sent: \(coordinate.latitude), \(coordinate.longitude)") // Less verbose logging
        } catch {
            print("LocationTracker: Error sending location: \(error)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("LocationTracker: CLLocationManager failed: \(error.localizedDescription)")
        // Consider stopping tracker or notifying user if error is persistent (e.g., no signal)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        print("LocationTracker: Authorization status changed to: \(newStatus.rawValue)")
        DispatchQueue.main.async { self.authorizationStatus = newStatus }
        
        if (newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways) && self.tripId != nil {
             // If tracking was intended, ensure updates are running
             locationManager.startUpdatingLocation() // Safe to call even if already running
             if self.isTripActive { setupLocationSendTimer() } // Restart timer if active
        } else {
             // Auth revoked or insufficient
             locationManager.stopUpdatingLocation()
             deactivateTripTracking() // Stop timer and set inactive
        }
    }
}
