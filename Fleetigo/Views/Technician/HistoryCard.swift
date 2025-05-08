// MaintenanceHistoryCard.swift
import SwiftUI

struct MaintenanceHistoryCard: View {
    let issueReport: IssueReport

    @State private var driverName: String?
    

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                priorityIcon(for: issueReport.priority) // Uses the corrected function
                Text("ID: \(issueReport.id.uuidString.prefix(8))")
                    .font(.headline)
                Spacer()
                if let createdAt = issueReport.createdAt {
                    Text(createdAt.formatted(date: .numeric, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }

            Text(issueReport.description)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(Color(UIColor.label))

            HStack {
                detailChip(label: "Category", value: issueReport.category)
                detailChip(label: "Type", value: issueReport.type)
                Spacer()
            }
            
            if let name = driverName {
                Text("Reported by: \(name)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(issueReport.status.capitalized)
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.green) // Resolved is green
                .clipShape(Capsule())
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .onAppear {
            Task {
                // If MaintenanceStore is properly injected via @EnvironmentObject, use that.
                // For now, this creates a new instance which is not ideal for shared state/caching.
                // This would be better if getDriverName was, for example, a static method on
                // a helper class or if the name was already part of a richer IssueReportViewModel.
                self.driverName = await MaintenanceStore().getDriverName(driverId: issueReport.driverId)
            }
        }
    }

    // CORRECTED FUNCTION: Return type is now `some View`
    @ViewBuilder // Good practice for functions returning `some View` with conditions
    private func priorityIcon(for priority: String) -> some View {
        switch priority.lowercased() {
        case "high":
            Image(systemName: "flame.fill").foregroundColor(.red)
        case "medium":
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
        case "low":
            Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
        default:
            Image(systemName: "info.circle.fill").foregroundColor(.gray)
        }
    }
    
    private func detailChip(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):")
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.caption2.weight(.medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(4)
        }
    }
}
