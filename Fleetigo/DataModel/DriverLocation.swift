//
//  DriverLocation.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//


import Foundation
import CoreLocation

struct DriverLocation: Codable, Identifiable {
    var id: UUID? // Changed to UUID, optional before insert
    var trip_id: UUID
    var driver_id: UUID
    var latitude: Double
    var longitude: Double
    var timestamp: Date?
    var created_at: Date?

    // Initializer for creating new location records
    init(id: UUID? = nil, tripId: UUID, driverId: UUID, coordinate: CLLocationCoordinate2D, timestamp: Date = Date()) {
        self.id = id // Can be nil for new records, Supabase will generate
        self.trip_id = tripId
        self.driver_id = driverId
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case id
        case trip_id
        case driver_id
        case latitude
        case longitude
        case timestamp
        case created_at
    }
}