import Foundation

struct Employee: Identifiable, Hashable {
    // Use the id from the database, ensure it's populated during mapping
    let id: UUID
    var name: String // DB allows null, handle in mapping if needed
    var status: String // Needs to be assigned (e.g., default "Available")
    var role: String // "Driver" or "Technician", assigned during mapping
    var email: String // DB is NOT NULL
    var experience: Int? // Match DB type 'integer'
    var specialty: String? // Technician only
    var consignmentId: String? // Not in DB schema provided
    var hireDate: Date? // Map from 'created_at'
    var location: String? // Not in DB schema provided
    var rating: Double? // Map from 'numeric'
    var earnings: Int? // Not in DB schema provided
    var totalTrips: Int? // Not in DB schema provided
    var totalDistance: Int? // Not in DB schema provided
    var contactNumber: String? // Map from 'phone'
    var licenseNumber: String? // Driver only, map from 'driver_license'
    var aadhaarNumber: String? // Driver only, map from 'aadhar_number'
}

struct Trip: Codable, Identifiable {
    let id: UUID?
    let consignmentId: UUID
    let driverId: UUID
    let vehicleId: UUID
    let pickupLocation: String
    let dropLocation: String
    let startTime: Date?
    let endTime: Date?
    let status: String
    let notes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id = "trip_id"
        case consignmentId = "consignment_id"
        case driverId = "driver_id"
        case vehicleId = "vehicle_id"
        case pickupLocation = "pickup_location"
        case dropLocation = "drop_location"
        case startTime = "start_time"
        case endTime = "end_time"
        case status
        case notes
        case createdAt = "created_at"
    }
}

