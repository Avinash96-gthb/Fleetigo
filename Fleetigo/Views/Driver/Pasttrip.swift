
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
    // Sample data - in a real app, this would come from a database or API
    @State private var pastTrips: [PastTripData] = [
        PastTripData(consignmentID: "CID-100234", consignmentType: .priority, date: Date()),
        PastTripData(consignmentID: "CID-100234", consignmentType: .medium, date: Date().addingTimeInterval(-86400)),
        PastTripData(consignmentID: "CID-100234", consignmentType: .standard, date: Date().addingTimeInterval(-172800)),
        PastTripData(consignmentID: "CID-100234", consignmentType: .priority, date: Date().addingTimeInterval(-259200)),
        PastTripData(consignmentID: "CID-100234", consignmentType: .priority, date: Date().addingTimeInterval(-345600))
    ]
    
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
                .ignoresSafeArea(edges: .top) // Limit to top only
                
                VStack(alignment: .leading) {
                    Text("Past Trips")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if pastTrips.isEmpty {
                        VStack {
                            Spacer()
                            Text("No past trips available.")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(pastTrips) { trip in
                                    PastTripCardView(trip: trip)
                                }
                                
                                // Add some extra space at the bottom
                                Spacer().frame(height: 20)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct PastTripCardView: View {
    let trip: PastTripData
    
    var body: some View {
        NavigationLink(destination: PastTripDetailView(trip: trip)) {
            HStack {
                // Icon based on consignment type
                getPriorityIcon(for: trip.consignmentType)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.consignmentID)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    HStack {
                        Text("Consignment Type")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(":")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(trip.consignmentType.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 8)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.25), radius: 2, x: 0, y: 1)
        }
    }
    
    @ViewBuilder
    private func getPriorityIcon(for type: PastTripData.ConsignmentType) -> some View {
        switch type {
        case .priority:
            Image(systemName: "chevron.up")
                .font(.title2)
                .foregroundColor(.red)
        case .medium:
            Image(systemName: "equal")
                .font(.title2)
                .foregroundColor(.orange)
        case .standard:
            Image(systemName: "chevron.down")
                .font(.title2)
                .foregroundColor(.blue)
        }
    }
}

// Trip details view for past trips
struct PastTripDetailView: View {
    let trip: PastTripData
    
    // Sample coordinates (would be stored with the actual trip data)
    let startCoordinate = CLLocationCoordinate2D(latitude: 28.7041, longitude: 77.1025) // Delhi
    let endCoordinate = CLLocationCoordinate2D(latitude: 13.0827, longitude: 80.2707) // Chennai
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Map view similar to active trip
                MapView(startCoordinate: startCoordinate, endCoordinate: endCoordinate)
                    .frame(height: 220)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
                
                // Trip info section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Consignment ID:")
                            .fontWeight(.medium)
                        Text(trip.consignmentID)
                    }
                    
                    HStack {
                        Text("Type:")
                            .fontWeight(.medium)
                        Text(trip.consignmentType.rawValue)
                    }
                    
                    HStack {
                        Text("Date:")
                            .fontWeight(.medium)
                        Text(formattedDate(trip.date))
                    }
                    
                    // Add more trip details as needed
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    Text("Location Details")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    HStack(alignment: .top, spacing: 12) {
                        VStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1, height: 30)
                        }
                        Text("Rohini, Delhi")
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        Text("Raja Muthai Salai, Chennai")
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Past Trip Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#B4CFFF").opacity(0.5), location: 0.0),
                    .init(color: Color(hex: "#B4CFFF").opacity(0.3), location: 0.1),
                    .init(color: Color(hex: "#B4CFFF").opacity(0.1), location: 0.3),
                    .init(color: .clear, location: 0.4)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PastTripsView_Previews: PreviewProvider {
    static var previews: some View {
        PastTripsView()
    }
}
