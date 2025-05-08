//
//  Vehicle.swift
//  Fleetigo
//
//  Created by Avinash on 28/04/25.
//

import Foundation

struct Vehicle: Codable, Identifiable, Hashable  {
    var id: UUID?
    var licensePlateNo: String
    var type: String
    var model: String
    var fastagNo: String
    var imageURL: String?
    var rcCertificateURL: String?
    var pollutionCertificateURL: String?
    var permitURL: String?
    var createdAt: String
    var status: VehicleStatus

    // Properties for storing the downloaded files
    var imageData: Data?
    var rcCertificateData: Data?
    var pollutionCertificateData: Data?
    var permitData: Data?

    enum CodingKeys: String, CodingKey {
        case id
        case licensePlateNo = "license_plate_no"
        case type
        case model
        case fastagNo = "fastag_no"
        case imageURL = "image_url"
        case rcCertificateURL = "rc_certificate_url"
        case pollutionCertificateURL = "pollution_certificate_url"
        case permitURL = "permit_url"
        case createdAt = "created_at"
        case status
    }

    enum VehicleStatus: String, Codable {
        case available, onDuty = "on_duty", garage
    }
    
    func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func ==(lhs: Vehicle, rhs: Vehicle) -> Bool {
            return lhs.id == rhs.id
        }
}

