//
//  AnalyticsViewModel.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//


import Foundation
import SwiftUI
import Supabase



class AnalyticsViewModel: ObservableObject {
    /// Published property for revenue data, observable by SwiftUI views.
    @Published var revenueData: [RevenueData] = []
    
    /// Published property for expenditure data by category, observable by SwiftUI views.
    @Published var expenditureData: [ExpenditureData] = []
    
    /// Published property for expenditure data over time, observable by SwiftUI views.
    @Published var expenditureTimeData: [ExpenditureTimeData] = []
    
    /// Published property for fleet status, observable by SwiftUI views.
    @Published var fleetStatus: FleetStatus = FleetStatus(onDuty: 0, available: 0, servicing: 0)
    
    private let supabaseManager = SupabaseManager.shared // Assuming you have a singleton instance
    private var fetchedRevenueDates: Set<Date> = [] // Track fetched revenue dates to avoid duplicates
    private var fetchedExpenditureCategories: Set<String> = []  // Track fetched expenditure categories
    private var fetchedExpenditureTimeDates: Set<Date> = [] // Track fetched expenditure over time
    
    private var initialRevenueData: [RevenueData] = [] // Store initial static revenue data
    private var initialExpenditureData: [ExpenditureData] = []  // Store initial static expenditure data
    private var initialExpenditureTimeData: [ExpenditureTimeData] = [] // Store initial static expenditure time data
    
