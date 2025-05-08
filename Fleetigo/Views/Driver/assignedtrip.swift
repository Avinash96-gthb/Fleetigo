import SwiftUI
import MapKit

// MARK: - Profile Section
struct ProfileSectionView: View {
    @ObservedObject var profileViewModel: ProfileViewModel

    var body: some View {
        if profileViewModel.isLoading {
            Text("Loading Profile...")
        } else if let role = profileViewModel.userRole {
            NavigationLink(destination: ProfileView()) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Hello")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#333333"))
                        
                        Text(displayName(for: role))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#4E8FFF"))
                    }
                    .padding(.leading, 5)

                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 0)
            }
        } else if let error = profileViewModel.errorMessage {
            Text("Error: \(error)")
        } else {
            Text("Profile not available.")
        }
    }

    private func displayName(for role: UserRole) -> String {
        switch role {
        case .admin:
            return profileViewModel.adminProfile?.full_name ?? "Admin"
        case .driver: 
            return profileViewModel.driverProfile?.name ?? "Driver"
        case .technician:
            return profileViewModel.technicianProfile?.name ?? "Technician"
        }
    }
}

struct PriorityIndicator: View {
    let priority: ConsignmentType

    var body: some View {
        HStack(spacing: 2) {
            switch priority {
            case .priority:
                Image(systemName: "arrow.up.2")
                    .foregroundColor(.red)
            case .medium:
                Image(systemName: "equal")
                    .foregroundColor(.yellow)
            case .standard:
                Image(systemName: "arrow.down")
                    .foregroundColor(.blue)
            }
            Text(priority.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(priorityColor(for: priority))
        }
        .font(.system(size: 12))
    }

    func priorityColor(for type: ConsignmentType) -> Color {
        switch type {
        case .priority:
            return .red
        case .medium:
            return .yellow
        case .standard:
            return .blue
        }
    }
}



// MARK: - Consignment Info Section
struct ConsignmentInfoView: View {
    let consignmentId: String
    let consignmentType: ConsignmentType // Assuming you have this enum
    let departureTime: Date // Or whatever the date/time field is in your Trip model

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy , h:mm a" // Adjust format as needed
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                HStack(spacing: 8) {
                    PriorityIndicator(priority: consignmentType) // Assuming you have this view
                    Text(consignmentId)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                Spacer()
                Text(dateFormatter.string(from: departureTime))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#767676"))
            }
            HStack(spacing: 2) {
                Text("Consignment Type : ")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "#767676"))
                Text(consignmentType.rawValue.capitalized) // Assuming ConsignmentType is an enum with RawRepresentable
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "#767676"))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)

        Divider()
            .padding(.vertical, 3)
    }
}


// MARK: - Trip Details Section
struct TripDetailsSectionView: View {
    let startLocation: String
    let endLocation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Trip Details")
                .font(.headline)
                .padding(.bottom, 8)
                .padding(.top, 12)

            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 12, height: 12)
                Text(startLocation)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                Spacer()
            }

            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 10)
                    .padding(.leading, 5.5)
                Spacer()
            }

            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                Text(endLocation)
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}



struct TripCardView: View {
    @EnvironmentObject var tripManager: TripManager
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var navigateToChecklist = false // State to trigger navigation

    var body: some View {
        TabView {
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

                    ScrollView {
                        VStack(spacing: 20) {
                            Color.clear.frame(height: 10)

                            ProfileSectionView(profileViewModel: profileViewModel)

                            if tripManager.isLoading {
                                Text("Loading Trip Details...")
                            } else if let currentTripDetails = tripManager.currentTripDetails {
                                VStack(spacing: 0) {
                                    if let startCoordinate = currentTripDetails.startCoordinate, let endCoordinate = currentTripDetails.endCoordinate {
                                        MapView(startCoordinate: startCoordinate, endCoordinate: endCoordinate)
                                            .frame(height: 190)
                                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                                    } else {
                                        Text("Could not load map coordinates.") // More specific error message
                                            .foregroundColor(.red)
                                            .padding()
                                    }
                                    Divider()
                                        .padding(.vertical, 3)

                                    ConsignmentInfoView(
                                        consignmentId: currentTripDetails.base.consignmentId.uuidString.uppercased(),
                                        consignmentType: currentTripDetails.consignmentType,
                                        departureTime: currentTripDetails.departureTime
                                    )

                                    TruckDetailsView(truckDetails: currentTripDetails)

                                    TripDetailsSectionView(startLocation: currentTripDetails.startLocation, endLocation: currentTripDetails.endLocation)

                                    Spacer(minLength: 20)

                                    // --- Replace NextButtonView with this NavigationLink ---
                                    NavigationLink(
                                        destination: PreTripChecklistView( // Pass the coordinates here
                                            startCoordinate: currentTripDetails.startCoordinate,
                                            endCoordinate: currentTripDetails.endCoordinate,
                                            consignmentId: currentTripDetails.base.consignmentId, vehichleId: currentTripDetails.truckNumber, driverId: currentTripDetails.base.driverId
                                        )
                                    ) {
                                        Text("Next")
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color(hex: "#4E8FFF"))
                                            .cornerRadius(12)
                                            .padding(.horizontal) // Add padding to the button itself
                                    }
                                    // No need for `.isActive` here as it's a visible button link

                                }
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.28), radius: 20, x: 0, y: -1)
                                .padding(.horizontal) // Padding around the white card background
                            } else if let errorMessage = tripManager.errorMessage {
                                Text("Error: \(errorMessage)")
                                    .foregroundColor(.red)
                                    .padding()
                            } else if profileViewModel.userRole == .driver {
                                VStack() {
                                    Image("truck")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 20)

                                    Text("No assigned trip found.")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                        .padding()
                                }
                                .padding(.bottom, 100)
                            }
                        }
                        // .padding(.bottom, 100) // Removed this outer padding, moved bottom padding to card
                    }
                }
                .onAppear {
                    if profileViewModel.userRole == .driver, let driverId = profileViewModel.driverProfile?.id {
                        Task {
                            await tripManager.fetchAssignedTripDetails(driverId: driverId)
                        }
                    }
                }
            }
            .tabItem {
                Label("Assigned Trip", systemImage: "truck.box")
            }

            PastTripsView() // Assuming this view exists
                .tabItem {
                    Label("Past Trips", systemImage: "clock.arrow.circlepath")
                }
        }
        .accentColor(Color(hex: "#4E8FFF"))
    }
}



