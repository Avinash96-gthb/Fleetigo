//
//  AppState.swift
//  Fleetigo
//
//  Created by Avinash on 05/05/25.
//
import Foundation

class AppState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var selectedRole: Role = .admin

    func signOut() {
        Task {
            do {
                try await SupabaseManager.shared.signOut()
                DispatchQueue.main.async {
                    self.isLoggedIn = false
                    self.selectedRole = .admin
                }
            } catch {
                print("Sign out failed: \(error.localizedDescription)")
            }
        }
    }
}

