import SwiftUI

// MARK: - Garage Tab
struct GarageTab: View {
    enum TabFilter: String, CaseIterable {
        case complaints = "Complaints" // Maps to "Pending"
        case approved = "Approved"   // Maps to "In Progress", "Resolved"
        case rejected = "Rejected"   // Maps to "Rejected"
    }

    // PriorityFilter values should match strings stored in IssueReport.priority
    enum PriorityFilter: String, CaseIterable {
        case all = "All"
        case high = "High"
        case medium = "Medium"
        case low = "Low"
    }

    @StateObject var issueManager = IssueManager.shared
    @State private var selectedFilter: TabFilter = .complaints
    @State private var searchText: String = ""
    @State private var selectedPriority: PriorityFilter = .all
    @StateObject var profileViewModel = ProfileViewModel()

    var filteredIssueReports: [IssueReport] {
        issueManager.issueReports.filter { report in
            let matchesTab: Bool
            let reportStatusLowercased = report.status.lowercased()
            switch selectedFilter {
            case .complaints:
                matchesTab = reportStatusLowercased == "pending"
            case .approved:
                matchesTab = reportStatusLowercased == "in progress" || reportStatusLowercased == "resolved"
            case .rejected:
                matchesTab = reportStatusLowercased == "rejected"
            }
            
            let matchesPriority: Bool
            if selectedPriority == .all {
                matchesPriority = true
            } else {
                matchesPriority = report.priority.lowercased() == selectedPriority.rawValue.lowercased()
            }
            
            let matchesSearch = searchText.isEmpty ||
                report.id.uuidString.localizedCaseInsensitiveContains(searchText) ||
                report.type.localizedCaseInsensitiveContains(searchText) ||
                report.description.localizedCaseInsensitiveContains(searchText) ||
                report.category.localizedCaseInsensitiveContains(searchText)
            
            return matchesTab && matchesPriority && matchesSearch
        }
    }
    
    private var inProgressReports: [IssueReport] {
        filteredIssueReports.filter { $0.status.lowercased() == "in progress" }
    }
    
    private var resolvedReports: [IssueReport] {
        filteredIssueReports.filter { $0.status.lowercased() == "resolved" }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#FF6767").opacity(0.5), location: 0.0),
                    .init(color: Color(hex: "#FF6767").opacity(0.3), location: 0.1),
                    .init(color: Color(hex: "#FF6767").opacity(0.1), location: 0.15),
                    .init(color: .clear, location: 0.5)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea() // Background extends to edges

            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Header Section
                Text("Garage")
                    .font(.largeTitle).bold()
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                HStack(spacing: 10) {
                    SearchBar(text: $searchText)
                    Menu {
                        ForEach(PriorityFilter.allCases, id: \.self) { priority in
                            Button(action: { selectedPriority = priority }) {
                                HStack {
                                    Text(priority.rawValue)
                                    Spacer()
                                    if selectedPriority == priority {
                                        Image(systemName: "checkmark").foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#4B4B4B"))
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TabFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.bottom, 16)

                // MARK: - Content Section
                if issueManager.isLoadingReports {
                    VStack {
                        Spacer()
                        ProgressView("Loading Reports...")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = issueManager.fetchError {
                    VStack {
                        Spacer()
                        Text("Error: \(error)")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredIssueReports.isEmpty {
                    VStack {
                        Spacer()
                        Text("No issue reports found for the selected filters.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if selectedFilter == .approved {
                                ForEach(inProgressReports) { report in
                                    IssueReportCardView(report: report, filter: selectedFilter, onUpdateStatus: handleStatusUpdate)
                                }
                                
                                if !resolvedReports.isEmpty {
                                    Text("History (Resolved)")
                                        .foregroundColor(Color(hex: "#4B4B4B"))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 20).padding(.horizontal).font(.system(size: 20, weight: .bold))
                                    
                                    ForEach(resolvedReports) { report in
                                        IssueReportCardView(report: report, filter: selectedFilter, onUpdateStatus: handleStatusUpdate)
                                    }
                                }
                            } else {
                                ForEach(filteredIssueReports) { report in
                                    IssueReportCardView(report: report, filter: selectedFilter, onUpdateStatus: handleStatusUpdate)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .refreshable {
                        await issueManager.fetchIssueReportsList()
                    }
                }
            }
            .background(Color.clear)
            .onAppear {
                if issueManager.issueReports.isEmpty {
                    Task {
                        await issueManager.fetchIssueReportsList()
                    }
                }
            }
        }
    }

    private func handleStatusUpdate(reportId: UUID, newStatus: String) {
        Task {
            // Handle the specific case for APPROVAL ("In Progress")
            if newStatus == "In Progress" {
                // 1. Get current Admin ID from ProfileViewModel
                guard profileViewModel.userRole == .admin, let adminId = profileViewModel.adminProfile?.id else {
                    print("GarageTab Error: Cannot approve. Not logged in as admin or admin profile not loaded.")
                    // TODO: Show error alert to the user
                    return
                }

                // 2. Find the specific IssueReport locally to get its vehicleId
                guard let reportToApprove = issueManager.issueReports.first(where: { $0.id == reportId }) else {
                    print("GarageTab Error: Could not find report \(reportId) locally to get vehicle ID.")
                    // TODO: Show error alert to the user
                    return
                }
                let vehicleId = reportToApprove.vehicleId // This can be nil

                print("GarageTab: Attempting to approve Report ID: \(reportId), Admin ID: \(adminId), Vehicle ID: \(vehicleId?.uuidString ?? "N/A")")

                // 3. Call the specific approval function in IssueManager
                do {
                    try await issueManager.approveIssueReportAndUpdateLocal(
                        reportId: reportId,
                        adminId: adminId,
                        vehicleId: vehicleId
                    )
                    print("GarageTab: Report \(reportId) approved successfully (DB & Local status updated).")
                } catch {
                    print("GarageTab Error: Failed to approve report \(reportId): \(error)")
                    // TODO: Show error alert to the user
                }

            } else {
                // Handle OTHER status updates (e.g., "Rejected", "Pending" from Re-open)
                print("GarageTab: Handling status update for Report ID: \(reportId) to Status: \(newStatus)")
                do {
                    try await issueManager.updateIssueReportStatusInList(
                        issueReportId: reportId,
                        newStatus: newStatus
                    )
                    print("GarageTab: Report \(reportId) status updated to \(newStatus).")
                } catch {
                    print("GarageTab Error: Failed to update status to \(newStatus) for report \(reportId): \(error)")
                    // TODO: Show error alert to the user
                }
            }
        }
    }
}

// Preview
struct GarageTab_Previews: PreviewProvider {
    static var previews: some View {
        GarageTab()
    }
}


