//
//  RouteCalculator.swift
//  Fleetigo
//
//  Created by Avinash on 09/05/25.
//
import SwiftUI
import MapKit

class RouteCalculator2: ObservableObject {
    @Published var pickupCoordinate: CLLocationCoordinate2D?
    @Published var dropCoordinate: CLLocationCoordinate2D?
    @Published var allRoutes: [MKRoute]?
    @Published var shortestRoute: MKRoute? // Could be based on distance or time

    private let geocoder = CLGeocoder()

    // Calculates route using pre-geocoded coordinates
    func calculateRoute(from pickupCoord: CLLocationCoordinate2D, to dropCoord: CLLocationCoordinate2D, completion: @escaping (MKRoute?) -> Void) {
        self.pickupCoordinate = pickupCoord
        self.dropCoordinate = dropCoord

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickupCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dropCoord))
        request.transportType = .automobile
        request.requestsAlternateRoutes = false // Usually want the primary

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                if let route = response?.routes.first, error == nil {
                    self.allRoutes = response?.routes
                    self.shortestRoute = route // Assuming first route is shortest or primary
                    completion(route)
                } else {
                    print("RouteCalculator: Failed to calculate route from coordinates: \(error?.localizedDescription ?? "Unknown error")")
                    self.allRoutes = nil
                    self.shortestRoute = nil
                    completion(nil)
                }
            }
        }
    }

    // Geocodes addresses and then calculates routes (more complex to manage async)
    func geocodeAndCalculateRoute(from pickupAddr: String, to dropAddr: String, completion: @escaping (MKRoute?) -> Void) {
        var tempPickupCoord: CLLocationCoordinate2D?
        var tempDropCoord: CLLocationCoordinate2D?
        
        let group = DispatchGroup()

        group.enter()
        geocodeAddressString(pickupAddr) { coordinate in
            tempPickupCoord = coordinate
            group.leave()
        }

        group.enter()
        geocodeAddressString(dropAddr) { coordinate in
            tempDropCoord = coordinate
            group.leave()
        }
        
        group.notify(queue: .main) {
            guard let pCoord = tempPickupCoord, let dCoord = tempDropCoord else {
                print("RouteCalculator: Cannot calculate route, geocoding failed for one or both addresses.")
                completion(nil)
                return
            }
            self.calculateRoute(from: pCoord, to: dCoord, completion: completion)
        }
    }
    
    func geocodeAddressString(_ addressString: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        geocoder.geocodeAddressString(addressString) { placemarks, error in
            if let error = error {
                print("Geocoding error for '\(addressString)': \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let coordinate = placemarks?.first?.location?.coordinate else {
                print("No coordinate found for address: \(addressString)")
                completion(nil)
                return
            }
            print("Geocoded '\(addressString)' to: \(coordinate.latitude), \(coordinate.longitude)")
            completion(coordinate)
        }
    }
}
