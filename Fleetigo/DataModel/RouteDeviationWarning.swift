//
//  RouteDeviationWarning.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//
import Foundation
import CoreLocation

struct RouteDeviationWarning: Codable, Identifiable {
    var id: UUID? // Changed to UUID
    var trip_id: UUID
    var driver_id: UUID?
    var consignment_id: UUID?
    var deviation_latitude: Double
    var deviation_longitude: Double
    var optimal_route_point_latitude: Double?
    var optimal_route_point_longitude: Double?
    var distance_from_route: Double?
    var timestamp: Date?
    var acknowledged_by_admin_at: Date?
    var acknowledged_by_driver_at: Date?
    var details: String?
    
    var displayTimestamp: String {
           guard let ts = timestamp else { return "Time unknown" }
           let formatter = DateFormatter()
           formatter.dateStyle = .medium
           formatter.timeStyle = .short
           return formatter.string(from: ts)
       }
       
       // Conformance to Hashable for ForEach if id is optional before DB save
       func hash(into hasher: inout Hasher) {
           hasher.combine(id ?? UUID()) // Use a generated UUID if id is nil for hashing
       }

       static func == (lhs: RouteDeviationWarning, rhs: RouteDeviationWarning) -> Bool {
           lhs.id == rhs.id
       }

    // CodingKeys matching the table
    enum CodingKeys: String, CodingKey {
        case id
        case trip_id
        case driver_id
        case consignment_id
        case deviation_latitude
        case deviation_longitude
        case optimal_route_point_latitude
        case optimal_route_point_longitude
        case distance_from_route
        case timestamp
        case acknowledged_by_admin_at
        case acknowledged_by_driver_at
        case details
    }
}
