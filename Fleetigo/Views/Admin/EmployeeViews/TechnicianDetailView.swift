//
//  TechnicianDetailView.swift
//  Fleetigo
//
//  Created by Avinash on 27/04/25.
//


import SwiftUI

struct TechnicianDetailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showDocumentViewer = false
    
    let technician: Employee
    
    // Optional fallback values
    private let fallbackContactNumber = "Not provided"
    private let fallbackVehicleAssigned = "None"
    private let fallbackCertificationNumber = "Not provided"
    
    // Date formatter for hireDate
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) { // increase spacing between cards
                profileSection
                contactInfoSection
                employmentDetailsSection
                assignmentDetailsSection
                documentsSection
                activitySection
            }
            .padding(.horizontal)
            .padding(.top, 16)

        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showDocumentViewer) {
            DocumentViewerView(isPresented: $showDocumentViewer)
        }
        .navigationTitle("Technician Details")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                }
                .accessibilityLabel("Back to employee list")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var profileSection: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(Circle())
                .foregroundColor(.gray)
                .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(technician.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(technician.role)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor(for: technician.status))
                        .frame(width: 10, height: 10)
                    Text(technician.status)
                        .font(.caption)
                        .foregroundColor(statusColor(for: technician.status))
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 16)
        .padding(.horizontal)
        .background(Color(.systemGray6).opacity(0.5))
    }
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.headline)
                .foregroundColor(.primary)

            InfoCard(title: "Email", value: technician.email ?? "Not provided", icon: "envelope.fill")
            InfoCard(title: "Contact Number", value: technician.contactNumber ?? fallbackContactNumber, icon: "phone.fill")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    
    private var employmentDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Employment Details")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            InfoCard(
                title: "Hire Date",
                value: technician.hireDate.map { dateFormatter.string(from: $0) } ?? "Not provided",
                icon: "calendar"
            )
            InfoCard(title: "Experience", value: String(technician.experience ?? 0) ?? "Not provided" , icon: "briefcase.fill")
            InfoCard(title: "Specialty", value: technician.specialty ?? "Not provided", icon: "gearshape.fill")
        }
        .padding(.vertical, 12)
    }
    
    private var assignmentDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assignment Details")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            InfoCard(title: "Vehicle Assigned", value: fallbackVehicleAssigned, icon: "car.fill")
            InfoCard(title: "Consignment ID", value: technician.consignmentId ?? "Not provided", icon: "tag.fill")
        }
        .padding(.vertical, 12)
    }
    
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Documents")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Certification Number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(fallbackCertificationNumber)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button {
                    showDocumentViewer = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("View")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .accessibilityLabel("View technician document")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.vertical, 12)
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            ActivityCard(activity: "Completed equipment inspection", time: "Today, 10:30 AM")
            ActivityCard(activity: "Started maintenance task", time: "Today, 8:00 AM")
            ActivityCard(activity: "Reported tool issue", time: "Yesterday, 3:45 PM")
        }
        .padding(.vertical, 12)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Available":
            return .green
        case "On-Duty":
            return Color(red: 240/255, green: 184/255, blue: 0/255) // #F0B800
        case "Not Available":
            return .red
        default:
            return .gray
        }
    }
}

// Supporting Views

struct ActivityCard: View {
    let activity: String
    let time: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(activity)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "clock.fill")
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DocumentViewerView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Document Preview")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.gray)
                    .padding()
                
                Text("Technician document would appear here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Document")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                    .accessibilityLabel("Close document viewer")
                }
            }
        }
    }
}
