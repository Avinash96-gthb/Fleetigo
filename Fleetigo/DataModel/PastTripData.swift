//
//  for.swift
//  Fleetigo
//
//  Created by Avinash on 09/05/25.
//


// PastTripDisplayItem.swift (New struct for the list)
import Foundation
import CoreLocation // For CLLocationCoordinate2D if you want to pass coords

struct PastTripDisplayItem: Identifiable, Hashable {
    let id: UUID // This will be the Trip's ID (PK from trips table)
    let consignmentDisplayId: String // e.g., "FLT123" from consignments table
    let consignmentType: ConsignmentType // From consignments table
    let dropLocation: String // From trips table
    let endTime: Date?       // From trips table (actual completion time)
    let status: String       // From trips table (e.g., "completed", "cancelled")

    // Optional: For navigation to a detail view that might need more
    let originalTrip: Trip // Keep the original trip object for full details
    // let originalConsignment: Consignment? // Optionally fetch and store this too

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PastTripDisplayItem, rhs: PastTripDisplayItem) -> Bool {
        lhs.id == rhs.id
    }
}

// Make sure your ConsignmentType enum is accessible
// enum ConsignmentType: String, CaseIterable, Codable { ... }
// And your Trip struct is defined as before
// struct Trip: Codable, Identifiable { ... }