    /// Initializes the view model and fetches initial data.
    init() {
        let calendar = Calendar.current
        // Populate revenueData with mock data *once* in init
        initialRevenueData = [
            // January 2025
            RevenueData(date: calendar.date(from: DateComponents(year: 2025, month: 3, day: 6))!, value: 1900),
            // February 2025
            RevenueData(date: calendar.date(from: DateComponents(year: 2025, month: 4, day: 7))!, value: 1850),
            RevenueData(date: calendar.date(from: DateComponents(year: 2025, month: 5, day: 6))!, value: 1900)
            
        ]
        revenueData.append(contentsOf: initialRevenueData) // Add initial data
        
        // Add initial dates to fetchedRevenueDates to prevent duplicates
        initialRevenueData.forEach { data in
            fetchedRevenueDates.insert(data.date)
        }
        
        // Populate expenditureData with mock data
        initialExpenditureData = [
            ExpenditureData(category: "Salary", value: 50),
            ExpenditureData(category: "Repairs", value: 30),
            ExpenditureData(category: "Expense", value: 20)
        ]
        expenditureData.append(contentsOf: initialExpenditureData)
        initialExpenditureData.forEach { data in
            fetchedExpenditureCategories.insert(data.category)
        }
        
        // Populate expenditureTimeData
        initialExpenditureTimeData = [
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 1, day: 15))!, value: 700),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 2, day: 15))!, value: 620),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 3, day: 1))!, value: 500),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 3, day: 5))!, value: 600),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 3, day: 15))!, value: 550),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 3, day: 25))!, value: 700),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 4, day: 2))!, value: 650),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 4, day: 10))!, value: 800),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 4, day: 20))!, value: 600)
        ]
        expenditureTimeData.append(contentsOf: initialExpenditureTimeData)
        initialExpenditureTimeData.forEach { data in
            fetchedExpenditureTimeDates.insert(data.date)
        }
        
        
        fetchData() // Then fetch the rest
    }
    
    /// Fetches or generates data for the view model.
    func fetchData() {
        
        fetchFleetStatus() // Fetch dynamic fleet status
        fetchRevenueData() // Fetch revenue data from Supabase
        fetchExpenditureData()
        fetchExpenditureTimeData()
        
    }
    
    /// Fetches the fleet status from Supabase.
    func fetchFleetStatus() {
        Task {
            do {
                let vehicles = try await supabaseManager.fetchVehicles()
                let onDutyCount = vehicles.filter { $0.status == .onDuty }.count
                let availableCount = vehicles.filter { $0.status == .available }.count
                let garageCount = vehicles.filter { $0.status == .garage }.count
                
                DispatchQueue.main.async {
                    self.fleetStatus = FleetStatus(onDuty: onDutyCount, available: availableCount, servicing: garageCount)
                    print("Fleet Status updated: \(self.fleetStatus)")
                }
            } catch {
                print("Error fetching fleet status: \(error)")
                // Handle error appropriately, e.g., show an error message to the user
            }
        }
    }
    
    /// Fetches revenue data from Supabase and appends it to the existing data.
    func fetchRevenueData() {
        Task {
            do {
                let tripRevenues = try await supabaseManager.fetchTripRevenues() // Use the function from SupabaseManager
                
                print("successfully fetched trip revenue data \(tripRevenues)")
                
                // Convert TripRevenue to RevenueData and filter duplicates
                let newRevenueData = tripRevenues.compactMap { tripRevenue -> RevenueData? in
                    guard let createdAt = tripRevenue.createdAt,
                          let customerCharge = tripRevenue.customerCharge,
                          let fuelCost = tripRevenue.fuelCost,
                          let driverCost = tripRevenue.driverCost else {
                        return nil // Skip if crucial data is missing
                    }
                    
                    let revenue = customerCharge - fuelCost - driverCost
                    
                    // Only include if this date hasn't been fetched before
                    if !fetchedRevenueDates.contains(createdAt) {
                        return RevenueData(date: createdAt, value: revenue)
                    } else {
                        return nil // Skip duplicate
                    }
                }
                
                // Update on the main thread
                DispatchQueue.main.async {
                    // Append the new data
                    self.revenueData.append(contentsOf: newRevenueData)
                    
                    // Update the set of fetched dates
                    newRevenueData.forEach { data in
                        self.fetchedRevenueDates.insert(data.date)
                    }
                    
                    print("Revenue Data updated. Total count: \(self.revenueData.count)")
                    print("Revenue data is now \(self.revenueData)")
                }
            } catch {
                print("Error fetching revenue data: \(error)")
                // Handle the error, e.g., show an alert to the user
            }
        }
    }
    
    func fetchExpenditureData() {
        Task {
            do {
                let tripRevenues = try await supabaseManager.fetchTripRevenues()
                
                // Create dictionaries to accumulate values for each category
                var salaryTotal = 0.0
                var expenseTotal = 0.0
                
                // Iterate through trip revenues and accumulate costs
                tripRevenues.forEach { tripRevenue in
                    if let driverCost = tripRevenue.driverCost {
                        salaryTotal += driverCost
                    }
                    if let fuelCost = tripRevenue.fuelCost {
                        expenseTotal += fuelCost
                    }
                }
                
                //check if the categories already exists before adding new values
                if let salaryIndex = expenditureData.firstIndex(where: { $0.category == "Salary" }) {
                    expenditureData[salaryIndex].value += salaryTotal
                } else
                {

                    
                    
                    DispatchQueue.main.async {
                        self.expenditureData.append(ExpenditureData(category: "Salary", value: salaryTotal))
                        self.fetchedExpenditureCategories.insert("Salary")
                    }
                }
                
                if let expenseIndex = expenditureData.firstIndex(where: { $0.category == "Expense" }) {
                    expenditureData[expenseIndex].value += expenseTotal
                } else {
                    expenditureData.append(ExpenditureData(category: "Expense", value: expenseTotal))
                    fetchedExpenditureCategories.insert("Expense")
                }
                
                // Ensure "Repairs" is always present, but its value remains 0
                if !fetchedExpenditureCategories.contains("Repairs") {
                    expenditureData.append(ExpenditureData(category: "Repairs", value: 0))
                    fetchedExpenditureCategories.insert("Repairs")
                }
                
                
                DispatchQueue.main.async {
                    
                    print("Expenditure data updated, total count: \(self.expenditureData.count)")
                    print("Expenditure data is now \(self.expenditureData)")
                }
                
            } catch {
                print("Error fetching expenses: \(error)")
            }
        }
    }
    
    func fetchExpenditureTimeData() {
        Task {
            do{
                let tripRevenues = try await supabaseManager.fetchTripRevenues()
                
                let newExpenditureTimeData = tripRevenues.compactMap{ tripRevenue -> ExpenditureTimeData? in
                    guard let createdAt = tripRevenue.createdAt,
                          let fuelCost = tripRevenue.fuelCost,
                          let driverCost = tripRevenue.driverCost else {
                        return nil
                    }
                    
                    // For time-based, we'll use a combined value (you might adjust as needed)
                    let combinedCost = fuelCost + driverCost
                    
                    if !fetchedExpenditureTimeDates.contains(createdAt){
                        return ExpenditureTimeData(date: createdAt, value: combinedCost)
                    } else {
                        return nil
                    }
                }
                
                DispatchQueue.main.async {
                    self.expenditureTimeData.append(contentsOf: newExpenditureTimeData)
                    
                    newExpenditureTimeData.forEach{ data in
                        self.fetchedExpenditureTimeDates.insert(data.date)
                    }
                    print("Expenditure time data updated, total count: \(self.expenditureTimeData.count)")
                    print("Expenditure time data is now \(self.expenditureTimeData)")
                }
                
            } catch {
                print("Error fetching expenses for time: \(error)")
            }
        }
    }
    
    
    /// Populates expenditureData with mock category-based data.
    func fetchExpenditureDataByCategory() {
        let calendar = Calendar.current
        
        // Populate expenditureData with mock data
        initialExpenditureData = [
            ExpenditureData(category: "Salary", value: 50),
            ExpenditureData(category: "Repairs", value: 30),
            ExpenditureData(category: "Expense", value: 20)
        ]
        expenditureData.append(contentsOf: initialExpenditureData)
        initialExpenditureData.forEach { data in
            fetchedExpenditureCategories.insert(data.category)
        }
        
    }
    
    /// Populates expenditureTimeData with mock time-based data.
    func fetchExpenditureDataOverTime() {
        let calendar = Calendar.current
        
        // Populate expenditureTimeData
        initialExpenditureTimeData = [
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 1, day: 15))!, value: 700),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 2, day: 15))!, value: 620),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 3, day: 1))!, value: 500),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 3, day: 5))!, value: 600),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 3, day: 15))!, value: 550),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 3, day: 25))!, value: 700),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 4, day: 2))!, value: 650),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 4, day: 10))!, value: 800),
            ExpenditureTimeData(date: calendar.date(from: DateComponents(year: 2023, month: 4, day: 20))!, value: 600)
        ]
        expenditureTimeData.append(contentsOf: initialExpenditureTimeData)
        initialExpenditureTimeData.forEach { data in
            fetchedExpenditureTimeDates.insert(data.date)
        }
        
    }
    
    
}

