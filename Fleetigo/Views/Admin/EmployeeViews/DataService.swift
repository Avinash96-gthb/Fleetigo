//
//  DataService.swift
//  Fleetigo
//
//  Created by Avinash on 04/05/25.
//


import Foundation
import Combine // Needed for ObservableObject

@MainActor // Ensures UI updates happen on the main thread
class DataService: ObservableObject {

    // Published properties for the UI to observe
    @Published var employees: [Employee] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // Instance of the SupabaseManager to interact with Supabase
    private let supabaseManager = SupabaseManager.shared
    
    var availableDrivers: [Employee] {
        employees.filter { $0.role == "Driver" && $0.status == "available" }
    }


    // Fetches employees using the SupabaseManager
    func fetchAllEmployees() async {
        isLoading = true
        errorMessage = nil
        print("DataService: Initiating fetchAllEmployees...")

        do {
            // Call the fetch method on SupabaseManager
            let fetchedEmployees = try await supabaseManager.fetchAllEmployees()
            self.employees = fetchedEmployees
            print("DataService: Successfully fetched \(employees.count) employees.")
        } catch {
            self.errorMessage = error.localizedDescription
            print("DataService: Error fetching employees - \(error.localizedDescription)")
            // Log more details if needed
            if let nsError = error as NSError? {
                print("Error Domain: \(nsError.domain), Code: \(nsError.code), UserInfo: \(nsError.userInfo)")
            }
        }
        isLoading = false
    }

    // --- Passthrough methods for creating users ---
    // These methods simply call the corresponding methods in SupabaseManager.
    // This keeps the View (AddEmployeeSheetView) interacting with DataService only.

    

}
