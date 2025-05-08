import SwiftUI
import PhotosUI

struct ReportIssueView: View {
    @EnvironmentObject var tripManager: TripManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var issueManager = IssueManager.shared // Use the shared instance

    let uncheckedItems: [String]
    let consignmentId: UUID?
    let vehichleId: UUID?
    let driverId: UUID? // Make this non-optional

    @State private var selectedItem: String = ""
    @State private var descriptionText: String = ""
    @State private var priorityLevel: String = ""
    @State private var repairCategory: String = ""
    @State private var repairType: String = ""
    @State private var selectedPhotos: [UIImage] = []
    @State private var photosPickerItems: [PhotosPickerItem] = []
    // @State private var showSuccessAlert: Bool = false  // Moved to IssueManager
    // @State private var isSubmitting: Bool = false  // Moved to IssueManager
    // @State private var submissionError: String? // Moved to IssueManager

    let priorityOptions = ["Low", "Medium", "High"]
    let repairCategories = ["Mechanical", "Electrical", "Body"]
    let repairTypes = ["General", "Urgent", "Scheduled"]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#B5FFDF"), location: 0.0),
                        .init(color: Color.white, location: 0.20)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        TextField("", text: $selectedItem, prompt: Text("Consignment ID")
                            .foregroundColor(Color(hex: "#757575"))
                            .font(.body)
                        )
                        .padding()
                        .background(Color(hex: "#F5F5F5"))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .disabled(true) // Disable editing since it's autofilled
                        .foregroundColor(.black)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: Binding(
                                get: { descriptionText },
                                set: { newValue in
                                    if newValue.count <= 500 {
                                        descriptionText = newValue
                                    } else {
                                        descriptionText = String(newValue.prefix(500))
                                    }
                                }
                            ))
                            .frame(height: 120)
                            .padding(4)
                            .background(Color(hex: "#F5F5F5"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .scrollContentBackground(.hidden)
                            .focusable()
                            .onTapGesture {
                                UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
                            }

                            if descriptionText.isEmpty {
                                Text("Description")
                                    .foregroundColor(Color(hex: "#757575"))
                                    .font(.body)
                                    .padding(.top, 12)
                                    .padding(.leading, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                        .padding(.horizontal)

                        Text("\(descriptionText.count)/500")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 28)

                        ZStack(alignment: .leading) {
                            Menu {
                                ForEach(priorityOptions, id: \.self) { option in
                                    Button(option) {
                                        priorityLevel = option
                                    }
                                }
                            } label: {
                                HStack {
                                    if priorityLevel.isEmpty {
                                        Text("Priority Level")
                                            .foregroundColor(Color(hex: "#757575"))
                                            .font(.body)
                                    } else {
                                        Text(priorityLevel)
                                            .foregroundColor(.black)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(hex: "#F5F5F5"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)

                        ZStack(alignment: .leading) {
                            Menu {
                                ForEach(repairCategories, id: \.self) { option in
                                    Button(option) {
                                        repairCategory = option
                                    }
                                }
                            } label: {
                                HStack {
                                    if repairCategory.isEmpty {
                                        Text("Repair Category")
                                            .foregroundColor(Color(hex: "#757575"))
                                            .font(.body)
                                    } else {
                                        Text(repairCategory)
                                            .foregroundColor(.black)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(hex: "#F5F5F5"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)

                        ZStack(alignment: .leading) {
                            Menu {
                                ForEach(repairTypes, id: \.self) { option in
                                    Button(option) {
                                        repairType = option
                                    }
                                }
                            } label: {
                                HStack {
                                    if repairType.isEmpty {
                                        Text("Repair Type")
                                            .foregroundColor(Color(hex: "#757575"))
                                            .font(.body)
                                    } else {
                                        Text(repairType)
                                            .foregroundColor(.black)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(hex: "#F5F5F5"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)

                        VStack {
                            Text("Upload Photos")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding(.top, 16)
                                .padding(.bottom, 16)
                                .padding(.leading, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 8) {
                                ForEach(0..<3, id: \.self) { index in
                                    if index < selectedPhotos.count {
                                        Image(uiImage: selectedPhotos[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .cornerRadius(8)
                                            .clipped()
                                    } else {
                                        ZStack {
                                            Rectangle()
                                                .fill(Color(hex: "#F5F5F5"))
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(8)
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                            PhotosPicker(
                                selection: $photosPickerItems,
                                maxSelectionCount: 3,
                                matching: .images
                            ) {
                                Image(systemName: "plus.circle")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(Color(hex: "#25A36B"))
                            }
                            .onChange(of: photosPickerItems) { newItems in
                                Task {
                                    selectedPhotos = []
                                    for item in newItems {
                                        if let data = try? await item.loadTransferable(type: Data.self),
                                           let image = UIImage(data: data) {
                                            selectedPhotos.append(image)
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)

                        Button(action: {
                            // Call IssueManager.shared.submitIssueReport here
                            guard let driverId = driverId else {
                                issueManager.submissionError = "Driver ID is required." // Set error in IssueManager
                                return
                            }
                            issueManager.submitIssueReport(
                                consignmentId: consignmentId,
                                vehicleId: vehichleId,
                                driverId: driverId,
                                description: descriptionText,
                                priority: priorityLevel,
                                category: repairCategory,
                                type: repairType,
                                images: selectedPhotos
                            ) { result in
                                switch result {
                                case .success:
                                    // Handle success, e.g., show an alert and dismiss
                                    // self.showSuccessAlert = true //  Moved to IssueManager
                                    DispatchQueue.main.async {
                                         issueManager.showSuccessAlert = true
                                    }

                                case .failure(let error):
                                    // Handle the error, e.g., show an error message
                                    print("Error submitting report: \(error)")
                                    DispatchQueue.main.async {
                                        issueManager.submissionError = error.localizedDescription
                                    }
                                }
                            }
                        }) {
                            Text("Submit")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(hex: "#25A36B"))
                                .cornerRadius(12)
                        }
                        .disabled(selectedItem.isEmpty || descriptionText.isEmpty || issueManager.isSubmitting) // Disable during submission
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                        if let error = issueManager.submissionError {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .padding()
                        }
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Raise a Complaint")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let id = consignmentId {
                    selectedItem = id.uuidString.uppercased()
                } else {
                    selectedItem = "Consignment ID not available"
                }
            }
            .alert("Success", isPresented: $issueManager.showSuccessAlert) { // Use state from IssueManager
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your report has been successfully submitted.")
            }
        }
    }
}
