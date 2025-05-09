// LiveTrackingMapView.swift
import SwiftUI
import MapKit
import CoreLocation

// --- CLLocationCoordinate2D Equatable Extension ---
extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}


enum AnnotationType {
    case pickup, dropoff, driver
}

struct LiveTrackingMapView: View {
    // Input Properties
    let pickupCoordinate: CLLocationCoordinate2D?
    let dropCoordinate: CLLocationCoordinate2D?
    @Binding var driverCurrentLocation: CLLocationCoordinate2D?
    let optimalRoute: MKRoute?
    @Binding var driverPathHistory: [CLLocationCoordinate2D]

    // Map State
    @State private var mapCameraPosition: MapCameraPosition = .automatic
    @State private var selectedAnnotationItem: IdentifiableCoordinate? = nil

    // Helper for Identifiable Annotations
    struct IdentifiableCoordinate: Identifiable {
        let id = UUID()
        let title: String
        let type: AnnotationType
        let coordinate: CLLocationCoordinate2D
    }

    private var allAnnotationItems: [IdentifiableCoordinate] {
        var items: [IdentifiableCoordinate] = []
        if let pickup = pickupCoordinate {
            items.append(IdentifiableCoordinate(title: "Pickup Location", type: .pickup, coordinate: pickup))
        }
        if let drop = dropCoordinate {
            items.append(IdentifiableCoordinate(title: "Drop-off Location", type: .dropoff, coordinate: drop))
        }
        if let driverLoc = driverCurrentLocation {
            items.append(IdentifiableCoordinate(title: "Driver's Current Location", type: .driver, coordinate: driverLoc))
        }
        return items
    }

    // MARK: - Body
    var body: some View {
        // Using a simpler approach that the compiler can better handle
        MapView2(
            mapCameraPosition: $mapCameraPosition,
            selectedAnnotationItem: $selectedAnnotationItem,
            pickupCoordinate: pickupCoordinate,
            dropCoordinate: dropCoordinate,
            driverCurrentLocation: driverCurrentLocation,
            optimalRoute: optimalRoute,
            driverPathHistory: driverPathHistory,
            allAnnotationItems: allAnnotationItems
        )
        .onAppear(perform: updateCameraPositionInitially)
        .onChange(of: driverCurrentLocation) { _, _ in
            updateCameraPosition(animated: true)
        }
        .onChange(of: optimalRoute) { _, _ in
            updateCameraPosition()
        }
        .onChange(of: driverPathHistory) { oldValue, newValue in
            if newValue.count > oldValue.count || (newValue.last != oldValue.last && newValue.count == oldValue.count) {
                updateCameraPosition(animated: true)
            }
        }
    }

    // MARK: - Annotation View Helper
    @ViewBuilder
    func annotationView(for type: AnnotationType, title: String) -> some View {
        switch type {
        case .pickup:
            Image(systemName: "shippingbox.fill")
                .font(.title2)
                .padding(8)
                .foregroundColor(.white)
                .background(Color.green)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .shadow(radius: 3)
        case .dropoff:
            Image(systemName: "house.fill")
                .font(.title2)
                .padding(8)
                .foregroundColor(.white)
                .background(Color.red)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .shadow(radius: 3)
        case .driver:
            Image(systemName: "truck.box.badge.clock.fill")
                .font(.title2)
                .padding(8)
                .foregroundColor(.white)
                .background(Color.purple)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .shadow(radius: 3)
        }
    }

