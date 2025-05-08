//
//  IssueReportCardView.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//
import SwiftUI

struct IssueReportCardView: View { // Renamed to avoid conflict if IssueReportCard is a model
    @State var report: IssueReport // Use @State if report might be modified by actions within this card, otherwise let/var
    var filter: GarageTab.TabFilter
    var onUpdateStatus: (UUID, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack {
                    priorityIcon(for: report.priority)
                        .font(.title3)
                        .padding(.top, 4)
                    Spacer()
                }
                .padding(.trailing, 8)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 0) {
                        Text("ID: ").font(.body)
                        Text(report.id.uuidString.prefix(8)).font(.body.bold())
                    }
                    detailText("Priority:", report.priority)
                    detailText("Type:", report.type)
                    detailText("Category:", report.category)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    NavigationLink(destination: IssueReportDetailView(report: report)) {
                        Text("Details >").font(.subheadline).foregroundColor(.blue)
                    }
                    
                    statusAndActionsView()
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground)) // Adapts to light/dark mode
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 0)
        .animation(.easeInOut, value: report.status) // Animate changes to status
    }
    
    @ViewBuilder
    private func priorityIcon(for priority: String) -> some View {
        switch priority.lowercased() {
        case "high": Image(systemName: "chevron.up.2").foregroundColor(.red)
        case "medium": Image(systemName: "equal").foregroundColor(.orange)
        case "low": Image(systemName: "chevron.down.2").foregroundColor(.green)
        default: Image(systemName: "exclamationmark.circle").foregroundColor(.gray)
        }
    }

    private func detailText(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Text(value).font(.system(size: 12, weight: .regular)).foregroundColor(Color(hex: "#767676"))
        }
    }

    @ViewBuilder
    private func statusAndActionsView() -> some View {
        let currentStatus = report.status.lowercased()
        
        if filter == .approved {
            if currentStatus == "in progress" {
                statusPill(text: "IN PROGRESS", colorHex: "#FFC500")
                Button(action: { onUpdateStatus(report.id, "Resolved") }) {
                    Text("Mark Resolved").font(.caption).padding(4)
                        .background(Color.green.opacity(0.2)).cornerRadius(4)
                }
            } else if currentStatus == "resolved" {
                statusPill(text: "RESOLVED", colorHex: "#34C759")
            }
        } else if filter == .rejected && currentStatus == "rejected" {
            statusPill(text: "REJECTED", colorHex: "#FF3B30")
            Button(action: { onUpdateStatus(report.id, "Pending") }) { // Action to re-open
                statusPill(text: "RE-OPEN", colorHex: "#007AFF", style: .outlined)
            }
        } else if filter == .complaints && currentStatus == "pending" {
            HStack(spacing: 8) {
                actionButton(systemName: "xmark.circle.fill", color: Color(hex: "#FF6767")) {
                    onUpdateStatus(report.id, "Rejected")
                }
                actionButton(systemName: "checkmark.circle.fill", color: Color(hex: "#89D06C")) {
                    onUpdateStatus(report.id, "In Progress")
                }
            }
            .padding(.top, 10) // Adjust as needed
        } else {
            // Fallback for any other status or combination
             statusPill(text: report.status.uppercased(), colorHex: "#8E8E93") // Neutral color
        }
    }

    private func actionButton(systemName: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName).resizable().frame(width: 24, height: 24).foregroundColor(color)
        }
    }
    
    enum PillStyle { case filled, outlined }
    private func statusPill(text: String, colorHex: String, style: PillStyle = .filled) -> some View {
        let pillColor = Color(hex: colorHex)
        return Text(text)
            .font(.system(size: 10, weight: .bold)) // Smaller font for pills
            .foregroundColor(style == .filled ? .white : pillColor)
            .textCase(.uppercase)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(
                Group {
                    if style == .filled {
                        RoundedRectangle(cornerRadius: 12).fill(pillColor)
                    } else {
                        RoundedRectangle(cornerRadius: 12).stroke(pillColor)
                    }
                }
            )
    }
}
