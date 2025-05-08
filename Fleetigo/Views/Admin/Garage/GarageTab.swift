//
//  GarageTab.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//


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

    // GarageTab.swift (Relevant part of body)

    var body: some View {
        NavigationView {
            ZStack { // Keep ZStack for the gradient background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#FF6767").opacity(0.5), location: 0.0),
                        .init(color: Color(hex: "#FF6767").opacity(0.3), location: 0.1),
                        .init(color: Color(hex: "#FF6767").opacity(0.1), location: 0.15),
                        .init(color: .clear, location: 0.5) // Adjust location to control gradient spread
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) { // Main VStack
                    // MARK: - Header Section
                    Text("Garage")
                        .font(.largeTitle).bold()
                        .padding(.horizontal)
                        .padding(.top) // Keep top padding
                        .padding(.bottom, 8) // Add a bit of bottom padding for separation

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
                                .padding(8) // Consider consistent padding with SearchBar
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
                    .padding(.bottom, 16) // Increased bottom padding before the list

                    // MARK: - Content Section
                    if issueManager.isLoadingReports {
                        VStack { // Center ProgressView
                            Spacer()
                            ProgressView("Loading Reports...")
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = issueManager.fetchError {
                        VStack { // Center Error Message
                            Spacer()
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredIssueReports.isEmpty {
                        VStack { // Center No Reports Message
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
                                // ... (ForEach loops for reports remain the same)
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
                            .padding(.horizontal) // Add horizontal padding to the LazyVStack content
                            .padding(.bottom) // Add bottom padding to the ScrollView content
                        }
                        .refreshable {
                            await issueManager.fetchIssueReportsList()
                        }
                    }
                }
                .background(Color.clear) // Ensure VStack itself is clear if gradient is in ZStack
                .navigationBarHidden(true)
                .onAppear {
                    if issueManager.issueReports.isEmpty {
                        Task {
                            await issueManager.fetchIssueReportsList()
                        }
                    }
                }
            }
            // .background(Color(.systemGroupedBackground)) // Moved gradient to ZStack
        }
        // .navigationViewStyle(.stack) // Optional: for consistent navigation behavior
    }

    private func handleStatusUpdate(reportId: UUID, newStatus: String) {
        Task {
            do {
                try await issueManager.updateIssueReportStatusInList(issueReportId: reportId, newStatus: newStatus)
            } catch {
                print("Error updating status from view: \(error)")
                // Optionally show an alert to the user here
            }
        }
    }
}