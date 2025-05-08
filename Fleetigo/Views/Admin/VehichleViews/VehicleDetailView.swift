import SwiftUI

struct VehicleDetailView: View {
    let vehicle: Vehicle
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                vehicleImage
                Group {
                    detailItem("Vehicle ID", value: vehicle.licensePlateNo)
                    detailItem("Type", value: vehicle.type ?? "N/A")
                    detailItem("Model", value: vehicle.model ?? "N/A")
                    detailItem("License Plate", value: vehicle.licensePlateNo ?? "N/A")
                    detailItem("Fastag No.", value: vehicle.fastagNo)
                    detailItem("Status", value: vehicle.status.rawValue)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(vehicle.licensePlateNo)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var vehicleImage: some View {
        Group {
            if let imageData = vehicle.imageData, !imageData.isEmpty {
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                } else {
                    placeholderImage
                }
            } else {
                placeholderImage
            }
        }
        .frame(height: 200)
    }
    
    private var placeholderImage: some View {
        Image(systemName: "car.fill")
            .resizable()
            .scaledToFit()
            .frame(height: 200)
            .foregroundColor(.gray)
            .background(Color(.systemGray5))
            .cornerRadius(10)
    }
    
    private func detailItem(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
        .padding(.vertical, 8)
    }
}
