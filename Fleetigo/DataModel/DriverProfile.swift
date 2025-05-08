//
//  DriverProfile.swift
//  Fleetigo
//
//  Created by Avinash on 05/05/25.
//
import Foundation

struct DriverProfile: Identifiable, Codable {
    let id: UUID
    let email: String
    let name: String?
    let aadhar_number: String?
    let driver_license: String?
    let phone: String?
    let experience: Int?
    let rating: Double?
    let created_at: Date?
    let factor_id: UUID?
    let is_2fa_enabled: Bool
}
