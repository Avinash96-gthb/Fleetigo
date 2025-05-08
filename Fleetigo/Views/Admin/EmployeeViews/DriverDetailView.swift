import SwiftUI

struct DriverDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showLicenseImage = false
    @State private var showAadhaarImage = false
    
    let driver: Employee
    let driverImage: Image = Image(systemName: "person.crop.circle.fill")
    let licenseImage: Image
    let aadhaarImage: Image
    
    let licenseExpiry = "15 May 2027"
    
    
    
    init(driver: Employee) {
        self.driver = driver
        if Bundle.main.path(forResource: "license_photo", ofType: nil) != nil {
            self.licenseImage = Image("license_photo")
        } else {
            self.licenseImage = Image(systemName: "doc.fill")
        }
        if Bundle.main.path(forResource: "aadhaar_photo", ofType: nil) != nil {
            self.aadhaarImage = Image("aadhaar_photo")
        } else {
            self.aadhaarImage = Image(systemName: "doc.fill")
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Section - Horizontal Layout
                HStack(alignment: .center, spacing: 16) {
                    driverImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(driver.name)
                            .font(.title2)
                            .foregroundColor(.primary)
                        
                        Text(driver.location ?? "Not provided")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", driver.rating ?? 0.0))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Earnings Card - Gray Style
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack {
                            Text("Total Trips")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(driver.totalTrips ?? 0)")
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        VStack {
                            Text("Total Distance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(driver.totalDistance ?? 0) Km")
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        VStack {
                            Text("Experience")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(driver.experience ?? 0) ?? "not available")
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Contact Info Cards
                VStack(spacing: 12) {
                    InfoCard(title: "Contact Number", value: driver.contactNumber ?? "Not provided", icon: "phone.fill")
                    InfoCard(title: "Mail ID", value: driver.email ?? "Not provided", icon: "envelope.fill")
                }
                .padding(.horizontal)
                
                // License and Aadhaar Details Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("License and Aadhaar Details")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    // License Details
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("License Number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(driver.licenseNumber ?? "Not provided")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Expiry Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(licenseExpiry)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showLicenseImage = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "doc.text.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("View")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .accessibilityLabel("View driver license")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Aadhaar Details
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aadhaar Number")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(driver.aadhaarNumber ?? "Not provided")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            showAadhaarImage = true
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: "doc.text.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                Text("View")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .accessibilityLabel("View Aadhaar document")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Trip History
                VStack(alignment: .leading, spacing: 12) {
                    Text("History of Trips")
                        .font(.headline)
                        .padding(.horizontal)
                    
//                    ForEach(tripHistory, id: \.id) { trip in
//                        TripCard(trip: trip)
//                    }
                }
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showLicenseImage) {
            NavigationStack {
                VStack {
                    licenseImage
                        .resizable()
                        .scaledToFit()
                        .padding()
                    
                    Spacer()
                }
                .navigationTitle("Driver License")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showLicenseImage = false
                        }
                        .foregroundColor(.blue)
                        .accessibilityLabel("Close license viewer")
                    }
                }
            }
        }
        .sheet(isPresented: $showAadhaarImage) {
            NavigationStack {
                VStack {
                    aadhaarImage
                        .resizable()
                        .scaledToFit()
                        .padding()
                    
                    Spacer()
                }
                .navigationTitle("Aadhaar Document")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showAadhaarImage = false
                        }
                        .foregroundColor(.blue)
                        .accessibilityLabel("Close Aadhaar viewer")
                    }
                }
            }
        }
        .navigationTitle("Driver Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Driver List")
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                }
                .accessibilityLabel("Back to employee list")
            }
        }
    }
    
//    private func parseExperience(_ experience: Int?) -> Double {
//        guard let experience = experience else { return 0.0 }
//        let cleaned = experience.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
//        return Double(cleaned) ?? 0.0
//    }
}

//struct InfoCard: View {
//    let title: String
//    let value: String
//    let icon: String
//    
//    var body: some View {
//        HStack {
//            Image(systemName: icon)
//                .foregroundColor(.blue)
//            VStack(alignment: .leading, spacing: 4) {
//                Text(title)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                Text(value)
//                    .font(.body)
//                    .foregroundColor(.primary)
//            }
//        }
//        .padding()
//        .background(Color(.systemGray6))
//        .cornerRadius(12)
//    }
//}

struct TripCard: View {
    let trip: Trip
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(trip.dropLocation)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text("Destination: \(trip.dropLocation)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "car.fill")
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
