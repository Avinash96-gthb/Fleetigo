import SwiftUI
import CoreLocation

struct ChecklistItem: Identifiable {
    var id = UUID()
    var title: String
    var isChecked: Bool = false
}

struct PreTripChecklistView: View {
    // MARK: – State
    @State private var truckItems: [ChecklistItem] = [
        ChecklistItem(title: "Tire condition and pressure"),
        ChecklistItem(title: "Windshield & windows (clean and intact)"),
        ChecklistItem(title: "Headlights, tail lights, indicators, brake lights"),
        ChecklistItem(title: "Mirrors properly adjusted"),
        ChecklistItem(title: "Windshield washer fluid")
    ]

    @State private var driverItems: [ChecklistItem] = [
        ChecklistItem(title: "Valid driver’s license"),
        ChecklistItem(title: "Fleet ID badge / authorization"),
        ChecklistItem(title: "Insurance papers"),
        ChecklistItem(title: "Well-rested and alert"),
        ChecklistItem(title: "No impairing substances (drugs/alcohol)"),
        ChecklistItem(title: "Mobile fully charged or backup available")
    ]
    
    @State private var showCompletionAlert = false
    @State private var navigateToNavigationView = false
    @State private var showReportIssue = false
    let startCoordinate: CLLocationCoordinate2D?
    let endCoordinate: CLLocationCoordinate2D?
    let consignmentId: UUID?
    let vehichleId: UUID?
    let driverId: UUID?

    // Only true when every single checkbox (truck + driver) is ticked
    private var allChecked: Bool {
        (truckItems + driverItems).allSatisfy { $0.isChecked }
    }
    
    // Computed list of titles still unchecked
    private var uncheckedTitles: [String] {
        (truckItems + driverItems)
            .filter { !$0.isChecked }
            .map { $0.title }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#B5FFDF"), location: 0.0),
                        .init(color: Color.white, location: 0.20)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Subtitle under the large navigation title
                        Text("Please perform these self checks before starting your trip.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 8)

                        checklistSection(title: "Truck Inspection", items: $truckItems)
                        checklistSection(title: "Driver Inspection", items: $driverItems)

                        // Hidden link for programmatic navigation to TripNavigationView
                        NavigationLink(
                            destination: TripNavigationView(consignmentId: consignmentId, vehicleId: vehichleId, driverId: driverId, startCoordinate: startCoordinate, endCoordinate: endCoordinate)
                                .onAppear { // Log when TripNavigationView appears
                                         print("TripNavigationView: Received StartCoord: \(startCoordinate?.latitude ?? -999), \(startCoordinate?.longitude ?? -999)")
                                         print("TripNavigationView: Received EndCoord: \(endCoordinate?.latitude ?? -999), \(endCoordinate?.longitude ?? -999)")
                                    },
                            isActive: $navigateToNavigationView
                        ) {
                            EmptyView()
                        }
                        
                        // Hidden link for programmatic navigation to ReportIssueView
                        NavigationLink(
                            destination: ReportIssueView(uncheckedItems: uncheckedTitles, consignmentId: consignmentId, vehichleId: vehichleId, driverId: driverId),
                            isActive: $showReportIssue
                        ) {
                            EmptyView()
                        }

                        // Start Trip button, disabled until allChecked == true
                        Button {
                            showCompletionAlert = true
                        } label: {
                            Text("Start Trip")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    allChecked
                                        ? Color(hex: "#25A36B")
                                        : Color(hex: "#25A36B").opacity(0.5)
                                )
                                .cornerRadius(12)
                        }
                        .disabled(!allChecked)
                        .padding(.top, 16)
                        .alert("Pre-Trip Complete", isPresented: $showCompletionAlert) {
                            Button("OK", role: .cancel) {
                                navigateToNavigationView = true
                            }
                        } message: {
                            Text("All checks completed successfully.")
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                }
            }
            // ←– Native nav bar with large title and system back button –→
            .navigationTitle("Checklist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Right: Report Issue button, disabled if there are no unchecked items
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Report Issue") {
                        showReportIssue = true
                    }
                    .disabled(uncheckedTitles.isEmpty)
                    .foregroundColor(Color(hex: "#25A36B"))
                }
            }
        }
    }
    
    // MARK: – Checklist Section Builder
    @ViewBuilder
    private func checklistSection(
        title: String,
        items: Binding<[ChecklistItem]>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 12) {
                    Button {
                        items[index].wrappedValue.isChecked.toggle()
                    } label: {
                        Image(
                            systemName: items[index].wrappedValue.isChecked
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#25A36B"))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text(items[index].wrappedValue.title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}


