//
//  MapLocationPicker.swift
//  FleetigoConsignment
//
//  Created by user@22 on 29/04/25.
//


import SwiftUI
import MapKit
import CoreLocation

struct MapLocationPicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedLocation: String
    @StateObject private var locationManager = LocationManager()
    @State private var searchQuery: String = ""
    @State private var position: MapCameraPosition
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var isShowingResults: Bool = false
    
    init(selectedLocation: Binding<String>) {
        self._selectedLocation = selectedLocation
        if let userLocation = LocationManager().userLocation {
            self._position = State(initialValue: .region(MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )))
        } else {
            self._position = State(initialValue: .automatic)
        }
    }
    
    var body: some View {
        NavigationStack {
            mapViewContent
                .navigationTitle("Select Location")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Select") {
                            if let selectedMapItem = selectedMapItem {
                                selectedLocation = selectedMapItem.placemark.formattedAddress ?? selectedMapItem.name ?? ""
                            }
                            dismiss()
                        }
                        .disabled(selectedMapItem == nil)
                    }
                }
                .tint(.red)
        }
    }
    
    private var mapViewContent: some View {
        ZStack {
            Map(position: $position, selection: $selectedMapItem) {
                mapContent
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()
            
            VStack {
                searchBarAndFilter
                searchResultsView
                Spacer()
            }
            
            // Current Location Button in Bottom-Right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    currentLocationButton
                        .padding(.bottom, 20)
                        .padding(.trailing, 20)
                }
            }
        }
    }
    
    private var searchBarAndFilter: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search location", text: $searchQuery)
                .autocorrectionDisabled()
                .onChange(of: searchQuery) { newValue in
                    performSearch(query: newValue)
                }
            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var currentLocationButton: some View {
        Button(action: {
            if let userLocation = locationManager.userLocation {
                let geocoder = CLGeocoder()
                let location = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let clPlacemark = placemarks?.first, error == nil {
                        let mkPlacemark = MKPlacemark(placemark: clPlacemark)
                        selectedLocation = mkPlacemark.formattedAddress ?? "Current Location"
                        selectedMapItem = MKMapItem(placemark: mkPlacemark)
                        position = .region(MKCoordinateRegion(
                            center: userLocation,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }
                }
            }
        }) {
            Image(systemName: "location.fill")
                .foregroundColor(.white)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
    
    private var searchResultsView: some View {
        Group {
            if isShowingResults && !searchResults.isEmpty {
                List(searchResults, id: \.self) { item in
                    Button(action: {
                        selectedMapItem = item
                        position = .item(item)
                        isShowingResults = false
                        searchQuery = item.name ?? ""
                    }) {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "Unknown")
                                .font(.headline)
                            if let address = item.placemark.formattedAddress {
                                Text(address)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .frame(maxHeight: 200)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)
            }
        }
    }
    
    private var mapContent: some MapContent {
        Group {
            if let selectedMapItem = selectedMapItem {
                Marker(item: selectedMapItem)
            }
            if let userLocation = locationManager.userLocation {
                Marker("Current Location", systemImage: "location.fill", coordinate: userLocation)
                    .tint(.blue)
            }
        }
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            isShowingResults = false
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let response = response {
                searchResults = response.mapItems
                isShowingResults = true
            }
        }
    }
}