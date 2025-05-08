//
//  RouteMapView.swift
//  FleetigoConsignment
//
//  Created by user@22 on 29/04/25.
//


import SwiftUI
import MapKit

struct RouteMapView: View {
    @Binding var pickupAddress: String
    @Binding var dropAddress: String
    @StateObject private var routeCalculator = RouteCalculator()
    @State private var selectedRoute: RouteType = .full
    @State private var position: MapCameraPosition = .automatic
    
    enum RouteType: String, CaseIterable, Identifiable {
        case full = "Full Route"
        case shortest = "Shortest Route"
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $position) {
                    if let pickupCoord = routeCalculator.pickupCoordinate {
                        Marker("Pickup", systemImage: "circle.fill", coordinate: pickupCoord)
                            .tint(.green)
                    }
                    if let dropCoord = routeCalculator.dropCoordinate {
                        Marker("Drop", systemImage: "circle.fill", coordinate: dropCoord)
                            .tint(.red)
                    }
                    if selectedRoute == .full, let routes = routeCalculator.allRoutes {
                        ForEach(Array(routes.enumerated()), id: \.offset) { index, route in
                            MapPolyline(route)
                                .stroke(
                                    index == 0 ? Color.blue : Color.blue.opacity(0.5),
                                    lineWidth: index == 0 ? 6 : 3
                                )
                        }
                    }
                    if selectedRoute == .shortest, let shortestRoute = routeCalculator.shortestRoute {
                        MapPolyline(shortestRoute)
                            .stroke(Color.green, lineWidth: 6)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea()
                
                VStack {
                    Picker("Route Type", selection: $selectedRoute) {
                        ForEach(RouteType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    
                    if let routes = routeCalculator.allRoutes, !routes.isEmpty {
                        let displayedRoute = selectedRoute == .full ? routes[0] : routeCalculator.shortestRoute!
                        VStack {
                            Text(selectedRoute == .full ? "Full Route" : "Shortest Route")
                                .font(.headline)
                            Text("Distance: \(String(format: "%.2f", displayedRoute.distance / 1000)) km")
                            Text("Estimated Time: \(String(format: "%.0f", displayedRoute.expectedTravelTime / 60)) min")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemGray6))
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Route")
            .navigationBarTitleDisplayMode(.inline)
            .tint(.red)
            .onAppear {
                routeCalculator.calculateRoutes(from: pickupAddress, to: dropAddress) { _ in
                }
            }
        }
    }
}