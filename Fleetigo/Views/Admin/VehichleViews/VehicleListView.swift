import SwiftUI

struct VehicleListView: View {
    @EnvironmentObject var viewModel: VehicleViewModel // ViewModel without fetch/add methods
    @State private var showingAddVehicle = false
    @State private var showingErrorAlert = false
    
    // Fetch vehicles when the view appears
    
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color(hex: "#FF6767").opacity(0.5), location: 0.0),
                                    .init(color: Color(hex: "#FF6767").opacity(0.3), location: 0.1),
                                    .init(color: Color(hex: "#FF6767").opacity(0.1), location: 0.3),
                                    .init(color: .clear, location: 0.4)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .ignoresSafeArea()
                VStack(spacing: 0) {
                    headerView
                    segmentedControl
                    vehicleList
                }
                if viewModel.isLoading {
                    loadingView
                }
                addButton
            }
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 5) }
            .sheet(isPresented: $showingAddVehicle) {
                             // Initialize AddVehicleView without the trailing closure
                             // as onSave parameter was removed in the previous fix.
                             // AddVehicleView should handle its own dismissal via @Environment(\.dismiss)
                             AddVehicleView()
                        }
            .alert(isPresented: $showingErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
            // Trigger the fetch when the view appears
            .task {
                await viewModel.fetchVehicles()
            }
        }
    }
    
    private var headerView: some View {
        VStack {
            HStack {
                Text("Vehicle")
                    .font(.largeTitle.bold())
                    .padding(.leading)
                Spacer()
            }
            .padding(.vertical, 8)

            HStack {
                NativeSearchBar(text: $viewModel.searchText)
                    .frame(height: 44)
                    .padding(.horizontal)

                Menu {
                    Button("All Types") { viewModel.clearVehicleTypes() }
                    ForEach(viewModel.uniqueVehicleTypes, id: \.self) { type in
                        Button(type) { viewModel.toggleVehicleType(type) }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.title2)
                        .padding(.trailing)
                }
            }
            .padding(.bottom, 8)
        }
    }
    
    private var segmentedControl: some View {
        Picker("Status", selection: $viewModel.selectedSegment) {
            Text("Available").tag(Vehicle.VehicleStatus.available)
            Text("On-Duty").tag(Vehicle.VehicleStatus.onDuty)
            Text("Garage").tag(Vehicle.VehicleStatus.garage)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .onChange(of: viewModel.selectedSegment) { _, _ in
            viewModel.filterVehicles()
        }
    }
    
    private var vehicleList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredVehicles) { vehicle in
                    NavigationLink(destination: VehicleDetailView(vehicle: vehicle)) {
                        VehicleCard(vehicle: vehicle)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    
    private var loadingView: some View {
        ProgressView()
            .scaleEffect(1.5)
            .padding()
            .background(Color(.systemBackground).opacity(0.8))
            .cornerRadius(10)
    }
    
    private var addButton: some View {
        Button(action: { showingAddVehicle = true }) {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .padding()
        }
        .accessibilityLabel("Add Vehicle")
        .padding([.trailing, .bottom], 16)
    }
}
