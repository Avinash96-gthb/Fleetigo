//
//  MaintenanceTask.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//

import Foundation


struct MaintenanceTask: Identifiable {
    let id = UUID()
    let cid: String
    let issueDescription: String
    let priorityLevel: String
    let repairType: String
    let location: String
    let vehicleData: String
    let reportedBy: String
    let phoneNumber: String
    let images: [String]
    var status: MaintenanceStatus
}
