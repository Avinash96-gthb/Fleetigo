//import SwiftUI
//
//struct VehicleCard: View {
//    let vehicle: Vehicle
//    
//    var body: some View {
//        HStack {
//            vehicleImage
//            vehicleDetails
//            Spacer()
//            Image(systemName: "chevron.right")
//                .foregroundColor(Color(hex: "#FE6767"))
//        }
//        .padding()
//        .background(Color.white)
//        .cornerRadius(12)
//        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
//    }
//    
//    private var vehicleImage: some View {
//        Group {
//            if let imageUrl = vehicle.imageUrl, let url = URL(string: imageUrl) {
//                AsyncImage(url: url) { phase in
//                    switch phase {
//                    case .success(let image):
//                        image.resizable()
//                            .aspectRatio(contentMode: .fill)
//                    case .failure:
//                        placeholderImage
//                    case .empty:
//                        ProgressView()
//                    @unknown default:
//                        placeholderImage
//                    }
//                }
//            } else {
//                placeholderImage
//            }
//        }
//        .frame(width: 80, height: 80)
//        .cornerRadius(8)
//    }
//    
//    private var placeholderImage: some View {
//        Image(systemName: "car.fill")
//            .resizable()
//            .scaledToFit()
//            .foregroundColor(.gray)
//            .background(Color(.systemGray5))
//    }
//    
//    private var vehicleDetails: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(vehicle.number)
//                .font(.headline.bold())
//                .foregroundColor(Color(hex: "#404040"))
//            detailRow(label: "Type:", value: vehicle.type)
//            detailRow(label: "Model:", value: vehicle.model)
//            detailRow(label: "License Plate:", value: vehicle.licensePlate)
//            if let fastagNo = vehicle.fastagNo {
//                detailRow(label: "Fastag No:", value: fastagNo)
//            }
//        }
//    }
//    
//    private func detailRow(label: String, value: String) -> some View {
//        HStack {
//            Text(label)
//                .font(.subheadline)
//                .foregroundColor(Color(hex: "#767676"))
//            Text(value)
//                .font(.subheadline)
//                .foregroundColor(Color(hex: "#767676"))
//        }
//    }
//}

import SwiftUI

struct VehicleCard: View {
    let vehicle: Vehicle
    
    var body: some View {
        HStack {
            vehicleImage
            vehicleDetails
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Color(hex: "#FE6767"))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var vehicleImage: some View {
        Group {
            if let imageData = vehicle.imageData, !imageData.isEmpty {
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                } else {
                    placeholderImage
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: 80, height: 80)
        .cornerRadius(8)
    }
    
    private var placeholderImage: some View {
        Image(systemName: "car.fill")
            .resizable()
            .scaledToFit()
            .foregroundColor(.gray)
            .background(Color(.systemGray5))
    }
    
    private var vehicleDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(vehicle.licensePlateNo)
                .font(.headline.bold())
                .foregroundColor(Color(hex: "#404040"))
            detailRow(label: "Type:", value: vehicle.type)
            detailRow(label: "Model:", value: vehicle.model)
            detailRow(label: "License Plate:", value: vehicle.licensePlateNo)
            detailRow(label: "Fastag No:", value: vehicle.fastagNo)
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color(hex: "#767676"))
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color(hex: "#767676"))
        }
    }
}
