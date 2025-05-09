//
//  IssueManager.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//


// IssueManager.swift
import SwiftUI
import Supabase

class IssueManager: ObservableObject {
    // For submission UI
    @Published var submissionError: String?
    @Published var isSubmitting = false
    @Published var showSuccessAlert = false

    // For GarageTab data
    @Published var issueReports: [IssueReport] = []
    @Published var isLoadingReports = false
    @Published var fetchError: String?

    static let shared = IssueManager()
    private init() {}

    private var client: SupabaseClient {
        return SupabaseManager.shared.client
    }

    func submitIssueReport(
        consignmentId: UUID?,
        vehicleId: UUID?,
        driverId: UUID, // driverId is non-optional here for submission
        description: String,
        priority: String,
        category: String,
        type: String,
        images: [UIImage],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        isSubmitting = true
        submissionError = nil

        let issueReport = IssueReport(
            consignmentId: consignmentId,
            vehicleId: vehicleId,
            driverId: driverId, // Passed as non-nil UUID
            description: description,
            priority: priority,
            category: category,
            type: type
            // status defaults to "Pending"
        )

        Task {
            do {
                let insertedReport = try await SupabaseManager.shared.insertIssueReport(report: issueReport)
                print("Report inserted with ID: \(insertedReport.id)")

                var photoUploadErrors: [String] = []
                for (index, image) in images.enumerated() {
                    do {
                        _ = try await SupabaseManager.shared.uploadIssuePhoto(issueId: insertedReport.id, image: image, index: index)
                        print("Uploaded photo \(index + 1)")
                    } catch {
                        let errorMsg = "Error uploading photo \(index + 1): \(error.localizedDescription)"
                        print(errorMsg)
                        photoUploadErrors.append(errorMsg)
                    }
                }

                if !photoUploadErrors.isEmpty {
                    self.submissionError = "Report submitted, but some photos failed to upload: " + photoUploadErrors.joined(separator: "; ")
                }
                
                DispatchQueue.main.async {
                    if !photoUploadErrors.isEmpty {
                         // Partial success, complete with an error indicating photo issues
                        completion(.failure(NSError(domain: "IssueManagerError", code: 501, userInfo: [NSLocalizedDescriptionKey: self.submissionError ?? "Photo upload errors."])))
                    } else {
                        self.showSuccessAlert = true
                        completion(.success(()))
                    }
                }
            } catch {
                print("Error inserting issue report: \(error)")
                DispatchQueue.main.async {
                    self.submissionError = "Failed to submit report: \(error.localizedDescription)"
                    completion(.failure(error))
                }
            }

            DispatchQueue.main.async {
                self.isSubmitting = false
            }
        }
    }
    
    // MARK: - Integrated Supabase Functions for GarageTab

    @MainActor // Ensures updates to @Published vars are on main thread
    func fetchIssueReportsList() async {
        isLoadingReports = true
        fetchError = nil
        
        do {
            let response = try await SupabaseManager.shared.fetchIssueReports()
            self.issueReports = response
        } catch {
            self.fetchError = "Failed to load reports: \(error.localizedDescription)"
            print("Error fetching issue reports: \(error)")
        }
        isLoadingReports = false
    }
        
    
    
    func fetchImageURLsForReport(issueReportId: UUID) async throws -> [URL] {
        // Convert the UUID string to lowercase to match Supabase storage folder names
        let pathString = issueReportId.uuidString.lowercased() // <<<< KEY CHANGE HERE
        
        print("[IssueManager DEBUG] TEST: Attempting to list root of 'issue-photos' bucket.");
            let rootFileObjects: [FileObject]
            do {
                rootFileObjects = try await client.storage.from("issue-photos").list() // NO PATH
                print("[IssueManager DEBUG] TEST: client.list() at ROOT returned \(rootFileObjects.count) file objects: \(rootFileObjects.map { $0.name })")
                // This should list your UUID folders if the RLS allows listing at this level.
            } catch {
                print("[IssueManager DEBUG] TEST: Error listing ROOT of 'issue-photos': \(error.localizedDescription)")
            }

        print("[IssueManager DEBUG] fetchImageURLsForReport: Called for issueReportId: \(issueReportId), using LOWERCASED pathString: '\(pathString)'")

        guard !pathString.isEmpty else {
            print("[IssueManager DEBUG] fetchImageURLsForReport: Error - issueReportId.uuidString.lowercased() is empty.")
            throw NSError(domain: "IssueManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid issueReportId (empty string after lowercasing)."])
        }

