import SwiftUI
import MapKit

// Model for past trip data
struct PastTripData: Identifiable {
    let id = UUID()
    let consignmentID: String
    let consignmentType: ConsignmentType
    let date: Date
    
    
    enum ConsignmentType: String {
        case priority = "Priority"
        case medium = "Medium"
        case standard = "Standard"
    }
}



struct PastTripsView: View {
    let driverId: UUID? // Passed from TripCardView's TabView item
    @StateObject private var viewModel = PastTripsViewModel()

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
                
                VStack(alignment: .leading) {
                    Text("Past Trips")
                        .font(.largeTitle.bold())
                        .padding([.horizontal, .top])
                        .padding(.bottom, 8) // Add some space below title
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading Past Trips...")
                        Spacer()
                    } else if let errorMessage = viewModel.errorMessage {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(errorMessage)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                Task { await viewModel.fetchPastTripsForDriver(driverId: driverId) }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        Spacer()
                    } else if viewModel.pastTripItems.isEmpty {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 50))
                                .foregroundColor(.gray.opacity(0.7))
                            Text("No past trips available.")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    } else {
                        List { // Use List for better performance and standard row appearance
                            ForEach(viewModel.pastTripItems) { tripItem in
                                PastTripCardView(tripItem: tripItem) // Pass PastTripDisplayItem
                                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0)) // Adjust insets
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(.plain) // Remove default List styling
                        .refreshable { // Add pull-to-refresh
                            await viewModel.fetchPastTripsForDriver(driverId: driverId)
                        }
                    }
                }
            }
            .navigationBarHidden(true) // Keep if you have custom header
            // Or use .navigationTitle("Past Trips") if header text is removed
            .onAppear {
                // Fetch only if list is empty and not already loading
                if viewModel.pastTripItems.isEmpty && !viewModel.isLoading {
                    Task {
                        await viewModel.fetchPastTripsForDriver(driverId: driverId)
                    }
                }
            }
        }
    }
}

struct PastTripCardView: View {
    let tripItem: PastTripDisplayItem // Changed from PastTripData

    var body: some View {
        // NavigationLink now to PastTripDetailView, passing the original Trip and potentially Consignment
        NavigationLink(destination: PastTripDetailView(trip: tripItem.originalTrip)) { // Pass original trip
            HStack(spacing: 12) { // Added spacing
                getPriorityIcon(for: tripItem.consignmentType) // Use new enum
                    .font(.title2) // Apply font here for consistency
                    .frame(width: 30, alignment: .center) // Smaller frame for icon

                VStack(alignment: .leading, spacing: 5) { // Adjusted spacing
                    Text("Consignment: \(tripItem.consignmentDisplayId)")
                        .font(.headline)
                        .foregroundColor(Color(UIColor.label)) // Adapts to light/dark
                        .lineLimit(1)

                    HStack {
                        Text("To:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(tripItem.dropLocation)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(Color(UIColor.secondaryLabel))
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Text(tripItem.endTime?.formatted(date: .abbreviated, time: .shortened) ?? "Date N/A")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(tripItem.status.capitalized)
                            .font(.caption.bold())
                            .foregroundColor(statusColor(for: tripItem.status))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(statusColor(for: tripItem.status).opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray.opacity(0.7))
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground)) // Adapts to light/dark
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 1) // Softer shadow
        }
    }
    
    // Use the ConsignmentType from your main data model
    @ViewBuilder
    private func getPriorityIcon(for type: ConsignmentType) -> some View {
        switch type {
        case .priority:
            Image(systemName: "bolt.fill").foregroundColor(.orange) // Changed icon
        case .medium:
            Image(systemName: "arrow.up.arrow.down.circle.fill").foregroundColor(.blue) // Changed icon
        case .standard:
            Image(systemName: "circle.fill").foregroundColor(.gray) // Changed icon
        }
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "completed": return .green
        case "cancelled": return .red
        case "ended_manually": return .orange
        default: return .gray
        }
    }
}



struct PastTripDetailView: View {
    let trip: Trip // Now receives the full Trip object

    // State for fetched related data
    @State private var consignment: Consignment?
    @State private var vehicle: Vehicle?
    @State private var isLoadingDetails: Bool = true
    @State private var errorMessage: String?

    // Map related state
    @State private var pickupGeoCoordinate: CLLocationCoordinate2D?
    @State private var dropGeoCoordinate: CLLocationCoordinate2D?
    @State private var optimalRouteToDisplay: MKRoute?
    @StateObject private var routeCalculator = RouteCalculator2() // Assuming RouteCalculator is defined

