//
//  Document1Type.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//

import Foundation


enum Document1Type: String, CaseIterable {
    case profilePicture = "Profile Picture"
    case aadhaarCard = "Aadhaar Card"
    case drivingLicense = "Driving License"
    case fitnessCertificate = "Fitness Certificate"
    
    var iconName: String {
        switch self {
        case .profilePicture: return "person.fill"
        case .aadhaarCard: return "person.text.rectangle.fill"
        case .drivingLicense: return "figure.seated.seatbelt"
        case .fitnessCertificate: return "cross.case.fill"
        }
    }
    
    var subtitle: String {
        switch self {
        case .profilePicture: return "Upload A Profile Photo Of Yourself"
        case .aadhaarCard: return "Upload A PDF Of Both Sides Of Your Card"
        case .drivingLicense: return "Upload A PDF Of Both Sides Of Your License"
        case .fitnessCertificate: return "Upload PDF Of Your Medical Certificate"
        }
    }
}
