//
//  VehicleType.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//
import Foundation

enum VehicleType: String, CaseIterable, Identifiable, Codable {

    case hcv = "HCV"

    case mcv = "MCV"

    case lcv = "LCV"
    var id: String { self.rawValue }
}
