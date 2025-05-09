//
//  ConsignmentDetailView.swift
//  FleetigoConsignment
//
//  Created by user@22 on 29/04/25.
//


import SwiftUI
import CoreLocation
import MapKit

struct ConsignmentDetailView: View {
    let consignment: Consignment
    
    // State for map data
    @State private var pickupGeoCoordinate: CLLocationCoordinate2D?
    @State private var dropGeoCoordinate: CLLocationCoordinate2D?
    @State private var driverCurrentLocation: CLLocationCoordinate2D?
    @State private var driverPathHistory: [CLLocationCoordinate2D] = []
    @State private var optimalRouteToDisplay: MKRoute?
    
    // UI State
    @State private var lastUpdatedMessage: String? = "Fetching location..."
    @State private var isLoadingMapData = true
    @State private var deviationWarnings: [RouteDeviationWarning] = []
    
    private let locationRefreshTimer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    // Using @StateObject for RouteCalculator as it publishes changes
    @StateObject private var routeCalculator = RouteCalculator2()
    @State private var currentDisplayTripId: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                generalInformationSection
                liveTrackingMapSection
                dateInformationSection
                contactInformationSection
                instructionsSection
                deviationWarningsSection
            }
            .padding()
        }
        .navigationTitle(consignment.id ?? "Consignment") // Use consignment.id (display ID)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            Task { await loadInitialDataForMapAndDetails() }
        }
        .onReceive(locationRefreshTimer) { _ in
            if consignment.status == .ongoing || consignment.status == .completed {
                Task { await fetchLatestDriverLocationAndPath() }
            }
        }
    }

    // MARK: - Data Loading
    func loadInitialDataForMapAndDetails() async {
            isLoadingMapData = true
            print("ConsignmentDetailView: Loading initial data for consignment \(consignment.id)...")

            // 1. Fetch the Trip ID associated with this consignment
            if let consignmentInternalPK = consignment.internal_id {
                do {
                    if let trip = try await SupabaseManager.shared.fetchTrip(byConsignmentID: consignmentInternalPK) {
                        self.currentDisplayTripId = trip.id // This is the trip's PK (trip_id in DB)
                        print("ConsignmentDetailView: Associated Trip ID fetched: \(self.currentDisplayTripId?.uuidString ?? "N/A")")
                    } else {
                        print("ConsignmentDetailView: No trip found associated with consignment \(consignmentInternalPK). Live tracking may not be available.")
                        self.lastUpdatedMessage = "No active trip data."
                    }
                } catch {
                    print("ConsignmentDetailView: Error fetching trip for consignment: \(error)")
                    self.lastUpdatedMessage = "Error fetching trip data."
                }
            } else {
                print("ConsignmentDetailView: Consignment internal_id is nil. Cannot fetch trip.")
                self.lastUpdatedMessage = "Consignment ID error."
            }

            // 2. Geocode addresses for pickup and drop
            await geocodeAddressesForMap()
            
            // 3. Fetch optimal route ONLY if both geocoded coordinates are available
            if let pCoord = pickupGeoCoordinate, let dCoord = dropGeoCoordinate {
                print("ConsignmentDetailView: Geocoded coords available. Fetching optimal route.")
                // Call the correct method on your RouteCalculator2 instance
                routeCalculator.calculateRoute(from: pCoord, to: dCoord) { route in
                    DispatchQueue.main.async {
                        self.optimalRouteToDisplay = route
                        if route == nil { print("ConsignmentDetailView: No optimal route found.") }
                        else { print("ConsignmentDetailView: Optimal route fetched.") }
                    }
                }
            } else {
                print("ConsignmentDetailView: Geocoded pickup/drop coordinates not available, skipping optimal route calculation.")
            }
            
            // 4. Fetch driver location, path, and warnings (only if we have a trip ID)
            if currentDisplayTripId != nil {
                await fetchLatestDriverLocationAndPath()
                await fetchDeviationWarnings()
            }
            
            isLoadingMapData = false
            print("ConsignmentDetailView: Initial data load attempt complete.")
        }

    // Helper to asynchronously geocode both addresses
    func geocodeAddressesForMap() async {
        print("ConsignmentDetailView: Starting geocoding for pickup and drop locations.")
        // Use a TaskGroup for concurrent geocoding if preferred, or sequential
        // For simplicity, sequential with await helper:
        self.pickupGeoCoordinate = await performGeocoding(for: consignment.pickup_location)
        self.dropGeoCoordinate = await performGeocoding(for: consignment.drop_location)
        print("ConsignmentDetailView: Geocoding finished. Pickup: \(pickupGeoCoordinate != nil), Drop: \(dropGeoCoordinate != nil)")
    }
    
    // Awaitable geocoding helper
    private func performGeocoding(for addressString: String) async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { continuation in
            routeCalculator.geocodeAddressString(addressString) { coordinate in // Assuming geocodeAddressString is in RouteCalculator
                continuation.resume(returning: coordinate)
            }
        }
    }

    // Fetches latest location and path history
    func fetchLatestDriverLocationAndPath() async {
        guard let associatedTripId = currentDisplayTripId else {
            await MainActor.run { self.lastUpdatedMessage = "Trip ID missing for location." }
            return
        }
        print("ConsignmentDetailView: Fetching latest location for trip \(associatedTripId)")

        do {
            async let latestLocationFetch = SupabaseManager.shared.fetchLatestDriverLocation(forTripId: associatedTripId)
            async let historyFetch = SupabaseManager.shared.fetchDriverLocationHistory(forTripId: associatedTripId, limit: 200)
            
            let latestLocation = try await latestLocationFetch
            let history = try await historyFetch
            
            await MainActor.run {
                if let loc = latestLocation {
                    self.driverCurrentLocation = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
                    if let ts = loc.timestamp {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .none
                        formatter.timeStyle = .medium
                        self.lastUpdatedMessage = "Live @ \(formatter.string(from: ts))"
                    } else { self.lastUpdatedMessage = "Location time unknown" }
                } else {
                    self.lastUpdatedMessage = "No recent location."
                }
                self.driverPathHistory = history.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
                 print("ConsignmentDetailView: Driver location/path updated. Current: \(self.driverCurrentLocation != nil), Path points: \(self.driverPathHistory.count)")
            }
        } catch {
            print("ConsignmentDetailView: Error fetching driver location/path: \(error)")
            await MainActor.run { self.lastUpdatedMessage = "Error fetching location." }
        }
    }

    // Fetches deviation warnings
    func fetchDeviationWarnings() async {
        guard let tripId = currentDisplayTripId else {
            print("ConsignmentDetailView: Trip ID missing for deviation warnings.")
            return
        }
        print("ConsignmentDetailView: Fetching deviation warnings for trip \(tripId)")
        do {
            let warnings = try await SupabaseManager.shared.fetchRouteDeviationWarnings(forTripId: tripId)
            await MainActor.run {
                self.deviationWarnings = warnings
                print("ConsignmentDetailView: Fetched \(warnings.count) deviation warnings.")
            }
        } catch {
            print("ConsignmentDetailView: Error fetching deviation warnings: \(error)")
        }
    }
    
    // MARK: - Sections
    
    private var generalInformationSection: some View {
        DetailSection(title: "General Information") {
            VStack(alignment: .leading, spacing: 10) {
                // Assuming consignment.id is your display ID (e.g., FLT123)
                // If consignment.internal_id is the UUID PK, use that if needed for something else.
                DetailRow(label: "Consignment No.", value: consignment.id ?? "N/A")
                DetailRow(label: "Trip ID", value: currentDisplayTripId?.uuidString.prefix(8).uppercased() ?? "N/A")
                DetailRow(label: "Status", value: consignment.status.rawValue.capitalized ?? "N/A")
                DetailRow(label: "Type", value: consignment.type.rawValue.capitalized)
                DetailRow(label: "Vehicle Type", value: consignment.vehichle_type.rawValue.capitalized ?? "N/A") // Assuming vehichle_type is on Consignment
                DetailRow(label: "Weight", value: consignment.weight.isEmpty ? "N/A" : "\(consignment.weight) kg")
                DetailRow(label: "Dimensions", value: consignment.dimensions.isEmpty ? "N/A" : consignment.dimensions)
                DetailRow(label: "Description", value: consignment.description.isEmpty ? "N/A" : consignment.description)
            }
        }
    }
    
    private var liveTrackingMapSection: some View {
        DetailSection(title: "Live Tracking") {
            HStack {
                Spacer() // For centering the message if map isn't ready
                if let message = lastUpdatedMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.bottom, 5)
            
            Group {
                if isLoadingMapData && optimalRouteToDisplay == nil && driverCurrentLocation == nil {
                    ProgressView("Loading map data...")
                        .frame(height: 300, alignment: .center) // Standardized height
                } else if pickupGeoCoordinate == nil && dropGeoCoordinate == nil && driverCurrentLocation == nil && optimalRouteToDisplay == nil {
                    // Only show this if all crucial map data is missing after loading attempt
                    Text("Map data unavailable (pickup/drop locations could not be found, or no driver location).")
                        .foregroundColor(.orange)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(height: 300, alignment: .center)
                } else {
                    LiveTrackingMapView(
                        pickupCoordinate: pickupGeoCoordinate,
                        dropCoordinate: dropGeoCoordinate,
                        driverCurrentLocation: $driverCurrentLocation,
                        optimalRoute: optimalRouteToDisplay,
                        driverPathHistory: $driverPathHistory
                    )
                    .frame(height: 300) // Standardized height
                    .frame(maxWidth: .infinity)
                    .cornerRadius(10) // Rounded corners for the map view itself
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                }
            }
        }
    }
    
    private var dateInformationSection: some View {
        DetailSection(title: "Timing") {
            VStack(alignment: .leading, spacing: 10) {
                DetailRow(label: "Pickup Date", value: consignment.pickup_date.formatted(date: .long, time: .shortened))
                DetailRow(label: "Delivery Date", value: consignment.delivery_date.formatted(date: .long, time: .shortened))
                if let created = consignment.created_at {
                    DetailRow(label: "Booked On", value: created.formatted(date: .long, time: .shortened))
                }
            }
        }
    }
    
    private var contactInformationSection: some View {
        DetailSection(title: "Contacts") {
            VStack(alignment: .leading, spacing: 10) {
                DetailRow(label: "Sender Phone", value: consignment.sender_phone)
                DetailRow(label: "Recipient Name", value: consignment.recipient_name)
                DetailRow(label: "Recipient Phone", value: consignment.recipient_phone)
            }
        }
    }
    
    private var instructionsSection: some View {
        DetailSection(title: "Special Instructions") {
            Text(consignment.instructions ?? "No special instructions provided.")
                .font(.subheadline)
                .foregroundColor(consignment.instructions == nil ? .gray : Color(UIColor.label))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4) // Space after title if content is simple text
        }
    }

    private var deviationWarningsSection: some View {
        DetailSection(title: "Route Deviation Alerts") {
            if isLoadingMapData && deviationWarnings.isEmpty { // Show loader if warnings are part of initial load
                ProgressView()
            } else if deviationWarnings.isEmpty {
                Text("No deviation alerts recorded for this trip.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(deviationWarnings) { warning in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                                Text("Deviated at: \(warning.timestamp?.formatted(date: .omitted, time: .shortened) ?? "N/A")")
                                    .font(.caption.bold())
                            }
                            Text("~ \(String(format: "%.0f", warning.distance_from_route ?? 0))m from route")
                                .font(.caption)
                                .padding(.leading, 26)
                            if let details = warning.details, !details.isEmpty {
                                Text("Note: \(details)")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                                    .padding(.leading, 26)
                            }
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
