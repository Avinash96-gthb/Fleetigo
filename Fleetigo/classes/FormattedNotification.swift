//
//  FormattedNotification.swift
//  Fleetigo
//
//  Created by Avinash on 09/05/25.
//


// NotificationViewModel.swift
import SwiftUI
import Combine

// Struct to hold the formatted notification message and original warning
struct FormattedNotification: Identifiable, Hashable {
    let id: UUID // Use warning's ID or generate one
    let message: String
    let timestamp: Date? // For sorting or display
    let originalWarning: RouteDeviationWarning // Keep original for potential navigation

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    static func == (lhs: FormattedNotification, rhs: FormattedNotification) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var formattedNotifications: [FormattedNotification] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabaseManager = SupabaseManager.shared
    // Cache for driver names to avoid re-fetching for the same driver multiple times
    private var driverNameCache: [UUID: String] = [:]

    init() {
        // Task { await fetchNotifications() } // Optionally fetch on init
    }

    func fetchNotifications() async {
        print("NotificationViewModel: Starting to fetch notifications...")
        isLoading = true
        errorMessage = nil
        driverNameCache.removeAll() // Clear cache on new fetch
        var tempFormattedNotifications: [FormattedNotification] = []

        do {
            let warnings = try await supabaseManager.fetchAllRouteDeviationWarnings()
            print("NotificationViewModel: Fetched \(warnings.count) raw warnings.")

            // Fetch driver names for each warning concurrently
            // Using a simpler loop for clarity, can be optimized with TaskGroup for many warnings
            for warning in warnings {
                guard let driverId = warning.driver_id else {
                    // Create a notification even if driver_id is missing
                    let message = "Route deviation detected on trip \(warning.trip_id.uuidString.prefix(6)) at \(warning.displayTimestamp). Driver unknown."
                    tempFormattedNotifications.append(
                        FormattedNotification(id: warning.id ?? UUID(), message: message, timestamp: warning.timestamp, originalWarning: warning)
                    )
                    continue
                }

                var driverName = "Driver \(driverId.uuidString.prefix(4))" // Default name
                
                // Check cache first
                if let cachedName = driverNameCache[driverId] {
                    driverName = cachedName
                } else {
                    // Fetch from Supabase if not in cache
                    if let driverProfile = try? await supabaseManager.fetchDriverProfile(byId: driverId) {
                        driverName = driverProfile.name ?? driverName // Use fetched name or keep default
                        driverNameCache[driverId] = driverName // Cache it
                    }
                }
                
                let distanceString = warning.distance_from_route.map { String(format: "%.0f", $0) + "m" } ?? "an unknown distance"
                let message = "\(driverName) exceeded route bounds by \(distanceString) on trip \(warning.trip_id.uuidString.prefix(6)) at \(warning.displayTimestamp)."
                
                tempFormattedNotifications.append(
                    FormattedNotification(id: warning.id ?? UUID(), message: message, timestamp: warning.timestamp, originalWarning: warning)
                )
            }
            
            // Sort by timestamp if needed (already ordered by DB)
            // self.formattedNotifications = tempFormattedNotifications.sorted { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }
            self.formattedNotifications = tempFormattedNotifications
            print("NotificationViewModel: Processed \(self.formattedNotifications.count) formatted notifications.")

        } catch {
            print("NotificationViewModel: Error fetching or processing notifications: \(error)")
            errorMessage = "Failed to load notifications: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
