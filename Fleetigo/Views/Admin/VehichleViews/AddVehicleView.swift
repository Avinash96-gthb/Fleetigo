import SwiftUI
import UIKit // Import UIKit for UIImage

struct AddVehicleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var number = "" // This state variable doesn't seem to be used based on the Vehicle struct
    @State private var type: VehicleType = .lcv
    @State private var model = ""
    @State private var licensePlate = ""
    @State private var fastagNo = ""
    @State private var image: UIImage? = nil
    @State private var isImagePickerPresented = false
    @State private var pollutionCertificate: URL? = nil
    @State private var rc: URL? = nil
    @State private var permit: URL? = nil
    @State private var isDocumentPickerPresented = false
    @State private var selectedDocumentType: String? = nil
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLicensePlateValidFormat = true

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Vehicle Information")) {
                    Picker("Type", selection: $type) {
                        ForEach(VehicleType.allCases) { vehicleType in
                            Text(vehicleType.rawValue).tag(vehicleType)
                        }
                    }
                    .padding(.bottom)

                    TextField("Model", text: $model)
                        .autocorrectionDisabled()
                        .textCase(.none)
                        .padding(.bottom)

                    VStack(alignment: .leading) {
                        TextField("License Plate", text: $licensePlate)
                            .autocorrectionDisabled()
                            .textCase(.uppercase)
                            .onChange(of: licensePlate) { _, newValue in
                                licensePlate = formatLicensePlate(newValue)
                                isLicensePlateValidFormat = isValidIndianLicensePlate(newValue)
                            }

                        if !isLicensePlateValidFormat {
                            Text("Invalid Indian License Plate Format")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding(.bottom)

                    TextField("Fastag No. (optional)", text: $fastagNo)
                        .keyboardType(.numberPad)
                        .autocorrectionDisabled()
                        .textCase(.none)
                        .padding(.bottom)

                    Button("Add Vehicle Image from Gallery") {
                        isImagePickerPresented = true
                    }
                    if let uiImage = image {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                    }
                }

                Section(header: Text("Documents")) {
                    documentSelectionRow(label: "Pollution Certificate", url: $pollutionCertificate, documentType: "pollutionCertificate")
                    documentSelectionRow(label: "RC", url: $rc, documentType: "rc")
                    documentSelectionRow(label: "Permit", url: $permit, documentType: "permit")
                }
            }
            .navigationTitle("Add Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await handleSave() }
                    }
                    .disabled(!isFormValid())
                }
            }
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(image: $image)
            }
            .sheet(isPresented: $isDocumentPickerPresented) {
                if selectedDocumentType == "pollutionCertificate" {
                    DocumentPicker(url: $pollutionCertificate)
                } else if selectedDocumentType == "rc" {
                    DocumentPicker(url: $rc)
                } else if selectedDocumentType == "permit" {
                    DocumentPicker(url: $permit)
                }
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Helper Views

    private func documentSelectionRow(label: String, url: Binding<URL?>, documentType: String) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label)
                Spacer()
                Button("Select file") {
                    selectedDocumentType = documentType
                    isDocumentPickerPresented = true
                }
            }
            if let fileURL = url.wrappedValue {
                Text(fileURL.lastPathComponent).foregroundColor(.gray)
            }
        }
        .padding(.bottom)
    }

    // MARK: - Validation

    private func isFormValid() -> Bool {
        isLicensePlateValidFormat && isModelValid(model)
    }

    private func isValidIndianLicensePlate(_ plate: String) -> Bool {
        // Regular Indian license plate format (e.g., KA01AB1234)
        let normalPattern = "^[A-Z]{2}[0-9]{1,2}[A-Z]{1,3}[0-9]{4}$"
        // Bharat Series license plate format (e.g., XX-YY-23-0000000-AA)
        let bharatPattern = "^[A-Z]{2}[0-9]{2}[A-Z]{1}[0-9]{4}[A-Z]{2}$"

        return plate.range(of: normalPattern, options: .regularExpression) != nil ||
               plate.range(of: bharatPattern, options: .regularExpression) != nil
    }

    private func isModelValid(_ model: String) -> Bool {
        // Check if the model contains at least one letter and is not empty
        return model.rangeOfCharacter(from: .letters) != nil && !model.isEmpty
    }

    private func formatLicensePlate(_ plate: String) -> String {
        // Remove any characters that are not uppercase letters or digits
        return plate.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }

    // MARK: – Extracted save logic
    private func handleSave() async {
        if !isFormValid() {
            alertMessage = "Please ensure all vehicle information is in the correct format."
            showingAlert = true
            return
        }

        // Prepare file data from the selected files
        let imageData = image?.jpegData(compressionQuality: 0.8)
        // Safely get Data from URLs
        let rcData = rc.flatMap { try? Data(contentsOf: $0) }
        let pollutionData = pollutionCertificate.flatMap { try? Data(contentsOf: $0) }
        let permitData = permit.flatMap { try? Data(contentsOf: $0) }

        do {
            // Upload documents and get their URLs
            let docs = try await SupabaseManager.shared.addVehicleDocuments(
                imageData: imageData,
                rcCertData: rcData,
                pollutionCertData: pollutionData,
                permitData: permitData
            )

            // Now call addNewVehicle with the collected data and uploaded document URLs
            try await SupabaseManager.shared.addNewVehicle(
                licensePlateNo: licensePlate, // Use the formatted state variable
                type: type.rawValue, // Convert VehicleType to its raw String value
                model: model.isEmpty ? nil : model,
                fastagNo: fastagNo.isEmpty ? nil : fastagNo,
                imageUrl: docs.imageUrl,
                rcCertificateUrl: docs.rcCertificateUrl,
                pollutionCertificateUrl: docs.pollutionCertificateUrl,
                permitUrl: docs.permitUrl
            )

            // If save is successful, dismiss the view
            dismiss()

        } catch {
            // Handle errors during file preparation, upload, or vehicle creation
            print("Failed to save vehicle:", error)
            // Consider showing a more specific error alert to the user
            alertMessage = "Failed to save vehicle. Please try again."
            showingAlert = true
        }
    }
}
