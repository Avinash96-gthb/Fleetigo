import Foundation
import SwiftUI
import os.log


class VehicleViewModel: ObservableObject {
    @Published var vehicles: [Vehicle] = []
    @Published var filteredVehicles: [Vehicle] = []
    @Published var selectedSegment: Vehicle.VehicleStatus = .available
    @Published var selectedVehicleTypes: Set<String> = []
    @Published var searchText: String = "" {
        didSet {
            print("searchText updated to: \(searchText)")
            filterVehicles()
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func getAvailableVehicles(ofType type: String) -> [Vehicle] {
        vehicles.filter {
            $0.status == .available && $0.type == type
        }
    }
    
    private let logger = Logger(subsystem: "com.yourapp", category: "VehicleViewModel")
    
    // Fetch vehicles from Supabase
    
    func fetchVehicles() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        do {
            print("Starting fetchVehicles...")

            let list = try await SupabaseManager.shared.fetchVehicles()  // this already includes downloaded file data

            DispatchQueue.main.async {
                self.vehicles = list
                self.filterVehicles()
                self.isLoading = false
                print("Finished fetchVehicles, total: \(self.vehicles.count)")
            }

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("Error fetching vehicles: \(error.localizedDescription)")
            }
        }
    }

    
    func filterVehicles() {
        let previousCount = filteredVehicles.count
        filteredVehicles = vehicles.filter { vehicle in
            // Handle optional status: Only include if status matches the selected segment
            // or if selectedSegment is nil (if you add an 'All' segment option)
            let matchesStatus = vehicle.status == selectedSegment

            // Filter by licensePlate (which is not optional)
            let matchesSearch = searchText.isEmpty || vehicle.licensePlateNo.localizedCaseInsensitiveContains(searchText)

            // Handle optional type: Only include if vehicle.type is not nil AND the type is in the selected set
            let matchesType = selectedVehicleTypes.isEmpty || (vehicle.type != nil && selectedVehicleTypes.contains(vehicle.type))

            return matchesStatus && matchesSearch && matchesType
        }
        print("Filtered vehicles count: \(filteredVehicles.count), selectedSegment: \(selectedSegment.rawValue ?? "nil"), searchText: \(searchText), selectedVehicleTypes: \(selectedVehicleTypes)")
        if previousCount != filteredVehicles.count {
             print("Filtered vehicles changed, should trigger view update")
             objectWillChange.send()
        }
    }

    func toggleVehicleType(_ type: String) {
         // This function assumes 'type' is a non-nil string
         // You might need to handle cases where the vehicle type is nil in the UI
         if selectedVehicleTypes.contains(type) {
             selectedVehicleTypes.remove(type)
         } else {
             selectedVehicleTypes.insert(type)
         }
         filterVehicles()
    }

    func clearVehicleTypes() {
        selectedVehicleTypes.removeAll()
        filterVehicles()
    }

    var uniqueVehicleTypes: [String] {
         // Use compactMap to get only the non-nil types
         Array(Set(vehicles.compactMap { $0.type })).sorted()
    }
}
