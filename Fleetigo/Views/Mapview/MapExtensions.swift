import MapKit

extension MKPlacemark {
    var formattedAddress: String? {
        guard let addressDictionary = addressDictionary as? [String: Any] else { return nil }
        let street = addressDictionary["Street"] as? String ?? ""
        let city = addressDictionary["City"] as? String ?? ""
        let state = addressDictionary["State"] as? String ?? ""
        let postalCode = addressDictionary["ZIP"] as? String ?? ""
        let country = addressDictionary["Country"] as? String ?? ""
        
        let components = [street, city, state, postalCode, country].filter { !$0.isEmpty }
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else {
            self.init(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
            return
        }
        
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }
        let minLat = latitudes.min()!
        let maxLat = latitudes.max()!
        let minLon = longitudes.min()!
        let maxLon = longitudes.max()!
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )
        
        self.init(center: center, span: span)
    }
    
    func expanded(by factor: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta * factor,
                longitudeDelta: span.longitudeDelta * factor
            )
        )
    }
}
