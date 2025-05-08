//
//  ConsignmentDetailView.swift
//  FleetigoConsignment
//
//  Created by user@22 on 29/04/25.
//


import SwiftUI

struct ConsignmentDetailView: View {
    let consignment: Consignment
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                generalInformationSection
                routeMapSection
                dateInformationSection
                contactInformationSection
                instructionsSection
            }
            .padding()
        }
        .navigationTitle("Consignment Details")
    }
    
    private var generalInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General Information")
                .font(.headline)
            
            DetailRow(label: "Consignment ID", value: consignment.id)
            DetailRow(label: "Type", value: consignment.type.rawValue.capitalized)
            DetailRow(label: "Weight", value: consignment.weight.isEmpty ? "N/A" : "\(consignment.weight) kg")
            DetailRow(label: "Dimensions", value: consignment.dimensions.isEmpty ? "N/A" : consignment.dimensions)
            DetailRow(label: "Description", value: consignment.description.isEmpty ? "N/A" : consignment.description)
        }
    }
    
    private var routeMapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route")
                .font(.headline)
            
            RouteMapView(
                pickupAddress: .constant(consignment.pickup_location),
                dropAddress: .constant(consignment.drop_location)
            )
            .frame(height: 300)
            .cornerRadius(12)
        }
    }
    
    private var dateInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timing")
                .font(.headline)
            
            DetailRow(label: "Pickup Date", value: consignment.pickup_date.formatted(date: .long, time: .omitted))
            DetailRow(label: "Delivery Date", value: consignment.delivery_date.formatted(date: .long, time: .omitted))
        }
    }
    
    private var contactInformationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contacts")
                .font(.headline)
            
            DetailRow(label: "Sender Phone", value: consignment.sender_phone)
            DetailRow(label: "Recipient Name", value: consignment.recipient_name)
            DetailRow(label: "Recipient Phone", value: consignment.recipient_phone)
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Special Instructions")
                .font(.headline)
            
            Text(consignment.instructions ?? "No special instructions given")
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}
