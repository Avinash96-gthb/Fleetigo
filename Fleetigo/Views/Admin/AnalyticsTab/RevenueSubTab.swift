import SwiftUI
import Charts

struct RevenueSubTab: View {
    @ObservedObject var viewModel: AnalyticsViewModel
    @State private var selectedSegment = 0
    @State private var animateCharts = false
    private let segments = ["This Month", "This Year", "Past Month"]
    @Environment(\.colorScheme) var colorScheme
    
    // 2025 Design System Colors - Centralized for consistency
    private let designColors = DesignColors()
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        ZStack {
            // Background matches ExpenditureSubTab
            Color(isDarkMode ? .black : .init(hex: "#F8F9FA"))
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Modern segment control
                    segmentControl
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Card-based data visualization
                    dataVisualizationCard
                    
                    // Summary stats before details
                    summaryStatsView
                    
                    // Modern list of daily revenues
                    dailyRevenueListView
                        .padding(.bottom, 20)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Revenue Details")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateCharts = true
            }
        }
    }
    
    // Modern segmented control with pill indicator
    private var segmentControl: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(isDarkMode ? Color(hex: "#1C1C1E") : Color.white)
                .frame(height: 52)
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 6)
            
            HStack(spacing: 0) {
                ForEach(0..<segments.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            selectedSegment = index
                        }
                    }) {
                        Text(segments[index])
                            .font(.system(size: 16, weight: selectedSegment == index ? .semibold : .medium))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(selectedSegment == index ? .white : isDarkMode ? .white.opacity(0.85) : .black.opacity(0.7))
                            .background(
                                Group {
                                    if selectedSegment == index {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [designColors.accentColor, designColors.tertiaryAccentColor]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    } else {
                                        Color.clear
                                    }
                                }
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(6)
        }
    }
    
    // Modern visualization card styled like ExpenditureSubTab
    private var dataVisualizationCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text(segments[selectedSegment])
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "#1A1C1E"))
                
                Group {
                    switch selectedSegment {
                    case 0: thisMonthBarGraph
                    case 1: thisYearBarGraph
                    case 2: pastMonthBarGraph
                    default: thisMonthBarGraph
                    }
                }
                .frame(height: 300)
                .animation(.easeInOut(duration: 0.5), value: selectedSegment)
            }
        }
    }
    
    // Summary statistics with modern visualization
    private var summaryStatsView: some View {
        HStack(spacing: 16) {
            statCard(
                title: "Total",
                value: "$\(String(format: "%.0f", totalRevenue))",
                icon: "creditcard.fill",
                color: designColors.accentColor
            )
            
            statCard(
                title: "Average",
                value: "$\(String(format: "%.0f", averageRevenue))",
                icon: "chart.bar.fill",
                color: designColors.secondaryAccentColor
            )
        }
        .padding(.horizontal)
    }
    
    // Modern stat card styled like ExpenditureSubTab
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isDarkMode ? .white.opacity(0.7) : Color(hex: "#71727A"))
                }
                
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isDarkMode ? .white : Color(hex: "#1A1C1E"))
            }
        }
    }
    
    // Modern daily revenues list
    private var dailyRevenueListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Breakdown")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isDarkMode ? .white : Color(hex: "#1A1C1E"))
                .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(filteredDailyData) { data in
                    RevenueDayCard(data: data, designColors: designColors, maxRevenue: maxRevenue)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Computed properties for statistics
    private var totalRevenue: Double {
        filteredDailyData.reduce(0) { $0 + $1.value }
    }
    
    private var averageRevenue: Double {
        filteredDailyData.isEmpty ? 0 : totalRevenue / Double(filteredDailyData.count)
    }
    
    // Maximum revenue for progress bar scaling
    private var maxRevenue: Double {
        filteredDailyData.map { $0.value }.max() ?? 1500
    }
    
    // Filter daily data based on selected segment
    private var filteredDailyData: [RevenueData] {
        let calendar = Calendar.current
        switch selectedSegment {
        case 0: // This Month (April 2023)
            return viewModel.revenueData.filter {
                let components = calendar.dateComponents([.year, .month], from: $0.date)
                return components.year == 2023 && components.month == 4
            }.sorted { $0.date < $1.date }
        case 1: // This Year (2023)
            return viewModel.revenueData.filter {
                let components = calendar.dateComponents([.year], from: $0.date)
                return components.year == 2023
            }.sorted { $0.date < $1.date }
        case 2: // Past Month (March 2023)
            return viewModel.revenueData.filter {
                let components = calendar.dateComponents([.year, .month], from: $0.date)
                return components.year == 2023 && components.month == 3
            }.sorted { $0.date < $1.date }
        default:
            return viewModel.revenueData
        }
    }

    // Weekly Revenue Data Structure
    struct WeeklyRevenueData: Identifiable {
        let id = UUID()
        let weekStartDate: Date
        let value: Double
        let weekNumber: Int
    }

    // Monthly Revenue Data Structure
    struct MonthlyRevenueData: Identifiable {
        let id = UUID()
        let monthStartDate: Date
        let value: Double
    }

    // Filter and aggregate data for "This Month" (April 2023) into 4 weeks
    private var thisMonthData: [WeeklyRevenueData] {
        let calendar = Calendar.current
        let filteredData = viewModel.revenueData.filter { data in
            let components = calendar.dateComponents([.year, .month], from: data.date)
            return components.year == 2023 && components.month == 4
        }

        let monthStart = calendar.date(from: DateComponents(year: 2023, month: 4, day: 1))!
        let weekRanges = [
            (start: monthStart, end: calendar.date(byAdding: .day, value: 7, to: monthStart)!),
            (start: calendar.date(byAdding: .day, value: 8, to: monthStart)!, end: calendar.date(byAdding: .day, value: 14, to: monthStart)!),
            (start: calendar.date(byAdding: .day, value: 15, to: monthStart)!, end: calendar.date(byAdding: .day, value: 21, to: monthStart)!),
            (start: calendar.date(byAdding: .day, value: 22, to: monthStart)!, end: calendar.date(byAdding: .day, value: 30, to: monthStart)!)
        ]

        var weeklyData: [WeeklyRevenueData] = []
        for (index, range) in weekRanges.enumerated() {
            let weekValue = filteredData
                .filter { $0.date >= range.start && $0.date <= range.end }
                .reduce(0.0) { $0 + $1.value }
            weeklyData.append(WeeklyRevenueData(weekStartDate: range.start, value: weekValue, weekNumber: index + 1))
        }

        return weeklyData
    }

    // Filter and aggregate data for "Past Month" (March 2023) into 4 weeks
    private var pastMonthData: [WeeklyRevenueData] {
        let calendar = Calendar.current
        let filteredData = viewModel.revenueData.filter { data in
            let components = calendar.dateComponents([.year, .month], from: data.date)
            return components.year == 2023 && components.month == 3
        }

        let monthStart = calendar.date(from: DateComponents(year: 2023, month: 3, day: 1))!
        let weekRanges = [
            (start: monthStart, end: calendar.date(byAdding: .day, value: 7, to: monthStart)!),
            (start: calendar.date(byAdding: .day, value: 8, to: monthStart)!, end: calendar.date(byAdding: .day, value: 14, to: monthStart)!),
            (start: calendar.date(byAdding: .day, value: 15, to: monthStart)!, end: calendar.date(byAdding: .day, value: 21, to: monthStart)!),
            (start: calendar.date(byAdding: .day, value: 22, to: monthStart)!, end: calendar.date(byAdding: .day, value: 31, to: monthStart)!)
        ]

        var weeklyData: [WeeklyRevenueData] = []
        for (index, range) in weekRanges.enumerated() {
            let weekValue = filteredData
                .filter { $0.date >= range.start && $0.date <= range.end }
                .reduce(0.0) { $0 + $1.value }
            weeklyData.append(WeeklyRevenueData(weekStartDate: range.start, value: weekValue, weekNumber: index + 1))
        }

        return weeklyData
    }

    // Filter and aggregate data for "This Year" (2023) into monthly totals
    private var thisYearData: [MonthlyRevenueData] {
        let calendar = Calendar.current
        let filteredData = viewModel.revenueData.filter { data in
            let components = calendar.dateComponents([.year], from: data.date)
            return components.year == 2023
        }

        var monthlyData: [Date: Double] = [:]
        for data in filteredData {
            let components = calendar.dateComponents([.year, .month], from: data.date)
            let monthStart = calendar.date(from: components)!
            monthlyData[monthStart, default: 0] += data.value
        }

        return monthlyData.map { (monthStart, value) in
            MonthlyRevenueData(monthStartDate: monthStart, value: value)
        }.sorted { $0.monthStartDate < $1.monthStartDate }
    }

    // Create a consistent chart style for all charts
    private func createChartYAxis() -> some AxisContent {
        AxisMarks(position: .leading) { value in
            if let revenue = value.as(Double.self) {
                AxisGridLine()
                    .foregroundStyle(Color(hex: "#71727A").opacity(isDarkMode ? 0.5 : 0.3))
                AxisValueLabel("$\(Int(revenue / 1000))k")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "#71727A"))
            }
        }
    }

    // Bar Graph for "This Month"
    private var thisMonthBarGraph: some View {
        Chart(thisMonthData) { data in
            BarMark(
                x: .value("Week", "Week \(data.weekNumber)"),
                y: .value("Revenue", animateCharts ? data.value : 0)
            )
            .cornerRadius(8)
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [designColors.accentColor, designColors.tertiaryAccentColor]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "#71727A"))
                AxisGridLine()
                    .foregroundStyle(Color(hex: "#71727A").opacity(isDarkMode ? 0.5 : 0.3))
            }
        }
        .chartYAxis(content: createChartYAxis)
        .chartYScale(domain: [0, 6000])
    }

    // Bar Graph for "This Year"
    private var thisYearBarGraph: some View {
        Chart(thisYearData) { data in
            BarMark(
                x: .value("Month", data.monthStartDate, unit: .month),
                y: .value("Revenue", animateCharts ? data.value : 0)
            )
            .cornerRadius(8)
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [designColors.accentColor, designColors.tertiaryAccentColor]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "#71727A"))
                AxisGridLine()
                    .foregroundStyle(Color(hex: "#71727A").opacity(isDarkMode ? 0.5 : 0.3))
            }
        }
        .chartYAxis(content: createChartYAxis)
        .chartYScale(domain: [0, 15000])
    }

    // Bar Graph for "Past Month"
    private var pastMonthBarGraph: some View {
        Chart(pastMonthData) { data in
            BarMark(
                x: .value("Week", "Week \(data.weekNumber)"),
                y: .value("Revenue", animateCharts ? data.value : 0)
            )
            .cornerRadius(8)
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [designColors.accentColor, designColors.tertiaryAccentColor]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(hex: "#71727A"))
                AxisGridLine()
                    .foregroundStyle(Color(hex: "#71727A").opacity(isDarkMode ? 0.5 : 0.3))
            }
        }
        .chartYAxis(content: createChartYAxis)
        .chartYScale(domain: [0, 6000])
    }
}