        let fileObjects: [FileObject]
        do {
            fileObjects = try await client.storage.from("issue-photos").list(path: pathString)
            print("[IssueManager DEBUG] fetchImageURLsForReport: client.list() returned \(fileObjects.count) file objects in path '\(pathString)': \(fileObjects.map { $0.name })")
        } catch {
            print("[IssueManager DEBUG] fetchImageURLsForReport: Error during client.list() for path '\(pathString)': \(error.localizedDescription)")
            print("[IssueManager DEBUG] Full error details: \(error)")
            throw error
        }
        
        if fileObjects.isEmpty {
            print("[IssueManager DEBUG] fetchImageURLsForReport: No files found by client.list() in storage at path '\(pathString)'. Check RLS, path case, and if folder/files exist.")
        }

        var generatedURLs: [URL] = []
        for fileObject in fileObjects {
            // pathString is already lowercased here
            let fullStoragePath = "\(pathString)/\(fileObject.name)"
            print("[IssueManager DEBUG] fetchImageURLsForReport: Attempting to get public URL for storage path: '\(fullStoragePath)'")
            do {
                let url = try client.storage.from("issue-photos").getPublicURL(path: fullStoragePath)
                print("[IssueManager DEBUG] fetchImageURLsForReport: Generated public URL: \(url.absoluteString)")
                generatedURLs.append(url)
            } catch {
                print("[IssueManager DEBUG] fetchImageURLsForReport: Error getting public URL for path '\(fullStoragePath)': \(error.localizedDescription)")
            }
        }
        return generatedURLs
    }
    @MainActor
    func updateIssueReportStatusInList(issueReportId: UUID, newStatus: String) async throws {
        // Optimistically update UI first, or wait for DB confirmation
        // For simplicity, let's update DB then refresh UI part or whole list

        _ = try await client
            .from("issue_reports")
            .update(["status": newStatus]) // Make sure "status" is the exact column name
            .eq("id", value: issueReportId.uuidString) // Supabase often expects UUIDs as strings in .eq()
            .execute()
        
        // Update local model
        if let index = issueReports.firstIndex(where: { $0.id == issueReportId }) {
            issueReports[index].status = newStatus
            // If other fields might change server-side upon status update (e.g., admin_id),
            // you might need to fetch the updated report object or re-fetch the whole list.
            // For now, just updating status.
        } else {
            // If not found, maybe the list is stale. Re-fetch.
            await fetchIssueReportsList()
        }
    }
    
    @MainActor
        func approveIssueReportAndUpdateLocal(reportId: UUID, adminId: UUID, vehicleId: UUID?) async throws {
            print("IssueManager: Approving report \(reportId) by admin \(adminId)...")
            
            // Call SupabaseManager to perform DB updates for approval
            try await SupabaseManager.shared.approveIssueReport(
                reportId: reportId,
                adminId: adminId,
                vehicleId: vehicleId
            )
            
            // Update local model state for the issue report
            if let index = issueReports.firstIndex(where: { $0.id == reportId }) {
                issueReports[index].status = "In Progress"
                // Note: We cannot update issueReports[index].adminId = adminId locally
                // because `adminId` is a `let` constant in the IssueReport struct.
                // The UI will reflect the "In Progress" status immediately.
                // To see the adminId reflected locally without re-fetching,
                // the IssueReport struct would need `var adminId: UUID?`.
                print("IssueManager: Local issue report \(reportId) status updated to In Progress.")
            } else {
                 print("IssueManager Warning: Could not find report \(reportId) locally to update status after approval.")
            }
            
            // Optional: Update local vehicle cache if you maintain one
            // e.g., find vehicle with vehicleId and set its status to .garage
            print("IssueManager: Approval process complete for report \(reportId).")
        }
}
