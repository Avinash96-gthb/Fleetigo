//
//  AppRootView.swift
//  Fleetigo
//
//  Created by Avinash on 25/04/25.
//
import SwiftUI

struct AppRootView: View {
    @State private var isLoggedIn = false
    @State private var selectedRole: Role = .admin
    @StateObject private var tripManager = TripManager()
    @StateObject private var appState = AppState()

    var body: some View {
        Group { // Wrap the conditional content in a Group
            if appState.isLoggedIn {
                switch appState.selectedRole {
                case .admin:
                    MainTabView()
                case .driver:
                    TripCardView() // Pass it here
                        .environmentObject(tripManager)
                case .maintenance:
                    MaintenanceView()
                }
            } else {
                LoginView()
            }
        }
        .environmentObject(appState) // Apply it to the Group
    }
}