    var body: some View {
        ScrollView {
            if isLoadingDetails {
                ProgressView("Loading Trip Details...")
                    .padding(.top, 50)
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if let cons = consignment, let veh = vehicle {
                VStack(alignment: .leading, spacing: 20) {
                    // Map Section (uses pickup/drop from Trip object)
                    mapSection
                    
                    // Consignment Info Section
                    DetailSection(title: "Consignment: \(cons.id)") {
                        VStack(alignment: .leading, spacing: 10) {
                            DetailRow(label: "Status", value: cons.status.rawValue.capitalized)
                            DetailRow(label: "Type", value: cons.type.rawValue.capitalized)
                            DetailRow(label: "Description", value: cons.description)
                            DetailRow(label: "Weight", value: "\(cons.weight) kg")
                        }
                    }
                    
                    // Trip Info Section
                    DetailSection(title: "Trip Details") {
                        VStack(alignment: .leading, spacing: 10) {
                            DetailRow(label: "Trip Status", value: trip.status.capitalized)
                            DetailRow(label: "Started", value: trip.startTime?.formatted(date: .abbreviated, time: .shortened) ?? "N/A")
                            DetailRow(label: "Ended", value: trip.endTime?.formatted(date: .abbreviated, time: .shortened) ?? "N/A")
                            DetailRow(label: "Pickup", value: trip.pickupLocation)
                            DetailRow(label: "Drop-off", value: trip.dropLocation)
                            DetailRow(label: "Notes", value: trip.notes ?? "None")
                        }
                    }

                    // Vehicle Info Section
                    DetailSection(title: "Vehicle Used: \(veh.licensePlateNo)") {
                        VStack(alignment: .leading, spacing: 10) {
                            DetailRow(label: "Model", value: veh.model)
                            DetailRow(label: "Type", value: veh.type)
                        }
                    }
                    // Add more sections as needed (e.g., Revenue, Issues reported during trip)
                }
                .padding()
            } else {
                Text("Could not load complete trip details.")
                    .foregroundColor(.orange)
            }
        }
        .navigationTitle("Past Trip: \(consignment?.id ?? String(trip.id?.uuidString.prefix(8) ?? "Details"))")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            Task {
                await fetchAssociatedDetails()
            }
        }
    }

    private func fetchAssociatedDetails() async {
        isLoadingDetails = true
        errorMessage = nil
        do {
            async let consFetch = SupabaseManager.shared.fetchConsignment(byID: trip.consignmentId)
            async let vehFetch = SupabaseManager.shared.fetchVehicle(byID: trip.vehicleId)

            self.consignment = try await consFetch
            self.vehicle = try await vehFetch
            
            print("PastTripDetailView: Fetched Consignment: \(self.consignment != nil), Vehicle: \(self.vehicle != nil)")

            // After fetching consignment, geocode its locations for the map
            if let cons = self.consignment {
                await geocodeAddressesAndCalcRoute(pickupAddr: cons.pickup_location, dropAddr: cons.drop_location)
            } else {
                 print("PastTripDetailView: Consignment details missing, cannot geocode or calculate route.")
            }

        } catch {
            print("PastTripDetailView: Error fetching associated details: \(error)")
            self.errorMessage = error.localizedDescription
        }
        isLoadingDetails = false
    }

    private func geocodeAddressesAndCalcRoute(pickupAddr: String, dropAddr: String) async {
        // Geocode
        self.pickupGeoCoordinate = await performGeocoding(for: pickupAddr)
        self.dropGeoCoordinate = await performGeocoding(for: dropAddr)

        // Calculate route if coordinates are available
        if let pCoord = self.pickupGeoCoordinate, let dCoord = self.dropGeoCoordinate {
            routeCalculator.calculateRoute(from: pCoord, to: dCoord) { route in
                DispatchQueue.main.async { self.optimalRouteToDisplay = route }
            }
        }
    }

    private func performGeocoding(for addressString: String) async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { continuation in
            routeCalculator.geocodeAddressString(addressString) { coordinate in
                continuation.resume(returning: coordinate)
            }
        }
    }

    // Map Section
    @ViewBuilder
    private var mapSection: some View {
        DetailSection(title: "Trip Route") {
            Group { // Use Group for conditional content
                if isLoadingDetails && optimalRouteToDisplay == nil && pickupGeoCoordinate == nil {
                    ProgressView("Loading map...")
                        .frame(height: 250, alignment: .center)
                } else if let pCoord = pickupGeoCoordinate, let dCoord = dropGeoCoordinate {
                    // Using a simplified map here, can replace with LiveTrackingMapView if needed
                    // For past trips, live driver location isn't relevant.
                    Map {
                        Marker("Pickup: \(trip.pickupLocation)", coordinate: pCoord).tint(.green)
                        Marker("Drop-off: \(trip.dropLocation)", coordinate: dCoord).tint(.red)
                        if let route = optimalRouteToDisplay {
                            MapPolyline(route.polyline).stroke(Color.blue, lineWidth: 5)
                        }
                    }
                    .frame(height: 250)
                    .cornerRadius(10)
                    .onAppear { // Set camera for the map
                        let mapRect = MKMapRect.boundingMapRect(for: [pCoord, dCoord])
                        // How to set MapCameraPosition for this simpler Map?
                        // This basic Map doesn't directly take MapCameraPosition binding like Map(position: $...).
                        // For more control, you'd use the more complex Map from LiveTrackingMapView or TripMapView
                        // For now, it will auto-fit.
                    }
                } else {
                    Text("Map data unavailable (locations could not be geocoded).")
                        .foregroundColor(.orange)
                        .padding()
                        .frame(height: 250, alignment: .center)
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
