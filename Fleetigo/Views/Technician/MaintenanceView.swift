// MaintenanceView.swift
import SwiftUI

struct MaintenanceView: View {
    @State private var selectedTab = 0 // 0 for Tasks, 1 for History
    @StateObject private var store = MaintenanceStore() // Initialize here
    @State private var searchText = "" // For history search
    
    @State private var navigateToProfile = false
    // No need to inject AppState if ProfileViewModel handles role and profile fetching
    // @EnvironmentObject var appState: AppState
    @StateObject private var profileViewModel = ProfileViewModel() // Already fetches on init

    // init() remains the same

    // Filtered tasks for the Tasks tab
    var pendingTasks: [IssueReport] {
        store.tasks.filter { $0.status.lowercased() == "pending" }
    }

    var inProgressTasks: [IssueReport] {
        store.tasks.filter { $0.status.lowercased() == "in progress" }
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
                // Assuming ProfileView also uses ProfileViewModel
                ProfileView().environmentObject(profileViewModel)
            }
            .onAppear {
                // ProfileViewModel fetches its own profile on init.
                // We just need to wait for it if it's still loading,
                // then set the technician ID in the store and fetch tasks.
                Task {
    
                    if profileViewModel.isLoading {
                        print("MaintenanceView.onAppear: ProfileViewModel might be loading. Waiting or re-triggering fetchUserProfile if necessary.")
                        // Await the existing fetch if it's ongoing, or trigger if it wasn't.
                        // Since `fetchUserProfile` is called in `init`, we check its state.
                        // A better pattern might be for ProfileViewModel to publish a "profileReady" state.
                        // For now, let's check if technicianProfile is already set.
                        if profileViewModel.technicianProfile == nil && !profileViewModel.isLoading {
                             print("MaintenanceView.onAppear: technicianProfile is nil and not loading, calling fetchUserProfile.")
                             await profileViewModel.fetchUserProfile() // Call it if not already loaded
                        }
                    }
                    
                    // After profile fetch attempt (either from init or above call)
                    if let techProfile = profileViewModel.technicianProfile {
                        store.currentTechnicianId = techProfile.id
                        print("Technician ID set in MaintenanceStore: \(techProfile.id)")
                    } else {
                        print("Could not get technician profile or ID for MaintenanceStore. User role might not be technician or fetch failed.")
                        // Handle this case: maybe show an error or prevent task fetching
                        // For now, fetchMaintenanceTasks might fetch all tasks if currentTechnicianId is nil.
                    }
                    
                    // Initial fetch of tasks
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
                // Pass profileViewModel to profileHeader
                profileHeader(profileVM: profileViewModel)
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
                } else if pendingTasks.isEmpty && inProgressTasks.isEmpty {
                    Spacer()
                    Text("No maintenance tasks assigned.")
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if !inProgressTasks.isEmpty {
                                sectionHeader(title: "In Progress")
                                ForEach(inProgressTasks) { taskReport in
                                    MaintenanceTaskCard(issueReport: taskReport)
                                        .padding(.horizontal)
                                }
                            }
                            
                            if !pendingTasks.isEmpty {
                                sectionHeader(title: "Pending / New Tasks")
                                ForEach(pendingTasks) { taskReport in
                                    MaintenanceTaskCard(issueReport: taskReport)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        // Optionally re-fetch profile if needed, then tasks
                        // await profileViewModel.fetchUserProfile()
                        // if let techProfile = profileViewModel.technicianProfile {
                        //     store.currentTechnicianId = techProfile.id
                        // }
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
                 VStack { // Ensure content is centered
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
                .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by ID, Description...")
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
    
    // Modified profileHeader to accept ProfileViewModel
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
                
                // Display Technician Name from the passed ProfileViewModel
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
