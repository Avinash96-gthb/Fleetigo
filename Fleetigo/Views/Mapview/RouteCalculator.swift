//
//  RouteCalculator.swift
//  FleetigoConsignment
//
//  Created by user@22 on 29/04/25.
//


import Foundation
import MapKit

class RouteCalculator: ObservableObject {
    @Published var pickupCoordinate: CLLocationCoordinate2D?
    @Published var dropCoordinate: CLLocationCoordinate2D?
    @Published var allRoutes: [MKRoute]?
    @Published var shortestRoute: MKRoute?
    
    func calculateRoutes(from pickupAddress: String, to dropAddress: String, completion: @escaping (MKCoordinateRegion?) -> Void) {
        let geocoder = CLGeocoder()
        
        // Geocode pickup address
        geocoder.geocodeAddressString(pickupAddress) { placemarks, error in
            guard let pickupPlacemark = placemarks?.first, let pickupLocation = pickupPlacemark.location else {
                print("Failed to geocode pickup address: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            self.pickupCoordinate = pickupLocation.coordinate
            
            // Geocode drop address
            geocoder.geocodeAddressString(dropAddress) { placemarks, error in
                guard let dropPlacemark = placemarks?.first, let dropLocation = dropPlacemark.location else {
                    print("Failed to geocode drop address: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self.dropCoordinate = dropLocation.coordinate
                
                // Calculate routes
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickupLocation.coordinate))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dropLocation.coordinate))
                request.transportType = .automobile
                request.requestsAlternateRoutes = true
                
                let directions = MKDirections(request: request)
                directions.calculate { response, error in
                    guard let response = response, !response.routes.isEmpty else {
                        print("Failed to calculate routes: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    self.allRoutes = response.routes
                    self.shortestRoute = response.routes.sorted(by: { $0.distance < $1.distance }).first
                    
                    // Set map region to encompass both routes
                    let coordinates = [pickupLocation.coordinate, dropLocation.coordinate]
                    let rect = MKCoordinateRegion(coordinates: coordinates).expanded(by: 1.5)
                    completion(rect)
                }
            }
        }
    }
}