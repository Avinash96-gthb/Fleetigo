// MaintenanceTaskCard.swift
import SwiftUI

struct MaintenanceTaskCard: View {
    @State var issueReport: IssueReport
    @EnvironmentObject var store: MaintenanceStore
    
    @State private var driverName: String?
    @State private var adminName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                priorityIcon(for: issueReport.priority) // This will now correctly use the `some View`
                Text("ID: \(issueReport.id.uuidString.prefix(8))")
                    .font(.headline)
                Spacer()
                Text(issueReport.status.capitalized)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(issueReport.status).opacity(0.2))
                    .foregroundColor(statusColor(issueReport.status))
                    .cornerRadius(6)
            }

            Group {
                detailRow(label: "Description", value: issueReport.description)
                detailRow(label: "Category", value: issueReport.category)
                detailRow(label: "Type", value: issueReport.type)
                if let name = driverName {
                    detailRow(label: "Reported by (Driver)", value: name)
                }
                if let createdAt = issueReport.createdAt {
                    detailRow(label: "Reported On", value: createdAt.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            actionButtons
                .padding(.top, 8)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .onAppear {
            Task {
                self.driverName = await store.getDriverName(driverId: issueReport.driverId)
                // self.adminName = await store.getAdminName(adminId: issueReport.adminId)
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        let status = issueReport.status.lowercased()
        if status == "pending" {
            Button {
                Task { await store.acceptTask(issueReport) }
            } label: {
                Text("Accept Task")
                    .modifier(MaintenanceButtonStyler(backgroundColor: .orange))
            }
        } else if status == "in progress" {
            Button {
                Task { await store.markTaskAsDone(issueReport) }
            } label: {
                Text("Mark as Done")
                    .modifier(MaintenanceButtonStyler(backgroundColor: .green))
            }
        } else {
            Text("Status: \(issueReport.status.capitalized)")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
    
    // CORRECTED FUNCTION: Return type is now `some View`
    @ViewBuilder // Good practice for functions returning `some View` with conditions
    private func priorityIcon(for priority: String) -> some View {
        switch priority.lowercased() {
        case "high":
            Image(systemName: "chevron.up.2").foregroundColor(.red)
        case "medium":
            Image(systemName: "equal").foregroundColor(.orange)
        case "low":
            Image(systemName: "chevron.down.2").foregroundColor(.green)
        default:
            Image(systemName: "minus").foregroundColor(.gray)
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "pending": return .orange
        case "in progress": return .blue
        case "resolved": return .green
        case "rejected": return .red
        default: return .gray
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .fontWeight(.medium)
                .frame(width: 100, alignment: .leading) // Increased width for "Reported by (Driver)"
            Text(value)
                .lineLimit(3) // Allow a bit more space for longer names/descriptions
            Spacer()
        }
    }
}

// Reusable Button Styler (remains the same)
struct MaintenanceButtonStyler: ViewModifier {
    let backgroundColor: Color
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .cornerRadius(8)
    }
}