// Modern daily revenue card styled like ExpenditureSubTab
struct RevenueDayCard: View {
    let data: RevenueData
    let designColors: DesignColors
    let maxRevenue: Double
    @Environment(\.colorScheme) var colorScheme
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    // Get revenue category icon and color
    private var categoryDetails: (icon: String, color: Color) {
        let value = data.value
        if value > 1000 {
            return ("dollarsign.circle.fill", Color(hex: "#34C759"))
        } else if value > 500 {
            return ("dollarsign.circle.fill", Color(hex: "#34C759"))
        } else if value > 200 {
            return ("dollarsign.circle.fill", Color(hex: "#34C759"))
        } else if value > 100 {
            return ("dollarsign.circle.fill", Color(hex: "#34C759"))
        } else {
            return ("dollarsign.circle.fill", Color(hex: "#34C759"))
        }
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(isDarkMode ? Color(hex: "#1C1C1E") : .white)
                .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 6)
            
            HStack(spacing: 16) {
                // Date container with accent gradient
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    designColors.accentColor.opacity(0.8),
                                    designColors.accentColor.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 70)
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text(formatDate(component: .day))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(formatDate(format: "MMM"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(formatDate(format: "EEEE"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isDarkMode ? .white : Color(hex: "#1A1C1E"))
                        
                        Spacer()
                        
                        // Category icon
                        Image(systemName: categoryDetails.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(categoryDetails.color)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(categoryDetails.color.opacity(0.15))
                            )
                    }
                    
                    HStack(alignment: .center) {
                        Text(formatDate(format: "yyyy"))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(isDarkMode ? Color(hex: "#E1E2E6") : Color(hex: "#71727A"))
                        
                        Spacer()
                        
                        Text("$\(String(format: "%.2f", data.value))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(categoryDetails.color)
                    }
                    
                    // Progress indicator based on revenue amount
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(hex: "#71727A").opacity(0.2))
                                .frame(height: 4)
                            
                            // Filled portion
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [categoryDetails.color, categoryDetails.color.opacity(0.5)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: maxRevenue > 0 ? min(CGFloat(data.value) / maxRevenue * geometry.size.width, geometry.size.width) : 0, height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.top, 4)
                }
            }
            .padding(16)
        }
    }
    
    // Helper function to format dates consistently
    private func formatDate(format: String? = nil, component: Calendar.Component? = nil) -> String {
        if let component = component {
            let calendar = Calendar.current
            let value = calendar.component(component, from: data.date)
            return "\(value)"
        } else if let format = format {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            return dateFormatter.string(from: data.date)
        }
        return ""
    }
}


