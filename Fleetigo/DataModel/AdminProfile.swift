//
//  AdminProfile.swift
//  Fleetigo
//
//  Created by Avinash on 05/05/25.
//
import Foundation

struct AdminProfile: Identifiable, Codable {
    let id: UUID
    let email: String
    let full_name: String?
    let phone: String?
    let gender: String?
    let created_at: Date?
    let factor_id: UUID?
    let is_2fa_enabled: Bool
    let date_of_birth: Date?
}



