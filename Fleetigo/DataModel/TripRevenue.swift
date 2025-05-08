//
//  TripRevenue.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//


import Foundation

struct TripRevenue: Codable {
    let tripId: UUID?
    let distanceCoveredKm: Double?
    let fuelCost: Double?
    let driverCost: Double?
    let customerCharge: Double?
    let createdAt: Date? // Added created_at
    
    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case distanceCoveredKm = "distance_covered_km"
        case fuelCost = "fuel_cost"
        case driverCost = "driver_cost"
        case customerCharge = "customer_charge"
        case createdAt = "created_at"
    }
}
