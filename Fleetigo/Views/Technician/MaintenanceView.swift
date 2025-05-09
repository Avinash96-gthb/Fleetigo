import SwiftUI

struct MaintenanceView: View {
    @State private var selectedTab = 0 // 0 for Tasks, 1 for History
    @StateObject private var store = MaintenanceStore() // Initialize here
    @State private var searchText = "" // For history and tasks search
    
    @State private var navigateToProfile = false
    @StateObject private var profileViewModel = ProfileViewModel() // Already fetches on init

    // Filtered tasks for the Tasks tab
    var pendingTasks: [IssueReport] {
        store.tasks.filter { $0.status.lowercased() == "pending" }
    }

    var inProgressTasks: [IssueReport] {
        store.tasks.filter { $0.status.lowercased() == "in progress" }
    }
    
    // Filtered tasks for search in Tasks tab
    var filteredTasks: (pending: [IssueReport], inProgress: [IssueReport]) {
        if searchText.isEmpty {
            return (pendingTasks, inProgressTasks)
        } else {
            let filteredPending = pendingTasks.filter { report in
                report.id.uuidString.localizedCaseInsensitiveContains(searchText) ||
                report.description.localizedCaseInsensitiveContains(searchText) ||
                report.type.localizedCaseInsensitiveContains(searchText) ||
                report.category.localizedCaseInsensitiveContains(searchText)
            }
            let filteredInProgress = inProgressTasks.filter { report in
                report.id.uuidString.localizedCaseInsensitiveContains(searchText) ||
                report.description.localizedCaseInsensitiveContains(searchText) ||
                report.type.localizedCaseInsensitiveContains(searchText) ||
                report.category.localizedCaseInsensitiveContains(searchText)
            }
            return (filteredPending, filteredInProgress)
        }
    }
    
    // Filtered history
    var filteredHistory: [IssueReport] {
        let historyToFilter = store.history
        if searchText.isEmpty {
            return historyToFilter
        } else {
            return historyToFilter.filter { report in
                report.id.uuidString.localizedCaseInsensitiveContains(searchText) ||
                report.description.localizedCaseInsensitiveContains(searchText) ||
                report.type.localizedCaseInsensitiveContains(searchText) ||
                report.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
                // MARK: - Tasks Tab
                tasksTabView
                    .tabItem { Label("Tasks", systemImage: "list.bullet") }
                    .tag(0)

                // MARK: - History Tab
                historyTabView
                    .tabItem { Label("History", systemImage: "clock") }
                    .tag(1)
            }
            .accentColor(Color(hex: "#F7C24B"))
            .navigationDestination(isPresented: $navigateToProfile) {
                ProfileView().environmentObject(profileViewModel)
            }
            .onAppear {
                Task {
                    if profileViewModel.isLoading {
                        print("MaintenanceView.onAppear: ProfileViewModel might be loading. Waiting or re-triggering fetchUserProfile if necessary.")
                        if profileViewModel.technicianProfile == nil && !profileViewModel.isLoading {
                             print("MaintenanceView.onAppear: technicianProfile is nil and not loading, calling fetchUserProfile.")
                             await profileViewModel.fetchUserProfile()
                        }
                    }
                    
                    if let techProfile = profileViewModel.technicianProfile {
                        store.currentTechnicianId = techProfile.id
                        print("Technician ID set in MaintenanceStore: \(techProfile.id)")
                    } else {
                        print("Could not get technician profile or ID for MaintenanceStore. User role might not be technician or fetch failed.")
                    }
                    
                    await store.fetchMaintenanceTasks()
                }
            }
        }
    }

    // Extracted Tasks Tab View
    private var tasksTabView: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                profileHeader(profileVM: profileViewModel)
                    .padding(.bottom, 8)
                
                // Search bar below profile header
                TextField("Search tasks...", text: $searchText)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                if store.isLoadingTasks {
                    Spacer()
                    ProgressView("Loading Tasks...")
                    Spacer()
                } else if let error = store.fetchError {
                    Spacer()
                    Text("Error loading tasks: \(error)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else if filteredTasks.pending.isEmpty && filteredTasks.inProgress.isEmpty {
                    Spacer()
                    Text("No maintenance tasks found.")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if !filteredTasks.inProgress.isEmpty {
                                sectionHeader(title: "In Progress")
                                ForEach(filteredTasks.inProgress) { taskReport in
                                    MaintenanceTaskCard(issueReport: taskReport)
                                        .padding(.horizontal)
                                }
                            }
                            
                            if !filteredTasks.pending.isEmpty {
                                sectionHeader(title: "Pending / New Tasks")
                                ForEach(filteredTasks.pending) { taskReport in
                                    MaintenanceTaskCard(issueReport: taskReport)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await store.fetchMaintenanceTasks()
                    }
                }
            }
        }
        .environmentObject(store)
    }

    // Extracted History Tab View
    private var historyTabView: some View {
        ZStack {
            backgroundGradient

            if store.isLoadingTasks && store.history.isEmpty {
                ProgressView("Loading History...")
            } else if filteredHistory.isEmpty {
                VStack {
                    Spacer()
                    Text("No maintenance history found.")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            } else {
                List {
                    ForEach(filteredHistory) { historyReport in
                        MaintenanceHistoryCard(issueReport: historyReport)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search")
            }
        }
        .navigationTitle("Maintenance History")
        .environmentObject(store)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "#F9DA9C").opacity(0.8), location: 0.0),
                .init(color: Color(UIColor.systemGroupedBackground), location: 0.25)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func sectionHeader(title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
    }
    
    private func profileHeader(profileVM: ProfileViewModel) -> some View {
        HStack {
            Button(action: { navigateToProfile = true }) {
                Image(systemName: "person.circle.fill")
                    .resizable().scaledToFit().frame(width: 44, height: 44)
                    .foregroundColor(Color(hex: "#666666"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Hello,")
                    .font(.caption).foregroundColor(Color(hex: "#555555"))
                
                Text(profileVM.technicianProfile?.name ?? (profileVM.isLoading ? "Loading..." : "Technician"))
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color(hex: "#D6A03A"))
                    .redacted(reason: profileVM.isLoading && profileVM.technicianProfile == nil ? .placeholder : [])
            }
            Spacer()
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundColor(Color(hex: "#666666"))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.thinMaterial)
    }
}
