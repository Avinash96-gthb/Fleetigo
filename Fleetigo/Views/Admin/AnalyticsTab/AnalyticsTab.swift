import SwiftUI
import Charts

// MARK: - Analytics Tab View
struct AnalyticsTab: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @StateObject private var profileViewModel = ProfileViewModel()
    
    var body: some View {
        ZStack {
            // Background gradient with controlled fade before Analytics header
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
            
            // Existing content
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    fleetStatusSection
                    analyticsSection
                }
                .padding()
            }
            .onAppear {
                viewModel.fetchData()
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        HStack {
            NavigationLink(destination: ProfileView()) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.gray)
                    VStack(alignment: .leading) {
                        Text("Hello,")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#333333"))
                        Text(displayName)
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(Color(hex: "#FF6767"))
                        
                    }
                }
            }
            
            Spacer()
            
            NavigationLink(destination: NotificationView()) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(width: 35, height: 35)
                        .shadow(color: Color(hex: "#FF6767"), radius: 4, x: 0, y: 0)
                    Image(systemName: "bell.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
    
    private var displayName: String {
        switch profileViewModel.userRole {
        case .admin:
            return profileViewModel.adminProfile?.full_name ?? "Admin"
        case .driver:
            return profileViewModel.driverProfile?.name ?? "Driver"
        case .technician:
            return profileViewModel.technicianProfile?.name ?? "Technician"
        default:
            return "User"
        }
    }
    
    // MARK: - Fleet Status Section
    private var fleetStatusSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Fleet Status")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#4B4B4B"))
                .padding(.leading, 10) // Move only the header 10 points to the right
            HStack(spacing: 5) {
                CircularMetricView(title: "On-Duty", value: viewModel.fleetStatus.onDuty)
                CircularMetricView(title: "Available", value: viewModel.fleetStatus.available)
                CircularMetricView(title: "Servicing", value: viewModel.fleetStatus.servicing)
            }
        }
    }
    
    // MARK: - Analytics Section
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Analytics")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(Color(hex: "#4B4B4B"))
                .padding(.leading, 0) // Match fleetStatusSection leading
            revenueChart
            expenditureChart
        }
    }
    
    // MARK: - Notification View (add this at the bottom of the file)
    struct NotificationView: View {
        @AppStorage("isDarkMode") private var isDarkMode = false // Keep if used elsewhere
        @StateObject private var viewModel = NotificationViewModel()

        var body: some View {
            NavigationStack { // Use NavigationStack for title
                Group { // Use Group for conditional content
                    if viewModel.isLoading {
                        VStack { // Center ProgressView
                            Spacer()
                            ProgressView("Loading Notifications...")
                            Spacer()
                        }
                    } else if let errorMessage = viewModel.errorMessage {
                        VStack { // Center Error Message
                            Spacer()
                            Text("Error: \(errorMessage)")
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                            Button("Retry") {
                                Task { await viewModel.fetchNotifications() }
                            }
                            .padding(.top)
                            Spacer()
                        }
                    } else if viewModel.formattedNotifications.isEmpty {
                        VStack { // Center No Notifications Message
                            Spacer()
                            Text("No new notifications.")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(viewModel.formattedNotifications) { notificationItem in
                                VStack(alignment: .leading, spacing: 5) { // Increased spacing slightly
                                    Text(notificationItem.message)
                                        .font(.system(size: 15, weight: .medium)) // Slightly smaller for better fit
                                        .lineLimit(3) // Allow up to 3 lines for message

                                    // Display the original warning's timestamp formatted
                                    Text(notificationItem.originalWarning.displayTimestamp)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                                // Optional: Add tap action to navigate to consignment/trip details
                                // .onTapGesture {
                                //     navigateToWarningDetails(warning: notificationItem.originalWarning)
                                // }
                            }
                        }
                        .listStyle(.plain) // Plain style for a cleaner look
                        .refreshable { // Add pull-to-refresh
                            await viewModel.fetchNotifications()
                        }
                    }
                }
                .navigationTitle("Notifications")
                .navigationBarTitleDisplayMode(.inline) // Or .large if preferred
                .onAppear {
                    // Fetch notifications when the view appears if not already loaded
                    if viewModel.formattedNotifications.isEmpty && !viewModel.isLoading {
                        Task {
                            await viewModel.fetchNotifications()
                        }
                    }
                }
                // Optional: Add a toolbar button to manually refresh
                // .toolbar {
                //     ToolbarItem(placement: .navigationBarTrailing) {
                //         Button {
                //             Task { await viewModel.fetchNotifications() }
                //         } label: {
                //             Image(systemName: "arrow.clockwise")
                //         }
                //         .disabled(viewModel.isLoading)
                //     }
                // }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light) // Apply dark mode preference
        }

        // Placeholder for navigation if you add tap action
        // private func navigateToWarningDetails(warning: RouteDeviationWarning) {
        //     print("Navigate to details for warning related to trip: \(warning.trip_id)")
        //     // Implement navigation logic here, e.g., using a NavigationLink or changing a @State var
        // }
    }
    
    // MARK: - Monthly Revenue Data Struct
    struct MonthlyRevenueData: Identifiable {
        let id = UUID()
        let monthStartDate: Date
        let value: Double
    }
    
    // Helper function to group daily data into monthly data
    private func groupByMonth(_ data: [RevenueData]) -> [MonthlyRevenueData] {
        let calendar = Calendar.current
        var groupedData: [Date: Double] = [:]
        
        // Group data by the start of the month
        for entry in data {
            let components = calendar.dateComponents([.year, .month], from: entry.date)
            if let monthStart = calendar.date(from: components) { // Use if-let
                groupedData[monthStart, default: 0] += entry.value
            }
        }
        
        // Convert to MonthlyRevenueData
        return groupedData.map { (monthStart, value) in
            MonthlyRevenueData(monthStartDate: monthStart, value: value)
        }.sorted { $0.monthStartDate < $1.monthStartDate }
    }
    
    // MARK: - Revenue Chart
    private var revenueChart: some View {
        // Aggregate daily data into monthly data
        let monthlyData = groupByMonth(viewModel.revenueData)
        
        // Find the peak data point
        // Handle the case where monthlyData is empty to avoid a crash.
        let peakDataPoint = monthlyData.max(by: { $0.value < $1.value }) ?? MonthlyRevenueData(monthStartDate: Date(), value: 0)
        
        return VStack(alignment: .leading) {
            HStack {
                Text("Revenue")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: RevenueSubTab(viewModel: viewModel)) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(hex: "#FE6767"))
                        .frame(width: 8, height: 11)
                }
            }
            if !monthlyData.isEmpty { //check if monthly data is empty
                Chart(monthlyData) { data in
                    LineMark(
                        x: .value("Month", data.monthStartDate, unit: .month),
                        y: .value("Revenue", data.value)
                    )
                    .foregroundStyle(Color(hex: "#FF6767"))
                    .interpolationMethod(.catmullRom)
                    AreaMark(
                        x: .value("Month", data.monthStartDate, unit: .month),
                        y: .value("Revenue", data.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#FF6767").opacity(0.15), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    RuleMark(
                        x: .value("Month", peakDataPoint.monthStartDate, unit: .month),
                        yStart: .value("Revenue", 0), // Start at the bottom (X-axis)
                        yEnd: .value("Revenue", peakDataPoint.value) // End at the peak value
                    )
                    .foregroundStyle(.gray)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    PointMark(
                        x: .value("Month", peakDataPoint.monthStartDate, unit: .month),
                        y: .value("Revenue", peakDataPoint.value)
                    )
                    .foregroundStyle(Color(hex: "#FF6767")) // Red dot on top of the red line
                    .annotation(position: .top) {
                        Text("$\(Int(peakDataPoint.value))")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(4)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        // Removed AxisGridLine and AxisValueLabel to hide Y-axis numbers and grid
                    }
                }
                .frame(width: 317, height: 200)
            } else {
                Text("No revenue data available.")
                    .frame(width: 317, height: 200)
            }
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private var expenditureChart: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Expenditures")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: ExpenditureSubTab(viewModel: viewModel)) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(hex: "#FE6767"))
                        .frame(width: 8, height: 11)
                }
            }
            if !viewModel.expenditureData.isEmpty {
                HStack {
                    Chart(viewModel.expenditureData) { data in
                        SectorMark(
                            angle: .value("Percentage", data.value),
                            innerRadius: .ratio(0.5),
                            angularInset: 1
                        )
                        .foregroundStyle(by: .value("Category", data.category))
                    }
                    .chartForegroundStyleScale([
                        "Salary": Color(hex: "#FF6767"),
                        "Repairs": Color(hex: "#FA898B"),
                        "Expense": Color(hex: "#F4A79D")
                    ])
                    .chartLegend(.hidden)
                    .frame(width: 200, height: 150)
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 8) {
                    // Use the category names from the data
                    ForEach(viewModel.expenditureData) { data in
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(categoryColor(for: data.category))
                                .frame(width: 15, height: 15)
                            Text(data.category)
                                .font(.caption)
                                .foregroundColor(Color(hex: "#333333"))
                        }
                    }
                }
            } else {
                Text("No expenditure data available")
                    .frame(width: 335, height: 200)
            }
        }
        .frame(width: 335)
        .padding()
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // Helper function to get color for category
    private func categoryColor(for category: String) -> Color {
        switch category {
        case "Salary": return Color(hex: "#FF6767")
        case "Repairs": return Color(hex: "#FA898B")
        case "Expense": return Color(hex: "#F4A79D")
        default: return .gray
        }
    }
}
// MARK: - Circular Metric View
struct CircularMetricView: View {
    let title: String
    let value: Int
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .frame(width: 100, height: 127)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 0)
                VStack(spacing: 10) {
                    Text("\(value)")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(Color(hex: "#FE6767"))
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: "#404040"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }
}

