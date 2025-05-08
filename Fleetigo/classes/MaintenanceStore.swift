//
//  MaintenanceStore.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//


import Foundation
import Combine



class MaintenanceStore: ObservableObject {
    @Published var tasks: [IssueReport] = [] // All fetched tasks (pending, in progress)
    @Published var history: [IssueReport] = [] // Resolved tasks
    @Published var isLoadingTasks: Bool = false
    @Published var fetchError: String?

    private var cancellables = Set<AnyCancellable>()
    private let issueManager = IssueManager.shared // Use the existing IssueManager

    // We need to know the current technician's ID to potentially assign tasks
    // This would typically come from the logged-in user's profile
    var currentTechnicianId: UUID? // Set this after login

    init(technicianId: UUID? = nil) {
        self.currentTechnicianId = technicianId
        // Initial fetch or subscribe to IssueManager updates if it publishes them broadly
        // For now, let's do a direct fetch.
    }

    @MainActor
    func fetchMaintenanceTasks() async {
        isLoadingTasks = true
        fetchError = nil
        
        // For simplicity, we'll re-fetch all reports from IssueManager
        // IssueManager already handles fetching from Supabase
        await issueManager.fetchIssueReportsList() // Make sure IssueManager is up-to-date

        if let error = issueManager.fetchError {
            self.fetchError = error
            self.isLoadingTasks = false
            return
        }
        
        // Filter tasks for the maintenance view
        // Technicians usually see "Pending" (newly approved by admin) and "In Progress" (accepted by a technician)
        // You might need to refine what "Pending" means for a technician.
        // Is it any "Pending" report? Or only those with status "Approved by Admin" or "Ready for Maintenance"?
        // Let's assume for now that any "Pending" or "In Progress" is a task.
        
        let allReports = issueManager.issueReports
        self.tasks = allReports.filter { report in
            let status = report.status.lowercased()
            return status == "in progress"
            // Potentially add: && (report.assigned_technician_id == currentTechnicianId || report.assigned_technician_id == nil)
            // if you want to show only unassigned or tasks assigned to the current technician.
        }
        
        self.history = allReports.filter { $0.status.lowercased() == "resolved" }
        
        isLoadingTasks = false
    }

    @MainActor
    func acceptTask(_ task: IssueReport) async {
        guard let technicianId = currentTechnicianId else {
            print("Error: currentTechnicianId is not set in MaintenanceStore.")
            // Handle error: show alert or log
            return
        }

        // Optimistically update UI
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].status = "In Progress"
            // Potentially set tasks[index].assigned_technician_id = technicianId if you have such a field
        }

        do {
            // Update status in Supabase.
            // You might also want to update an 'assigned_technician_id' field here.
            // For now, just updating status. If updating more fields, SupabaseManager.updateIssueReport needs to support it.
            try await SupabaseManager.shared.updateIssueReportStatus(
                issueReportId: task.id,
                newStatus: "In Progress"
                // Potentially add: assignedTechnicianId: technicianId
            )
            print("Task \(task.id) accepted and status updated in Supabase.")
            // Re-fetch or ensure local data is consistent.
            // A full re-fetch is simplest for now after an update.
            await fetchMaintenanceTasks()
        } catch {
            print("Error accepting task \(task.id): \(error)")
            // Revert optimistic UI update if needed
            // For now, a re-fetch will correct it.
            await fetchMaintenanceTasks() // Re-fetch to get consistent state
            // Optionally show an error to the user
        }
    }

    @MainActor
    func markTaskAsDone(_ task: IssueReport) async {
        // Optimistically update UI
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            var resolvedTask = tasks.remove(at: index)
            resolvedTask.status = "Resolved"
            history.insert(resolvedTask, at: 0) // Add to top of history
        }

        do {
            try await SupabaseManager.shared.updateIssueReportStatus(
                issueReportId: task.id,
                newStatus: "Resolved"
            )
            print("Task \(task.id) marked as Resolved and status updated in Supabase.")
            // A full re-fetch is simplest for now after an update.
            await fetchMaintenanceTasks()
        } catch {
            print("Error marking task \(task.id) as done: \(error)")
            // Revert optimistic UI update
            await fetchMaintenanceTasks() // Re-fetch to get consistent state
            // Optionally show an error to the user
        }
    }

    // You might need to fetch Driver and Admin profiles to display their names
    // This can be done on-demand or pre-fetched if performance allows.
    // For now, we'll assume IssueReport might eventually contain driver_name, admin_name
    // or you'll fetch them when displaying the card.

    // Example function to get a Driver's name (simplified)
    // In a real app, cache these or fetch more efficiently.
    func getDriverName(driverId: UUID?) async -> String? {
        guard let driverId = driverId else { return nil }
        // This is a placeholder. You'd need a SupabaseManager function
        // to fetch a specific driver_profile by ID.
        // For example: let profile = try? await SupabaseManager.shared.fetchDriverProfile(byId: driverId)
        // return profile?.name
        
        // Simulate fetching (replace with actual Supabase call)
        let drivers = try? await SupabaseManager.shared.fetchAllEmployees().filter { $0.role == "Driver" }
        return drivers?.first(where: { $0.id == driverId })?.name ?? "Driver \(driverId.uuidString.prefix(4))"
    }

    // Example function to get an Admin's name
    func getAdminName(adminId: UUID?) async -> String? {
        guard let adminId = adminId else { return nil }
        // Similar to getDriverName, fetch from admin_profiles
        // let profile = try? await SupabaseManager.shared.fetchAdminProfile(byId: adminId)
        // return profile?.full_name
        
        // Simulate fetching
        let admins = try? await SupabaseManager.shared.fetchAllEmployees().filter { $0.role == "Admin" }
        return admins?.first(where: { $0.id == adminId })?.name ?? "Admin \(adminId.uuidString.prefix(4))"
    }
}
