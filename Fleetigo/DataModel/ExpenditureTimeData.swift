//
//  ExpenditureTimeData.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//
import Foundation

struct ExpenditureTimeData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
