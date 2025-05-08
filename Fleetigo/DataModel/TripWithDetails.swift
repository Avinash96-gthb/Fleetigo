//
//  TripWithDetails.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//

import Foundation
import CoreLocation
import MapKit



struct TripWithDetails {
    let base: Trip
    let consignmentType: ConsignmentType
    let departureTime: Date
    let startLocation: String
    let endLocation: String
    var startCoordinate: CLLocationCoordinate2D? // Make optional as geocoding can fail
    var endCoordinate: CLLocationCoordinate2D?   // Make optional as geocoding can fail
    let truckNumber: UUID
    let truckType: String // Changed to String
    let truckModel: String
    let licensePlate: String
}
