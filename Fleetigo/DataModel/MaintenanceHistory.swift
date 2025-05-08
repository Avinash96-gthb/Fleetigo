//
//  MaintenanceHistory.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//
import Foundation

struct MaintenanceHistory: Identifiable {
    let id = UUID()
    let cid: String
    let title: String
    let priorityLevel: String
    let repairType: String
    let status: MaintenanceStatus
}