    // MARK: - Camera Update Logic
    private func updateCameraPositionInitially() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            updateCameraPosition(animated: false)
        }
    }

    private func updateCameraPosition(animated: Bool = false) {
        var coordinatesToFit: [CLLocationCoordinate2D] = []
        if let pickup = pickupCoordinate { coordinatesToFit.append(pickup) }
        if let drop = dropCoordinate { coordinatesToFit.append(drop) }
        if let driverLoc = driverCurrentLocation { coordinatesToFit.append(driverLoc) }

        let targetRect: MKMapRect

        if let route = optimalRoute, !route.polyline.boundingMapRect.isNull {
            var routeRect = route.polyline.boundingMapRect
            if let driverLoc = driverCurrentLocation {
                let driverPoint = MKMapPoint(driverLoc)
                if !routeRect.contains(driverPoint) {
                    routeRect = routeRect.union(MKMapRect(origin: driverPoint, size: MKMapSize()))
                }
            }
            targetRect = routeRect
        } else if !coordinatesToFit.isEmpty {
            targetRect = MKMapRect.boundingMapRect(for: coordinatesToFit)
        } else {
            mapCameraPosition = .automatic
            return
        }
        
        guard !targetRect.isNull, targetRect.size.width > 0 || targetRect.size.height > 0 else {
            if let singleCoord = coordinatesToFit.first {
                 let region = MKCoordinateRegion(center: singleCoord, latitudinalMeters: 2000, longitudinalMeters: 2000)
                 if animated {
                     withAnimation(.smooth) {
                         mapCameraPosition = .region(region)
                     }
                 } else {
                     mapCameraPosition = .region(region)
                 }
            } else {
                 mapCameraPosition = .automatic
            }
            return
        }

        let paddedRect = targetRect.paddedBy(percent: 0.35)

        if animated {
            withAnimation(.smooth(duration: 0.7)) {
                mapCameraPosition = .rect(paddedRect)
            }
        } else {
            mapCameraPosition = .rect(paddedRect)
        }
    }
}

struct MapView2: View {
    // Bindings for map state controlled by the parent
    @Binding var mapCameraPosition: MapCameraPosition
    @Binding var selectedAnnotationItem: LiveTrackingMapView.IdentifiableCoordinate? // Use parent's IdentifiableCoordinate
    
    // Data passed from parent
    let pickupCoordinate: CLLocationCoordinate2D?
    let dropCoordinate: CLLocationCoordinate2D?
    let driverCurrentLocation: CLLocationCoordinate2D? // This is now a 'let' as the binding is from parent's @State
    let optimalRoute: MKRoute?
    let driverPathHistory: [CLLocationCoordinate2D]    // This is also now a 'let'
    let allAnnotationItems: [LiveTrackingMapView.IdentifiableCoordinate] // Use parent's IdentifiableCoordinate
    
    var body: some View {
        // ***** CORRECTED MAP INITIALIZER *****
        Map(position: $mapCameraPosition) {
        // ***** ------------------------- *****
            // Draw driver's path history (snail trail)
            if driverPathHistory.count > 1 {
                MapPolyline(coordinates: driverPathHistory)
                    .stroke(Color.orange.opacity(0.7), lineWidth: 3.0) // Use Color.orange
            }
            
            // Draw optimal route if available
            if let route = optimalRoute {
                MapPolyline(route.polyline)
                    .stroke(Color.blue.opacity(0.6), lineWidth: 5.0) // Use Color.blue
            }
            
            // Add all location markers
            ForEach(allAnnotationItems) { item in
                Annotation(item.title, coordinate: item.coordinate) {
                    // Call the annotation view helper from the parent LiveTrackingMapView
                    // This requires passing a reference or making it static/global.
                    // For simplicity, let's redefine it here or pass it.
                    // Easiest for now is to redefine or call a static version if you make one.
                    // Let's assume we call a static version or redefine.
                    // For now, I will just call a locally defined version to make it compile here.
                    MapView2.annotationViewFor(type: item.type, title: item.title) // Using a static func or local one
                        .onTapGesture {
                            selectedAnnotationItem = item
                        }
                }
            }
        }
        .mapStyle(.standard(showsTraffic: true)) // Removed pointsOfInterest for simplicity for now
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
            MapPitchToggle()
        }
    }
    
    // If you want to keep annotationView logic separate and not pass it,
    // define it within MapView2 or make it static/global.
    // This is a copy from LiveTrackingMapView for demonstration.
    @ViewBuilder
    static func annotationViewFor(type: AnnotationType, title: String) -> some View {
        // To use LiveTrackingMapView.AnnotationType, it needs to be accessible
        // or MapView2 should have its own identical AnnotationType enum.
        // Let's assume AnnotationType is defined outside or is LiveTrackingMapView.AnnotationType
        switch type {
        case .pickup:
            Image(systemName: "shippingbox.fill")
                .font(.title2).padding(8).foregroundColor(.white).background(Color.green).clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5)).shadow(radius: 3)
        case .dropoff:
            Image(systemName: "house.fill")
                .font(.title2).padding(8).foregroundColor(.white).background(Color.red).clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5)).shadow(radius: 3)
        case .driver:
            Image(systemName: "truck.box.badge.clock.fill")
                .font(.title2).padding(8).foregroundColor(.white).background(Color.purple).clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5)).shadow(radius: 3)
        }
    }
}
