// VehicleCard.swift
import SwiftUI

struct VehicleCard: View {
    let vehicle: Vehicle

    var body: some View {
        HStack(spacing: 15) {
            // Image Section with Placeholder Logic
            vehicleImage
                .resizable()
                .aspectRatio(contentMode: .fill) // Fill the frame
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10)) // Rounded corners for the image
                .overlay( // Optional: subtle border
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            // Details Section
            VStack(alignment: .leading, spacing: 6) {
                Text(vehicle.licensePlateNo)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                HStack {
                     Image(systemName: "truck.box.fill") // Icon for type
                         .foregroundColor(.secondary)
                     Text(vehicle.type)
                         .font(.subheadline)
                         .foregroundColor(.secondary)
                }
                 
                Text(vehicle.model)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Status Pill
                Text(vehicle.status.rawValue.capitalized.replacingOccurrences(of: "_", with: " "))
                    .font(.caption.weight(.medium))
                    .foregroundColor(statusColorForeground(for: vehicle.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColorBackground(for: vehicle.status))
                    .clipShape(Capsule())
            }

            Spacer() // Pushes content to the left

            // Chevron for NavigationLink indication
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .padding(.trailing, 5)

        }
        .padding(12) // Padding inside the card
        .background(Color(UIColor.systemBackground)) // Adapts to light/dark mode
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2) // Softer shadow
    }

    // Computed property to determine the image
    private var vehicleImage: Image {
        if let imageData = vehicle.imageData, let uiImage = UIImage(data: imageData) {
            // If actual image data is available, use it
            return Image(uiImage: uiImage)
        } else {
            // Otherwise, use placeholder based on type
            switch vehicle.type.lowercased() {
            case "lcv":
                return Image("vehicle1") // Use vehicle1 for LCV
            case "mcv":
                return Image("vehicle6") // Use vehicle6 for MCV
            case "hcv":
                return Image("vehicle5") // Use vehicle5 for HCV
            default:
                return Image("vehicle1") // Default placeholder
            }
        }
    }

    // Helper for status pill background color
    private func statusColorBackground(for status: Vehicle.VehicleStatus) -> Color {
        switch status {
        case .available:
            return Color.green.opacity(0.15)
        case .onDuty:
            return Color.blue.opacity(0.15)
        case .garage:
            return Color.orange.opacity(0.15)
        }
    }

    // Helper for status pill foreground color
    private func statusColorForeground(for status: Vehicle.VehicleStatus) -> Color {
         switch status {
         case .available:
             return Color.green
         case .onDuty:
             return Color.blue
         case .garage:
             return Color.orange
         }
     }
}
