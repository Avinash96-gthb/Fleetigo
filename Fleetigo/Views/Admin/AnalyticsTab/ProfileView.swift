import SwiftUI
import SVGKit
import PhotosUI
import WebKit
import Foundation
import Supabase

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel = ProfileViewModel()
    @State private var isEditing = false
    @State private var editableAdminProfile = EditableAdminProfile()
    @State private var editableDriverProfile = EditableDriverProfile()
    @State private var editableTechnicianProfile = EditableTechnicianProfile()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showDeletePhotoAlert = false
    @State private var showDocumentsView = false
    @State private var showAccessibilityAlert = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    let customBlue = Color(hex: "#4E8FFF")
    let customRed = Color(hex: "#FF5A5F")
    let genders = ["Male", "Female", "Non-binary"]
    let experienceYears = Array(1...50).map { String($0) }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading Profile...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                } else {
                    Form {
                        Section {
                            profilePictureSection
                        }
                        .listRowBackground(Color.clear)

                        switch viewModel.userRole {
                        case .admin:
                            adminSection
                        case .driver:
                            driverSection
                        case .technician:
                            technicianSection
                        case .none:
                            Text("No profile information available.")
                        }

                        if viewModel.userRole != .admin {
                            Section("Documents") {
                                Button {
                                    showDocumentsView = true
                                } label: {
                                    HStack {
                                        Text("View Documents")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }

                        Section("Appearance") {
                            Toggle("Dark Mode", isOn: $isDarkMode)
                                .onChange(of: isDarkMode) { newValue in
                                    UIApplication.shared.windows.first?.overrideUserInterfaceStyle = newValue ? .dark : .light
                                }
                        }

                        Section("Accessibility") {
                            VStack(alignment: .leading, spacing: 8) {
                                Button {
                                    showAccessibilityAlert = true
                                } label: {
                                    HStack {
                                        Text("Show Vehicle Motion Cues")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray)
                                    }
                                }
                                Text("Helps reduce motion sickness when using the app in a moving vehicle.")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }

                        Section {
                            Button("Sign Out") {
                                appState.signOut()
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .onAppear {
                        updateEditableProfiles()
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        isEditing ? saveChanges() : startEditing()
                    }
                    .foregroundColor(customBlue)
                }
                if isEditing {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            cancelEditing()
                        }
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        print("Selected new photo data: \(data.count) bytes")
                    }
                }
            }
            .alert("Delete Photo", isPresented: $showDeletePhotoAlert) {
                Button("Delete", role: .destructive) {
                    print("Deleting profile photo")
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete your profile photo?")
            }
            .alert("Accessibility Settings", isPresented: $showAccessibilityAlert) {
                Button("OK") {
                    openSettingsHomePage()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You will now be redirected to the Settings app.\n\nTo enable 'Vehicle Motion Cues', Go to \n'Accessibility' > select 'Motion' > Turn on 'Show Vehicle Motion Cues'")
            }
            .sheet(isPresented: $showDocumentsView) {
                if viewModel.userRole == .driver {
                    DocumentsView(documents: .constant([]), isEditing: $isEditing)
                } else if viewModel.userRole == .technician {
                    DocumentsView(documents: .constant([]), isEditing: $isEditing)
                } else {
                    Text("Documents not available for this profile type.")
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .onReceive(viewModel.$adminProfile) { newAdminProfile in
            if !isEditing, let _ = newAdminProfile {
                updateEditableProfiles()
            }
        }
        .onReceive(viewModel.$driverProfile) { newDriverProfile in
            if !isEditing, let _ = newDriverProfile {
                updateEditableProfiles()
            }
        }
        .onReceive(viewModel.$technicianProfile) { newTechnicianProfile in
            if !isEditing, let _ = newTechnicianProfile {
                updateEditableProfiles()
            }
        }
    }

    // MARK: - Role Sections

    private var adminSection: some View {
        Group {
            if let _ = viewModel.adminProfile {
                Section("Admin Information") {
                    editableField("Full Name", text: $editableAdminProfile.full_name)
                    editableField("Email", text: $editableAdminProfile.email).disabled(true)
                    editableField("Phone", text: $editableAdminProfile.phone)
                    editableField("Gender", text: $editableAdminProfile.gender)
                    if let dob = editableAdminProfile.date_of_birth {
                        Text("Date of Birth: \(dob, style: .date)")
                    }
                }
            }
        }
    }

    private var driverSection: some View {
        Group {
            if let _ = viewModel.driverProfile {
                Section("Driver Information") {
                    editableField("Name", text: $editableDriverProfile.name)
                    editableField("Email", text: $editableDriverProfile.email).disabled(true)
                    editableField("Phone", text: $editableDriverProfile.phone)
                    editableField("Aadhaar Number", text: $editableDriverProfile.aadhar_number)
                    editableField("Driver's License", text: $editableDriverProfile.driver_license)
                    experiencePicker(experience: $editableDriverProfile.experience)
                    ratingView(rating: $editableDriverProfile.rating)
                }
            }
        }
    }

    private var technicianSection: some View {
        Group {
            if let _ = viewModel.technicianProfile {
                Section("Technician Information") {
                    editableField("Name", text: $editableTechnicianProfile.name)
                    editableField("Email", text: $editableTechnicianProfile.email).disabled(true)
                    editableField("Phone", text: $editableTechnicianProfile.phone)
                    experiencePicker(experience: $editableTechnicianProfile.experience)
                    editableField("Specialty", text: $editableTechnicianProfile.specialty)
                    ratingView(rating: $editableTechnicianProfile.rating)
                }
            }
        }
    }

    // MARK: - UI Helpers

    private var profilePictureSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 110, height: 110)
                .foregroundColor(.gray)
                .overlay(alignment: .bottomTrailing) {
                    if isEditing {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Image(systemName: "plus.circle.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 24))
                                .foregroundColor(customBlue)
                                .background(Circle().fill(Color(.systemBackground)))
                        }
                    }
                }

            if let admin = viewModel.adminProfile {
                Text(admin.full_name ?? "Admin")
                    .font(.title3)
                    .fontWeight(.semibold)
            } else if let driver = viewModel.driverProfile {
                Text(driver.name ?? "Driver")
                    .font(.title3)
                    .fontWeight(.semibold)
                if let rating = driver.rating {
                    ratingView(rating: .constant(rating))
                }
            } else if let tech = viewModel.technicianProfile {
                Text(tech.name ?? "Technician")
                    .font(.title3)
                    .fontWeight(.semibold)
                if let rating = tech.rating {
                    ratingView(rating: .constant(rating))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private func editableField(_ label: String, text: Binding<String?>) -> some View {
        HStack {
            Text(label)
            Spacer()
            if isEditing {
                TextField(label, text: text.bound)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(customBlue)
            } else {
                Text(text.wrappedValue ?? "N/A")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func experiencePicker(experience: Binding<Int?>) -> some View {
        HStack {
            Text("Experience (years)")
            Spacer()
            if isEditing {
                Picker("", selection: experience.bound) {
                    ForEach(experienceYears, id: \.self) { year in
                        Text(year).tag(Int(year) ?? 0)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(customBlue)
            } else {
                Text(experience.wrappedValue != nil ? String(experience.wrappedValue!) : "N/A")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func ratingView(rating: Binding<Double?>) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill").foregroundColor(.yellow)
            Text(rating.wrappedValue.map { String(format: "%.1f", $0) } ?? "N/A")
        }
        .padding(.top, 2)
    }

    // MARK: - Actions

    private func updateEditableProfiles() {
        if let admin = viewModel.adminProfile {
            editableAdminProfile = EditableAdminProfile(from: admin)
        } else if let driver = viewModel.driverProfile {
            editableDriverProfile = EditableDriverProfile(from: driver)
        } else if let tech = viewModel.technicianProfile {
            editableTechnicianProfile = EditableTechnicianProfile(from: tech)
        }
    }

    private func startEditing() {
        updateEditableProfiles()
        isEditing = true
    }

    private func cancelEditing() {
        isEditing = false
    }

    private func saveChanges() {
        isEditing = false
        switch viewModel.userRole {
        case .admin:
            print("Saving admin profile: \(editableAdminProfile)")
            // Implement save logic for admin
        case .driver:
            print("Saving driver profile: \(editableDriverProfile)")
            // Implement save logic for driver
        case .technician:
            print("Saving technician profile: \(editableTechnicianProfile)")
            // Implement save logic for technician
        case .none:
            break
        }
    }

    private func openSettingsHomePage() {
        if let url = URL(string: "App-prefs:root=") {
            UIApplication.shared.open(url, options: [:]) { success in
                if !success {
                    print("Failed to open Settings app. URL scheme may not be supported.")
                }
            }
        }
    }
}

// MARK: - Editable Profile Models
struct EditableAdminProfile {
    var id: UUID?
    var email: String? = ""
    var full_name: String?
    var phone: String?
    var gender: String?
    var created_at: Date?
    var factor_id: UUID?
    var is_2fa_enabled: Bool = false
    var date_of_birth: Date?

    init() {}

    init(from admin: AdminProfile) {
        self.id = admin.id
        self.email = admin.email
        self.full_name = admin.full_name
        self.phone = admin.phone
        self.gender = admin.gender
        self.created_at = admin.created_at
        self.factor_id = admin.factor_id
        self.is_2fa_enabled = admin.is_2fa_enabled
        self.date_of_birth = admin.date_of_birth
    }
}

struct EditableDriverProfile {
    var id: UUID?
    var email: String? = ""
    var name: String?
    var aadhar_number: String?
    var driver_license: String?
    var phone: String?
    var experience: Int?
    var rating: Double?
    var created_at: Date?
    var factor_id: UUID?
    var is_2fa_enabled: Bool = false
    
    init() {}
    
    init(from driver: DriverProfile) {
        self.id = driver.id
        self.email = driver.email
        self.name = driver.name
        self.aadhar_number = driver.aadhar_number
        self.driver_license = driver.driver_license
        self.phone = driver.phone
        self.experience = driver.experience
        self.rating = driver.rating
        self.created_at = driver.created_at
        self.factor_id = driver.factor_id
        self.is_2fa_enabled = driver.is_2fa_enabled
    }
}

struct EditableTechnicianProfile {
    var id: UUID?
    var email: String? = ""
    var name: String?
    var experience: Int?
    var specialty: String?
    var rating: Double?
    var created_at: Date?
    var factor_id: UUID?
    var is_2fa_enabled: Bool = false
    var phone: String?
    
    init() {}
    
    init(from tech: TechnicianProfile) {
        self.id = tech.id
        self.email = tech.email
        self.name = tech.name
        self.experience = tech.experience
        self.specialty = tech.specialty
        self.rating = tech.rating
        self.created_at = tech.created_at
        self.factor_id = tech.factor_id
        self.is_2fa_enabled = tech.is_2fa_enabled
        self.phone = tech.phone
    }
}

struct DocumentsView: View {
    @Binding var documents: [Document]
    @Binding var isEditing: Bool
    @State private var isImporting = false
    @State private var currentDocumentType: DocumentType?
    @State private var selectedDocument: Document?

    var body: some View {
        NavigationStack {
            Text("Document management needs to be implemented based on the actual data structure for each user role.")
                .padding()
                .navigationTitle("Documents")
                .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func handlePDFSelection(_ result: Result<[URL], Error>) {
        // ...
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.loadFileURL(url, allowingReadAccessTo: url)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

enum DocumentType: String, CaseIterable, Identifiable {
    case aadhar
    case license
    case medical
    var id: String { rawValue }
}

extension Binding where Value: Equatable {
    var bound: Self {
        return self
    }
}
extension Binding where Value == String? {
    var bound: Binding<String> {
        return Binding<String>(
            get: { self.wrappedValue ?? "" },
            set: { self.wrappedValue = $0 }
        )
    }
}
extension Binding where Value == Int? {
    var bound: Binding<Int> {
        return Binding<Int>(
            get: { self.wrappedValue ?? 0 },
            set: { self.wrappedValue = $0 }
        )
    }
}
extension Binding where Value == Double? {
    var bound: Binding<Double> {
        return Binding<Double>(
            get: { self.wrappedValue ?? 0.0 },
            set: { self.wrappedValue = $0 }
        )
    }
}
