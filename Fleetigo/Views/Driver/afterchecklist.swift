import SwiftUI
import CoreLocation

struct CheckItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    var isChecked: Bool = false

    static func == (lhs: CheckItem, rhs: CheckItem) -> Bool {
        lhs.id == rhs.id && lhs.isChecked == rhs.isChecked
    }
}

struct PostTripChecklistView: View {
    @EnvironmentObject var tripManager: TripManager
    @Environment(\.dismiss) private var dismiss

    @State private var truckChecks = [
        CheckItem(title: "Tire condition and pressure (check for damage/wear)"),
        CheckItem(title: "Windshield & windows (clean and intact)"),
        CheckItem(title: "All lights functioning (headlights, brake lights, indicators)"),
        CheckItem(title: "Mirrors clean and properly adjusted"),
        CheckItem(title: "No visible leaks under vehicle")
    ]

    @State private var driverChecks = [
        CheckItem(title: "Fleet ID badge stored securely"),
        CheckItem(title: "All personal belongings removed from cab"),
        CheckItem(title: "Cab interior clean and organized"),
        CheckItem(title: "All valuables secured"),
        CheckItem(title: "Defect reports filed if needed")
    ]

    @State private var allChecksComplete = false
    @State private var showCompletionAlert = false
    @State private var isAtEndLocation = false
    @State private var showReportIssue = false
    @State private var navigateToNoTrip = false
    let consignmentId: UUID?
    let vehichleId: UUID?
    let driverId: UUID?

    // No longer a static constant
    // private let endCoordinate = CLLocationCoordinate2D(
    //     latitude: 43.7829,
    //     longitude: -79.1854
    // )

    private var uncheckedTitles: [String] {
        (truckChecks + driverChecks)
            .filter { !$0.isChecked }
            .map { $0.title }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    mainContent
                        .padding(.horizontal, 16)
                }
            }
            .navigationTitle("Checklist")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                leadingToolbarItem
                trailingToolbarItem
            }
            .onChange(of: truckChecks) { _ in validateChecks() }
            .onChange(of: driverChecks) { _ in validateChecks() }
            .onAppear { checkDriverLocation() }
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "#B1CEFF"), location: 0.0),
                .init(color: Color.white, location: 0.20)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Please perform these post-trip checks to conclude your consignment.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 8)

            checklistSection(title: "Truck Inspection", items: $truckChecks)
            checklistSection(title: "Driver Inspection", items: $driverChecks)

            NavigationLink(
                destination: ReportIssueView(uncheckedItems: uncheckedTitles, consignmentId: consignmentId, vehichleId: vehichleId, driverId: driverId),
                isActive: $showReportIssue
            ) {
                EmptyView()
            }

            NavigationLink(
                destination: NoTripView()
                    .environmentObject(tripManager),
                isActive: $navigateToNoTrip
            ) {
                EmptyView()
            }

            endTripButton
                .padding(.top, 16)
                .alert("Post-Trip Complete", isPresented: $showCompletionAlert) {
                    Button("OK", role: .cancel) {
                        if let tripDetails = tripManager.currentTripDetails {
                            Task {
                                await tripManager.endCurrentTrip(driverId: tripDetails.base.driverId, vehicleId: tripDetails.base.vehicleId)
                                navigateToNoTrip = true
                            }
                        } else {
                            print("Error: Could not retrieve trip details to end trip.")
                            navigateToNoTrip = true // Still navigate, but without updating status
                            // Optionally show an error message to the user
                        }
                    }
                } message: {
                    Text("All post-trip checks have been completed successfully.")
                }
        }
    }

    private var endTripButton: some View {
        Button {
            showCompletionAlert = true
        } label: {
            Text("End Trip")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    (allChecksComplete && isAtEndLocation)
                        ? Color(hex: "#4E8FFF")
                        : Color(hex: "#4E8FFF").opacity(0.5)
                )
                .cornerRadius(12)
        }
        .disabled(!(allChecksComplete && isAtEndLocation))
    }

    private var leadingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(Color(hex: "#4E8FFF"))
            }
        }
    }

    private var trailingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Report Issue") {
                showReportIssue = true
            }
            .disabled(uncheckedTitles.isEmpty)
            .foregroundColor(Color(hex: "#4E8FFF"))
        }
    }

    private func validateChecks() {
        allChecksComplete =
            truckChecks.allSatisfy { $0.isChecked } &&
            driverChecks.allSatisfy { $0.isChecked }
    }

    private func checkDriverLocation() {
        guard let endCoordinate = tripManager.currentTripDetails?.endCoordinate else {
            // Handle the case where endCoordinate is not available yet
            print("End coordinate not available.")
            isAtEndLocation = false
            return
        }

        // Simulate driver location (replace with actual location tracking)
        let driverLoc = CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude)
        let endLoc   = CLLocation(latitude: endCoordinate.latitude, longitude: endCoordinate.longitude)
        isAtEndLocation = driverLoc.distance(from: endLoc) <= 100
    }

    @ViewBuilder
    private func checklistSection(
        title: String,
        items: Binding<[CheckItem]>
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            ForEach(items.indices, id: \.self) { idx in
                HStack(alignment: .top, spacing: 12) {
                    Button {
                        items[idx].wrappedValue.isChecked.toggle()
                    } label: {
                        let isCurrentlyChecked = items[idx].wrappedValue.isChecked
                        let imageName = isCurrentlyChecked ? "checkmark.circle.fill" : "circle"
                        Image(systemName: imageName)
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#4E8FFF"))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Text(items[idx].wrappedValue.title)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
