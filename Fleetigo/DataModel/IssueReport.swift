// matching.swift (or IssueReport.swift)
import Foundation

struct IssueReport: Identifiable, Codable, Equatable { // Added Equatable for easier updates in @Published arrays
    let id: UUID
    var createdAt: Date? // Make it var if it can be updated, though usually not for creation timestamp
    let consignmentId: UUID?
    let vehicleId: UUID?
    let driverId: UUID? // This was UUID in submitIssueReport params, but UUID? in struct. Struct is likely DB accurate.
    let description: String
    let priority: String
    let category: String
    let type: String
    var status: String // Make it var to allow local updates after status change
    let adminId: UUID?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case consignmentId = "consignment_id"
        case vehicleId = "vehicle_id"
        case driverId = "driver_id"
        case description
        case priority
        case category
        case type
        case status
        case adminId = "admin_id"
    }

    init(id: UUID = UUID(), createdAt: Date? = nil, consignmentId: UUID?, vehicleId: UUID?, driverId: UUID?, description: String, priority: String, category: String, type: String, status: String = "Pending", adminId: UUID? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.consignmentId = consignmentId
        self.vehicleId = vehicleId
        self.driverId = driverId
        self.description = description
        self.priority = priority
        self.category = category
        self.type = type
        self.status = status
        self.adminId = adminId
    }
}