// MARK: - Updated TruckDetailsView
struct TruckDetailsView: View {
    let truckDetails: TripWithDetails

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Truck Details")
                    .font(.headline)
                Spacer()
                if let startCoordinate = truckDetails.startCoordinate, let endCoordinate = truckDetails.endCoordinate {
                    NavigationLink(destination: TripDetailsView(
                        startLocation: truckDetails.startLocation,
                        endLocation: truckDetails.endLocation,
                        startCoordinate: startCoordinate,
                        endCoordinate: endCoordinate
                    )) {
                        HStack(spacing: 4) {
                            Text("Details")
                                .foregroundColor(Color(hex: "#4E8FFF"))
                                .font(.subheadline)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#4E8FFF"))
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 8)

            HStack(alignment: .top, spacing: 18) {
                Image(systemName: "truck.box")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 75, height: 70)
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(truckDetails.truckNumber.uuidString)
                        .fontWeight(.semibold)
                    HStack {
                        Text("Type:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "#767676"))
                        Text(truckDetails.truckType)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#333333"))
                    }
                    .font(.subheadline)
                    HStack {
                        Text("Model:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(hex: "#767676"))
                        Text(truckDetails.truckModel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#333333"))
                    }
                    .font(.subheadline)
                    Text("License Plate: \(truckDetails.licensePlate)")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "#767676"))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            Divider()
                .padding(.vertical, 3)
        }
    }
}

// MARK: - Updated TripDetailsView to handle optional coordinates
struct TripDetailsView: View {
    let startLocation: String
    let endLocation: String
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
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Trip Details")
                            .font(.title)
                            .fontWeight(.bold)

                        Section(header: Text("Start Location").font(.headline)) {
                            Text(startLocation)
                            if let coordinate = startCoordinate {
                                Text("Latitude: \(coordinate.latitude), Longitude: \(coordinate.longitude)")
                            } else {
                                Text("Coordinates not available.")
                                    .foregroundColor(.red)
                            }
                        }

                        Section(header: Text("End Location").font(.headline)) {
                            Text(endLocation)
                            if let coordinate = endCoordinate {
                                Text("Latitude: \(coordinate.latitude), Longitude: \(coordinate.longitude)")
                            } else {
                                Text("Coordinates not available.")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Trip Details")
        }
    }
}

// MARK: - Updated MapView to handle optional coordinates
struct MapView: UIViewRepresentable {
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)

        if let start = startCoordinate, let end = endCoordinate {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "Start"

            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end
            endAnnotation.title = "End"

            uiView.addAnnotations([startAnnotation, endAnnotation])

            let points = [start, end]
            let polyline = MKPolyline(coordinates: points, count: points.count)
            uiView.addOverlay(polyline)

            let centerCoordinate = CLLocationCoordinate2D(
                latitude: (start.latitude + end.latitude) / 2,
                longitude: (start.longitude + end.longitude) / 2
            )

            let span = MKCoordinateSpan(
                latitudeDelta: abs(start.latitude - end.latitude) * 1.5,
                longitudeDelta: abs(start.longitude - end.longitude) * 1.5
            )

            let region = MKCoordinateRegion(center: centerCoordinate, span: span)
            uiView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

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
            let identifier = "LocationPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            if annotation.title == "Start" {
                (annotationView as? MKMarkerAnnotationView)?.markerTintColor = .green
            } else {
                (annotationView as? MKMarkerAnnotationView)?.markerTintColor = .red
            }

            return annotationView
        }
    }
}
