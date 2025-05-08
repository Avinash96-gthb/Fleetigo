//
//  IssueReportDetailView.swift
//  Fleetigo
//
//  Created by Avinash on 08/05/25.
//


struct IssueReportDetailView: View {
    let report: IssueReport
    @StateObject private var issueManager = IssueManager.shared
    @State private var imageURLs: [URL] = []
    @State private var isLoadingImages = true
    @State private var imageFetchError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) { // Increased spacing between sections
                
                // Section 1: Overview
                DetailSection(title: "Overview") {
                    DetailRow2(label: "Status", value: report.status.capitalized, valueColor: statusColor(report.status))
                    DetailRow2(label: "Priority", value: report.priority.capitalized, valueColor: priorityColor(report.priority))
                    DetailRow2(label: "Category", value: report.category)
                    DetailRow2(label: "Type", value: report.type)
                    DetailRow2(label: "Reported", value: report.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "N/A")
                }

                // Section 2: Identifiers
                DetailSection(title: "Identifiers") {
                    DetailRow(label: "Report ID", value: report.id.uuidString.prefix(8).uppercased())
                    if let id = report.consignmentId { DetailRow(label: "Consignment ID", value: id.uuidString.prefix(8).uppercased()) }
                    if let id = report.vehicleId { DetailRow(label: "Vehicle ID", value: id.uuidString.prefix(8).uppercased()) }
                    if let id = report.driverId { DetailRow(label: "Driver ID", value: id.uuidString.prefix(8).uppercased()) }
                    if let id = report.adminId { DetailRow(label: "Admin ID", value: id.uuidString.prefix(8).uppercased()) }
                }
                
                // Section 3: Description
                DetailSection(title: "Description") {
                    Text(report.description.isEmpty ? "No description provided." : report.description)
                        .font(.body)
                        .foregroundColor(report.description.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading) // Ensure it takes full width
                        .padding(.top, 5) // Add a little space below the section title
                }
                
                // Section 4: Photos
                DetailSection(title: "Photos") {
                    imageSection()
                }
                
                Spacer() // Pushes content up if it's short
            }
            .padding() // Overall padding for the ScrollView content
        }
        .navigationTitle("Report #\(report.id.uuidString.prefix(8).uppercased())")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea()) // Background for the whole detail view
        .onAppear(perform: fetchImages)
    }

    // Helper to get color based on status
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "pending": return .orange
        case "in progress": return .blue
        case "resolved": return .green
        case "rejected": return .red
        default: return .gray
        }
    }

    // Helper to get color based on priority
    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }

    @ViewBuilder
    private func imageSection() -> some View {
        if isLoadingImages {
            HStack { // Center the loader
                Spacer()
                ProgressView("Loading images...")
                Spacer()
            }
            .padding(.vertical)
        } else if let error = imageFetchError {
            Text("Error loading images: \(error)")
                .foregroundColor(.red)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical)
        } else if imageURLs.isEmpty {
            Text("No photos uploaded for this report.")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) { // Spacing between images
                    ForEach(imageURLs, id: \.self) { url in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack { // Individual loading indicator
                                    Color(.systemGray5) // Placeholder background
                                    ProgressView()
                                }
                                .frame(width: 120, height: 120)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                                
                            case .success(let image):
                                image.resizable()
                                     .aspectRatio(contentMode: .fill)
                                     .frame(width: 120, height: 120)
                                     .clipped()
                                     .cornerRadius(8)
                                     .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                                     // .shadow(radius: 3) // Optional subtle shadow

                            case .failure:
                                ZStack {
                                    Color(.systemGray5)
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 120, height: 120)
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.5)))
                                
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .padding(.vertical, 5) // Padding for the horizontal scroll view
            }
        }
    }
    
    private func fetchImages() {
        // Keep isLoadingImages true until data is fetched or error
        isLoadingImages = true // Ensure it's set at the start
        imageFetchError = nil
        Task {
            do {
                let urls = try await issueManager.fetchImageURLsForReport(issueReportId: report.id)
                // Using @MainActor for UI updates or ensure this Task is on main actor
                await MainActor.run {
                    self.imageURLs = urls
                    self.isLoadingImages = false
                }
            } catch {
                await MainActor.run {
                    self.imageFetchError = error.localizedDescription
                    self.isLoadingImages = false
                    print("Error fetching images for report \(report.id): \(error)")
                }
            }
        }
    }
}

// MARK: - Reusable Detail Section View
struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(.primary)
            // Divider().padding(.bottom, 4) // Optional divider under title
            
            content
                .padding(.leading, 5) // Indent content slightly under title
        }
        .padding() // Padding around the section content
        .background(Color(UIColor.secondarySystemGroupedBackground)) // Card background
        .cornerRadius(12)
        // .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2) // Subtle shadow
    }
}

// MARK: - Reusable Detail Row View
struct DetailRow2: View {
    let label: String
    let value: String
    var valueColor: Color = .primary // Default color

    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
                .frame(minWidth: 110, alignment: .leading) // Align labels
            Text(value)
                .font(.subheadline)
                .foregroundColor(valueColor)
                .frame(maxWidth: .infinity, alignment: .leading) // Allow value to wrap
        }
        .padding(.vertical, 2) // Small vertical padding for each row
    }
}
