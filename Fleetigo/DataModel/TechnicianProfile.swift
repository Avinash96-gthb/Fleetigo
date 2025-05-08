//
//  TechnicianProfile.swift
//  Fleetigo
//
//  Created by Avinash on 05/05/25.
//
import Foundation

struct TechnicianProfile: Identifiable, Codable {
    let id: UUID
    let email: String
    let name: String?
    let experience: Int?
    let specialty: String?
    let rating: Double?
    let created_at: Date?
    let factor_id: UUID?
    let is_2fa_enabled: Bool
    let phone: String?
}
