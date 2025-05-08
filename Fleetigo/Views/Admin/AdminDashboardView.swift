import SwiftUI
import MapKit
import CoreLocation
import Foundation


// MARK: - Data Models
struct Consignment: Identifiable, Codable {
    let internal_id: UUID?
    let id: String
    let type: ConsignmentType
    let vehichle_type: VehicleType
    var status: ConsignmentStatus
    let description: String
    let weight: String
    let dimensions: String
    let pickup_location: String
    let drop_location: String
    let pickup_date: Date
    let delivery_date: Date
    let sender_phone: String
    let recipient_name: String
    let recipient_phone: String
    let instructions: String?
    let created_at: Date?
    
    enum CodingKeys: String, CodingKey {
        case internal_id, id, type, status, description,
             weight, dimensions, pickup_location, drop_location,
             pickup_date, delivery_date, sender_phone, recipient_name,
             recipient_phone, instructions, created_at, vehichle_type
    }

    var identifier: UUID {
        return internal_id ?? UUID()
    }
}

enum ConsignmentType: String, CaseIterable, Codable  {
    case priority, medium, standard
}

enum ConsignmentStatus: String, Codable {
    case ongoing, completed
}



class TabRouter: ObservableObject {
    @Published var selectedTab: Int = 1
}

// MARK: - MainTabView
struct MainTabView: View {
    @StateObject private var tabRouter = TabRouter()
    @StateObject private var consignmentStore = ConsignmentStore()
    @StateObject private var vehicleViewModel = VehicleViewModel()
    @StateObject private var dataService = DataService()
    

    var body: some View {
        TabView(selection: $tabRouter.selectedTab) {
            NavigationStack {
                VehicleListView()
            }
                .tabItem { Label("Vehicle", systemImage: "steeringwheel") }
                .tag(0)
            NavigationStack {
                EmployeeView()
            }
                .tabItem { Label("Employee", systemImage: "person.text.rectangle.fill") }
                .tag(1)
            //
            NavigationStack {
                AnalyticsTab()
            }
            .tabItem { Label("Analytics", systemImage: "chart.xyaxis.line") }
            .tag(2)
            //
            NavigationStack {
                GarageTab()
                    .environmentObject(consignmentStore)
                    .environmentObject(tabRouter)
            }
            .tabItem { Label("Garage", systemImage: "wrench.fill") }
            .tag(3)
            //
            NavigationStack {
                ConsignmentView()
                    .environmentObject(consignmentStore)
                    .environmentObject(vehicleViewModel)
                    .environmentObject(dataService)
            }
            .tabItem { Label("Consignment", systemImage: "shippingbox.fill") }
            .tag(4)
        }
        .tint(.red)
        .environmentObject(tabRouter)
        .environmentObject(consignmentStore)
        .environmentObject(vehicleViewModel)
        .environmentObject(dataService)
    }
}

// MARK: - Consignment Management
class ConsignmentStore: ObservableObject {
    @Published var consignments: [Consignment] = []

    // Fetch consignments from Supabase
    func fetchConsignments() async {
        do {
            let fetchedConsignments = try await SupabaseManager.shared.fetchConsignments()
            DispatchQueue.main.async {
                self.consignments = fetchedConsignments
            }
        } catch {
            print("Failed to fetch consignments: \(error.localizedDescription)")
        }
    }

    // Add a consignment and append it to local store
    func addConsignment(_ consignment: Consignment) async {
        do {
            let created = try await SupabaseManager.shared.addConsignment(consignment: consignment)
            DispatchQueue.main.async {
                self.consignments.append(created)
            }
        } catch {
            print("Failed to add consignment: \(error.localizedDescription)")
        }
    }

    /// Create a consignment and its corresponding trip in Supabase
    func createConsignmentWithTrip(consignment: Consignment, driver: Employee, vehicle: Vehicle) async {
        do {
            // Step 1: Create the consignment
            let createdConsignment = try await SupabaseManager.shared.addConsignment(consignment: consignment)

            // Step 2: Create the trip
            let trip = Trip(
                id: nil,
                consignmentId: createdConsignment.internal_id!,
                driverId: driver.id,
                vehicleId: vehicle.id!,
                pickupLocation: createdConsignment.pickup_location,
                dropLocation: createdConsignment.drop_location,
                startTime: createdConsignment.pickup_date,
                endTime: createdConsignment.delivery_date,
                status: "ongoing", // 👈 Status is set to "ongoing"
                notes: createdConsignment.instructions,
                createdAt: nil
            )

            try await SupabaseManager.shared.addTrip(trip: trip)
            try await SupabaseManager.shared.updateVehicleStatus(vehicleId: vehicle.id!, newStatus: .onDuty)
            try await SupabaseManager.shared.updateDriverStatus(driverId: driver.id, newStatus: "On-Duty")

            // Step 3: Update local store
            DispatchQueue.main.async {
                self.consignments.append(createdConsignment)
            }

            print("✅ Successfully created consignment and trip and status updated.")
        } catch {
            print("❌ Failed to create consignment or trip: \(error.localizedDescription)")
        }
    }
}

struct ConsignmentView: View {
    @EnvironmentObject var store: ConsignmentStore
    @EnvironmentObject var vehicleViewModel: VehicleViewModel
    @EnvironmentObject var dataService: DataService
    @State private var selectedSegment = 0
    private let segments = ["Ongoing", "Completed"]

    var body: some View {
        ZStack {
            VStack {
                Picker("Filter", selection: $selectedSegment) {
                    ForEach(0..<segments.count, id: \.self) {
                        Text(segments[$0])
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List {
                    ForEach(filteredConsignments) { consignment in
                        ConsignmentRow(consignment: consignment)
                    }
                }
                .listStyle(.insetGrouped)
            }

            FloatingActionButton()
        }
        .navigationTitle("Consignment")
        .tint(.red)
        .onAppear {
            // Fetch consignments every time the view appears
            Task {
                await store.fetchConsignments()
            }
        }
    }

    var filteredConsignments: [Consignment] {
        store.consignments.filter {
            selectedSegment == 0 ? $0.status == .ongoing : $0.status == .completed
        }
    }
}

struct FloatingActionButton: View {
    @EnvironmentObject var store: ConsignmentStore
    @EnvironmentObject var vehicleViewModel: VehicleViewModel
    @EnvironmentObject var dataService: DataService
    
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                NavigationLink(destination: AddConsignmentScreen(vehicleViewModel: vehicleViewModel, dataService: dataService)
                               
                ) {
                    Image(systemName: "shippingbox.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                        .overlay(
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .offset(x: 12, y: 13)
                        )
                }
                .buttonStyle(.plain)
                .frame(width: 56, height: 56)
                .background(Color.red)
                .clipShape(Circle())
                .shadow(radius: 4)
                .padding(.bottom, 20)
                .padding(.trailing, 20)
            }
        }
    }
}


extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
