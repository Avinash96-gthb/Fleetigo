//
//  ExpenditureData.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//
import Foundation

/// Represents expenditure data by category with a value.
struct ExpenditureData: Identifiable {
    let id = UUID()
    let category: String
    var value: Double
}
