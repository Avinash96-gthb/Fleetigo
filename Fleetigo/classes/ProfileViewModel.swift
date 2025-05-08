//
//  ProfileViewModel.swift
//  Fleetigo
//
//  Created by Avinash on 05/05/25.
//
import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var adminProfile: AdminProfile?
    @Published var driverProfile: DriverProfile?
    @Published var technicianProfile: TechnicianProfile?

    @Published var userRole: UserRole?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    

    private let supabaseManager = SupabaseManager.shared

    init() {
        Task {
            await fetchUserProfile()
        }
    }

    func fetchUserProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            if let role = await supabaseManager.getUserRole() {
                self.userRole = role
                switch role {
                case .admin:
                    self.adminProfile = try await supabaseManager.fetchAdminProfile()
                    print(adminProfile)
                case .driver:
                    self.driverProfile = try await supabaseManager.fetchDriverProfile()
                    print(driverProfile)
                case .technician:
                    self.technicianProfile = try await supabaseManager.fetchTechnicianProfile()
                    print(technicianProfile)
                }
            } else {
                errorMessage = "Could not determine user role."
            }
        } catch {
            errorMessage = "Error fetching user profile: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
