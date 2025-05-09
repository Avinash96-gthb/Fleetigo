// VehicleDetailView.swift
import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) { // Add spacing between sections

                // MARK: - Core Details Section
                DetailSection(title: "Vehicle Information") {
                    VStack(alignment: .leading, spacing: 12) { // Consistent spacing for rows
                        // Using the reusable DetailRow for alignment
                        DetailRow(label: "License Plate", value: vehicle.licensePlateNo)
                        DetailRow(label: "Type", value: vehicle.type)
                        DetailRow(label: "Model", value: vehicle.model)
                        DetailRow(label: "Fastag No.", value: vehicle.fastagNo.isEmpty ? "N/A" : vehicle.fastagNo)
                        // Assuming 'createdAt' is a String as per the Vehicle struct provided earlier.
                        // If it becomes a Date, format it appropriately.
                        DetailRow(label: "Added On", value: formattedCreationDate(vehicle.createdAt))
                    }
                }
                .padding(.horizontal) // Add horizontal padding to sections

                // MARK: - Status Section
                DetailSection(title: "Current Status") {
                     HStack { // Center the status pill
                        Spacer()
                        statusPill(for: vehicle.status)
                        Spacer()
                     }
                     .padding(.vertical, 8) // Add some vertical padding around the pill
                }
                .padding(.horizontal)

                Spacer() // Push content up if ScrollView content is short
            }
            .padding(.vertical) // Add vertical padding to the main VStack content
        }
        .navigationTitle(vehicle.licensePlateNo) // Use license plate as title
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea()) // Use a standard grouped background
    }

    // MARK: - Helper Functions

    /// Formats the creation date string (assuming ISO 8601 format)
    private func formattedCreationDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Handle potential fractional seconds
        
        if let date = isoFormatter.date(from: dateString) {
             let displayFormatter = DateFormatter()
             displayFormatter.dateStyle = .medium
             displayFormatter.timeStyle = .short
             return displayFormatter.string(from: date)
        }
        
        // Fallback for simple date format if ISO parsing fails
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        if let date = simpleFormatter.date(from: dateString) {
             let displayFormatter = DateFormatter()
             displayFormatter.dateStyle = .medium
             displayFormatter.timeStyle = .none // Don't show time if only date was parsed
             return displayFormatter.string(from: date)
        }
        
        return "N/A" // Return N/A if parsing fails
    }

    /// Creates the status pill view.
    private func statusPill(for status: Vehicle.VehicleStatus) -> some View {
        Text(status.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
            .font(.callout.weight(.semibold)) // Slightly larger font
            .foregroundColor(statusColorForeground(for: status))
            .padding(.horizontal, 14) // More padding
            .padding(.vertical, 6)
            .background(statusColorBackground(for: status))
            .clipShape(Capsule())
    }

    // Helper for status pill background color
    private func statusColorBackground(for status: Vehicle.VehicleStatus) -> Color {
        switch status {
        case .available: return Color.green.opacity(0.15)
        case .onDuty: return Color.blue.opacity(0.15)
        case .garage: return Color.orange.opacity(0.15)
        }
    }

    // Helper for status pill foreground color
    private func statusColorForeground(for status: Vehicle.VehicleStatus) -> Color {
         switch status {
         case .available: return Color.green
         case .onDuty: return Color.blue
         case .garage: return Color.orange
         }
     }
}

//// MARK: - Reusable Detail Section & Row (Ensure these are defined or accessible)
//
//// Reusable Detail Section View (Using the cleaner version)
//struct DetailSection<Content: View>: View {
//    let title: String
//    @ViewBuilder let content: Content
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(title)
//                .font(.title3.weight(.semibold))
//                .foregroundColor(.primary)
//                .padding(.bottom, 4) // Space below title
//
//            content // Content provided by the caller
//        }
//        .padding() // Padding inside the card
//        .background(Color(UIColor.secondarySystemGroupedBackground)) // Card background
//        .cornerRadius(12)
//    }
//}
//
//// Reusable Detail Row View (Using the cleaner version)
//struct DetailRow: View {
//    let label: String
//    let value: String
//
//    var body: some View {
//        HStack(alignment: .top) {
//            Text(label)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .frame(width: 120, alignment: .leading) // Consistent label width
//            Text(value)
//                .font(.subheadline)
//                .frame(maxWidth: .infinity, alignment: .leading) // Allow value to wrap
//        }
//        .padding(.vertical, 2) // Minimal vertical padding
//    }
//}
//
//
//// MARK: - Preview
//
