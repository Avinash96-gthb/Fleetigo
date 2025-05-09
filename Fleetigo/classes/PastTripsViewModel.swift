//
//  PastTripsViewModel.swift
//  Fleetigo
//
//  Created by UTKARSH NAYAN on 09/05/25.
//


//
//  PastTripsViewModel.swift
//  Fleetigo
//
//  Created by Avinash on 09/05/25.
//


// PastTripsViewModel.swift
import SwiftUI
import Combine

@MainActor
class PastTripsViewModel: ObservableObject {
    @Published var pastTripItems: [PastTripDisplayItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabaseManager = SupabaseManager.shared

    func fetchPastTripsForDriver(driverId: UUID?) async {
        guard let driverId = driverId else {
            print("PastTripsViewModel: Driver ID is nil, cannot fetch past trips.")
            self.errorMessage = "Driver information not available."
            self.pastTripItems = []
            return
        }

        print("PastTripsViewModel: Fetching past trips for driver \(driverId)...")
        isLoading = true
        errorMessage = nil

        do {
            let fetchedTrips = try await supabaseManager.fetchPastTrips(forDriverID: driverId)
            print("PastTripsViewModel: Fetched \(fetchedTrips.count) raw past trips.")

            var displayItems: [PastTripDisplayItem] = []

            // For each trip, fetch its consignment to get displayId and type
            for trip in fetchedTrips {
                // Fetch the associated consignment
                // This can be slow if done one by one. Consider optimizing if many trips.
                if let consignment = try? await supabaseManager.fetchConsignment(byID: trip.consignmentId) {
                    let displayItem = PastTripDisplayItem(
                        id: trip.id!, // Assuming trip.id is the PK and non-nil for fetched trips
                        consignmentDisplayId: consignment.id, // This is the FLT123 style ID
                        consignmentType: consignment.type,
                        dropLocation: trip.dropLocation,
                        endTime: trip.endTime,
                        status: trip.status,
                        originalTrip: trip
                        // originalConsignment: consignment // Optionally store
                    )
                    displayItems.append(displayItem)
                } else {
                    print("PastTripsViewModel: Could not fetch consignment details for trip \(trip.id?.uuidString ?? "N/A") (consignment ID: \(trip.consignmentId)). Skipping this past trip.")
                }
            }
            
            self.pastTripItems = displayItems
            print("PastTripsViewModel: Processed \(displayItems.count) past trip display items.")

        } catch {
            print("PastTripsViewModel: Error fetching past trips: \(error)")
            errorMessage = "Failed to load past trips: \(error.localizedDescription)"
        }
        isLoading = false
    }
}