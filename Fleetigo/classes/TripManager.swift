//
//  TripManager.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//


import Foundation
import SwiftUI
import CoreLocation
import MapKit

class TripManager: ObservableObject {
    @Published var currentTripDetails: TripWithDetails? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let supabaseManager = SupabaseManager.shared
    private let geocoder = CLGeocoder()

    func endCurrentTrip(driverId: UUID, vehicleId: UUID) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            if let currentTripDetails = self.currentTripDetails {
                let trip = currentTripDetails.base
                let pickupLocation = trip.pickupLocation
                let dropLocation = trip.dropLocation
                let consignment = try? await supabaseManager.fetchConsignment(byID: trip.consignmentId)

                // Use MKLocalSearch instead of CLGeocoder
                async let startPlacemarks = performLocalSearch(for: pickupLocation)
                async let endPlacemarks = performLocalSearch(for: dropLocation)

                let (startPlacemarksResult, endPlacemarksResult) = await (try? startPlacemarks, try? endPlacemarks)

                if let startCoordinate = startPlacemarksResult?.placemark.coordinate,
                   let endCoordinate = endPlacemarksResult?.placemark.coordinate,
                   let consignmentWeight = consignment?.weight,
                   let weightInKg = Double(consignmentWeight) {

                    let distanceInMeters = CLLocation(latitude: startCoordinate.latitude, longitude: endCoordinate.longitude).distance(from: CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude))
                    let distanceInKilometers = distanceInMeters / 1000.0

                    // --- Hardcoded Mileage and Rates ---
                    var mileage: Double = 0.0
                    switch currentTripDetails.truckType {
                    case "HCV":
                        mileage = 5.0
                    case "MCV":
                        mileage = 7.0
                    case "LCV":
                        mileage = 9.0
                    default:
                        mileage = 0.0
                    }
                    let fuelCostPerLiter = 110.0
                    let driverCostPerKm = 7.0
                    let chargePerKgPerKm = 500.0

                    // Calculate costs and charges
                    let fuelConsumed = distanceInKilometers / mileage
                    let fuelCost = fuelConsumed * fuelCostPerLiter
                    let driverCost = distanceInKilometers * driverCostPerKm
                    let customerCharge = distanceInKilometers * weightInKg * chargePerKgPerKm

                    // Create TripRevenue struct
                    let revenueData = TripRevenue(
                        tripId: trip.id!,
                        distanceCoveredKm: distanceInKilometers,
                        fuelCost: fuelCost,
                        driverCost: driverCost,
                        customerCharge: customerCharge,
                        createdAt: nil
                    )

                    // Insert trip revenue data into Supabase
                    try await supabaseManager.insertTripRevenue(revenueData: revenueData)
                    print("Trip revenue data uploaded to Supabase.")

                    // Update vehicle status to 'available'
                    try await supabaseManager.updateVehicleStatus(vehicleId: vehicleId, newStatus: .available)
                    print("Vehicle status updated to available for ID: \(vehicleId)")

                    // Update driver status to 'Available'
                    try await supabaseManager.updateDriverStatus(driverId: driverId, newStatus: "Available")
                    print("Driver status updated to Available for ID: \(driverId)")

                    // Update consignment status to 'completed'
                    try await supabaseManager.updateConsignmentStatus(consignmentId: trip.consignmentId, newStatus: .completed)
                    print("Consignment status updated to completed for ID: \(trip.consignmentId)")

                    // Update trip status to 'completed'
                    if let tripId = trip.id {
                        try await supabaseManager.updateTripStatus(tripId: tripId, newStatus: "completed")
                        print("Trip status updated to completed for ID: \(tripId)")
                    } else {
                        print("Warning: Could not update trip status as trip ID is nil.")
                    }

                    // Clear the current trip details
                    DispatchQueue.main.async {
                        self.currentTripDetails = nil
                    }

                    print("Trip ended successfully.")

                } else {
                    var errorMessage = "Error: Could not calculate trip revenue."
                    if startPlacemarksResult == nil || endPlacemarksResult == nil {
                        errorMessage += " Could not geocode start or end locations."
                    }
                    if currentTripDetails.truckType == nil {
                        errorMessage += " Truck type is nil."
                    }
                    if consignment?.weight == nil {
                        errorMessage += " Consignment weight is nil."
                    }
                    self.errorMessage = errorMessage
                    print(errorMessage)
                }
            } else {
                self.errorMessage = "Error: No current trip details found."
                print("Error ending trip: No current trip details found.")
            }

        } catch {
            self.errorMessage = "Error ending trip: \(error.localizedDescription)"
            print("Error ending trip: \(error)")
        }
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }

    func fetchAssignedTripDetails(driverId: UUID) async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.currentTripDetails = nil
        }

        do {
            if let trip = try await supabaseManager.fetchTrip(byDriverID: driverId) {
                async let vehicleResult = supabaseManager.fetchVehicle(byID: trip.vehicleId)
                async let consignmentResult = supabaseManager.fetchConsignment(byID: trip.consignmentId)

                let (vehicle, consignment) = await (try? vehicleResult, try? consignmentResult)

                DispatchQueue.main.async {
                    if let consignment = consignment, let vehicle = vehicle {
                        self.currentTripDetails = TripWithDetails(
                            base: trip,
                            consignmentType: consignment.type,
                            departureTime: trip.startTime ?? Date(),
                            startLocation: trip.pickupLocation,
                            endLocation: trip.dropLocation,
                            startCoordinate: nil, // Initialize as nil, will be updated later
                            endCoordinate: nil,   // Initialize as nil, will be updated later
                            truckNumber: vehicle.id!,
                            truckType: vehicle.type,
                            truckModel: vehicle.model,
                            licensePlate: vehicle.licensePlateNo
                        )
                        print("Successfully fetched basic trip details.")
                        self.isLoading = false
                    } else {
                        self.errorMessage = "Failed to fetch consignment or vehicle details."
                        self.isLoading = false
                        return
                    }
                }

                // Concurrent fetching of geocodes using MKLocalSearch
                Task {
                    async let startMapItem = performLocalSearch(for: trip.pickupLocation)
                    async let endMapItem = performLocalSearch(for: trip.dropLocation)

                    let (startItem, endItem) = await (try? startMapItem, try? endMapItem)

                    let startCoordinate = startItem?.placemark.coordinate
                    let endCoordinate = endItem?.placemark.coordinate

                    DispatchQueue.main.async {
                        if var currentTripDetails = self.currentTripDetails {
                            currentTripDetails.startCoordinate = startCoordinate
                            currentTripDetails.endCoordinate = endCoordinate
                            self.currentTripDetails = currentTripDetails
                            print("Successfully fetched geocodes using MKLocalSearch (if available).")
                        }
                    }
                }

            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "No assigned trip found for this driver."
                    self.isLoading = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error fetching assigned trip: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func performLocalSearch(for query: String) async throws -> MKMapItem? {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        return response.mapItems.first
    }
    private func geocodeLocation(address: String) async -> CLLocationCoordinate2D? {
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            if let firstPlacemark = placemarks.first?.location?.coordinate {
                return firstPlacemark
            }
            return nil
        } catch {
            print("Geocoding error for \(address): \(error.localizedDescription)")
            return nil
        }
    }
}

// Update the TripWithDetails struct to reflect the Trip model
