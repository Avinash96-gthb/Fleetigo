//
//  EmployeeView.swift
//  Fleetigo
//
//  Created by Avinash on 27/04/25.
//


import SwiftUI

struct EmployeeView: View {
    @State private var searchText = ""
    @State private var selectedSegment = 0 // 0: Driver, 1: Technician
    @State private var selectedStatus: String? = nil
    @State private var showAddEmployee = false

    // Use @StateObject to manage the lifecycle of DataService for this view
    @EnvironmentObject var dataService: DataService

    var selectedRole: String {
        selectedSegment == 0 ? "Driver" : "Technician"
    }

    // Filter based on the dataService's published employees array
    var filteredEmployees: [Employee] {
        dataService.employees.filter {
            // Role filter
            $0.role == selectedRole &&
            // Search filter
            (searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased())) &&
            // Status filter
            (selectedStatus == nil || $0.status == selectedStatus) // Assuming 'status' exists in your Employee model
        }
    }

    var groupedEmployees: [String: [Employee]] {
        Dictionary(grouping: filteredEmployees, by: { String($0.name.prefix(1)) })
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationStack {
                // Main content area Vstack
                VStack {
                    // Show loading indicator only when initially loading data
                    if dataService.isLoading && dataService.employees.isEmpty {
                        ProgressView("Loading Employees...")
                            .padding(.top, 50) // Add some padding
                        Spacer()
                    }
                    // Show error message if loading failed
                    else if let errorMessage = dataService.errorMessage {
                        VStack {
                            Spacer()
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("Error Loading Data")
                                .font(.headline)
                                .padding(.top, 5)
                            Text(errorMessage)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Button("Retry") {
                                Task {
                                    await dataService.fetchAllEmployees()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.top)
                            Spacer()
                        }
                        .padding()
                    }
                    // Show employee content if loaded successfully or if loading non-initially
                    else {
                        employeeContent // Extracted content Vstack
                    }
                }
                .navigationTitle("Employee")
                // Enable pull-to-refresh for the main content
                .refreshable {
                    print("Pull to refresh triggered.")
                    await dataService.fetchAllEmployees()
                }
            }
            .background( // Your gradient background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#FF6767").opacity(0.5), location: 0.0),
                        .init(color: Color(hex: "#FF6767").opacity(0.3), location: 0.1),
                        .init(color: Color(hex: "#FF6767").opacity(0.1), location: 0.3),
                        .init(color: .clear, location: 0.4) // Fade completes at 40% to ensure before Analytics header
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )

            addButton // Your floating action button
        }
        .sheet(isPresented: $showAddEmployee) {
            // Present the correct Add view based on selection
            if selectedSegment == 0 {
                // AddDriverView no longer needs the binding
                AddDriverView()
            } else {
                // AddTechnicianView no longer needs the binding
                AddTechnicianView()
            }
        }
        // Use .onDisappear on the SHEET ITSELF to refresh data AFTER it closes
        // This ensures data is refreshed regardless of how the sheet is dismissed (swipe, cancel, save)
        // It's simpler than passing success state back.
        .onChange(of: showAddEmployee) { oldValue, newValue in
             // Check if the sheet *was* presented and is *now* dismissed
             if oldValue == true && newValue == false {
                  print("Add Employee sheet dismissed, triggering refresh.")
                  Task {
                      await dataService.fetchAllEmployees()
                  }
             }
         }
        .task { // Fetch data when the view FIRST appears
            // Only fetch if the list is currently empty to avoid redundant calls on navigation
            if dataService.employees.isEmpty {
                print("EmployeeView appearing, task starting initial fetch...")
                await dataService.fetchAllEmployees()
            } else {
                 print("EmployeeView appearing, data already loaded.")
            }
        }
    }
    // MARK: - Subviews

    private var employeeContent: some View {
        VStack(spacing: 12) {
            // Updated search bar section
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search Employee", text: $searchText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Menu {
                    Button("All") { selectedStatus = nil }
                    Button("Available") { selectedStatus = "Available" }
                    Button("On-Duty") { selectedStatus = "On-Duty" }
                    Button("Not Available") { selectedStatus = "Not Available" }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
            
            Picker("Select Role", selection: $selectedSegment) {
                Text("Driver").tag(0)
                Text("Technician").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)

            employeeListView
        }
        .navigationTitle("Employee")
    }

    private var employeeListView: some View {
        List {
            ForEach(groupedEmployees.keys.sorted(), id: \.self) { key in
                Section(header: Text(key)) {
                    ForEach(groupedEmployees[key]!) { employee in
                        NavigationLink {
                            if employee.role == "Driver" {
                                DriverDetailView(driver: employee)
                            } else {
                                TechnicianDetailView(technician: employee)
                            }
                        } label: {
                            EmployeeRow(employee: employee)
                        }
                    }
                }
            }
        }
        .id(UUID()) // This forces the list to refresh when the sheet closes
        .listStyle(.insetGrouped)
    }

    private var addButton: some View {
        Button(action: {
            showAddEmployee = true
        }) {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.red)
                .shadow(radius: 6)
        }
        .padding(.trailing, 30)
        .padding(.bottom, 20)
    }

    // MARK: - Helper View

    private struct EmployeeRow: View {
        let employee: Employee

        var body: some View {
            HStack {
                Text(employee.name)
                Spacer()
                Text(employee.status)
                    .font(.caption)
                    .frame(minWidth: 100)
                    .frame(height: 28)
                    .padding(.horizontal, 8)
                    .background(statusColor(status: employee.status).opacity(0.2))
                    .foregroundColor(statusColor(status: employee.status))
                    .cornerRadius(14)
            }
        }

        private func statusColor(status: String) -> Color {
            switch status {
            case "Available":
                return .green
            case "On-Duty":
                return Color(red: 240/255, green: 184/255, blue: 0/255) // #F0B800
            case "Not Available":
                return .red
            default:
                return .gray
            }
        }
    }
}

