//
//  RevenueData.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//

import Foundation


struct RevenueData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
