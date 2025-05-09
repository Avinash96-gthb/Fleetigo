//
//  AddTechnicianView.swift
//  Fleetigo
//
//  Created by Avinash on 27/04/25.
//


import SwiftUI

// AddTechnicianView.swift

struct AddTechnicianView: View {
    @Environment(\.dismiss) var dismiss
    // REMOVED: @Binding var employeeList: [Employee]

    // Form state variables
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var experience: String = ""
    @State private var specialty: String = ""
    @State private var contactNumber: String = "" // Added to match Supabase function needs
    @State private var password: String = ""
    @State private var ratingString: String = "0.0" // Collect rating as string

    // State for loading and alert
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false // Track success for alert dismissal

    var body: some View {
        NavigationStack {
            ZStack { // Use ZStack for overlaying the loading indicator
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Technician Details")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            InputField(title: "Name", text: $name, placeholder: "Enter technician name", keyboardType: .default)
                                .accessibilityLabel("Technician name")
                            
                            InputField(title: "Email ID", text: $email, placeholder: "Enter email address", keyboardType: .emailAddress)
                                .autocapitalization(.none)
                                .accessibilityLabel("Technician email")
                            
                            InputField(title: "Contact Number", text: $contactNumber, placeholder: "Enter phone number", keyboardType: .phonePad)
                                .accessibilityLabel("Technician contact number")
                            
                            InputField(title: "Experience", text: $experience, placeholder: "Years as number", keyboardType: .numberPad)
                                .accessibilityLabel("Technician experience")
                            
                            InputField(title: "Specialty", text: $specialty, placeholder: "e.g., Electrical", keyboardType: .default)
                                .accessibilityLabel("Technician specialty")
                            
                            InputField(title: "Rating", text: $ratingString, placeholder: "e.g., 4.5", keyboardType: .decimalPad)
                                .accessibilityLabel("Technician rating")
                            
                            SecureInputField(title: "Password", text: $password, placeholder: "Minimum 6 characters")
                                .accessibilityLabel("Technician password")
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        Button {
                            Task { await saveTechnician() }
                        } label: {
                            Text("Save Technician")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(name.isEmpty || email.isEmpty || password.isEmpty || contactNumber.isEmpty || isLoading ? Color.blue.opacity(0.3) : Color.blue)
                                )
                                .foregroundColor(.white)
                        }
                        .disabled(name.isEmpty || email.isEmpty || password.isEmpty || contactNumber.isEmpty || isLoading)
                        .accessibilityLabel("Save technician")
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    .padding(.top, 16)
                }
                .navigationTitle("Add Technician")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                        .accessibilityLabel("Cancel adding technician")
                    }
                }
                
                // Overlay loading indicator
                if isLoading {
                    Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Adding Technician...")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 180, height: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                    )
                    .shadow(radius: 15)
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if isSuccess {
                    dismiss() // Dismiss view only on success
                }
                // Reset state if needed, or just let alert disappear
                isSuccess = false
            }
        } message: {
            Text(alertMessage)
        }
    }

    // Async function to handle the save logic
    private func saveTechnician() async {
        isLoading = true
        isSuccess = false // Reset success state
        // Don't use defer here, set isLoading = false before showing alert or returning

        // --- Validation ---
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty, !contactNumber.isEmpty else {
            alertTitle = "Missing Information"
            alertMessage = "Name, Email, Password, and Contact Number are required."
            isLoading = false // Stop loading before showing alert
            showingAlert = true
            return
        }
        // Validate email format (basic example)
        guard email.contains("@") else {
            alertTitle = "Invalid Email"
            alertMessage = "Please enter a valid email address."
            isLoading = false
            showingAlert = true
            return
        }
        // Validate password length
        guard password.count >= 6 else {
             alertTitle = "Password Too Short"
             alertMessage = "Password must be at least 6 characters long."
             isLoading = false
             showingAlert = true
             return
        }
        // Validate rating format
         guard let ratingValue = Double(ratingString), ratingValue >= 0.0 && ratingValue <= 5.0 else {
              alertTitle = "Invalid Rating"
              alertMessage = "Please enter a valid rating between 0.0 and 5.0."
              isLoading = false
              showingAlert = true
              return
         }
         // Validate experience (optional, but good practice)
          // let experienceInt = Int(experience) // Check if it's a valid integer if needed

        // --- API Call ---
        do {
            print("Attempting to create technician: \(email)")
            // Call the Supabase function directly via the manager
            try await SupabaseManager.shared.createTechnician(
                email: email,
                password: password,
                name: name,
                experience: experience, // Pass as String, function handles conversion
                specialty: specialty,
                rating: ratingValue // Pass the validated Double// Pass contact number
            )

            // --- Success ---
            print("Successfully created technician: \(email)")
            alertTitle = "Success"
            alertMessage = "Technician added successfully!"
            isSuccess = true
            isLoading = false // Stop loading *before* showing success alert
            showingAlert = true // Show success alert (which will dismiss the view)

        } catch {
            // --- Error ---
            print("Error adding technician: \(error)")
            alertTitle = "Error"
            // Provide a user-friendly error message
            let nsError = error as NSError
            if nsError.domain == "CreateTechnician" { // Check if it's our custom domain
                 alertMessage = nsError.localizedDescription // Show the message from the function
            } else {
                 alertMessage = "An unexpected error occurred. Please try again. (\(error.localizedDescription))"
            }
            isSuccess = false
            isLoading = false // Stop loading *before* showing error alert
            showingAlert = true // Show error alert
        }
    }
}

// Supporting custom input field components
struct InputField: View {
    var title: String
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(text.isEmpty ? Color.clear : Color.blue, lineWidth: 1)
                )
        }
    }
}

struct SecureInputField: View {
    var title: String
    @Binding var text: String
    var placeholder: String
    
    @State private var showPassword: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
                
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(text.isEmpty ? Color.clear : Color.blue, lineWidth: 1)
            )
        }
    }
}

// MARK: - AddDriverView

// AddDriverView.swift

// MARK: - AddDriverView

// AddDriverView.swift

struct AddDriverView: View {
    @Environment(\.dismiss) var dismiss
    // REMOVED: @Binding var employeeList: [Employee]

    // Form state variables
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var contactNumber: String = "" // Needs to be passed to Supabase function
    @State private var experience: String = "" // Keep as String for TextField
    @State private var licenseNumber: String = ""
    @State private var password: String = ""
    @State private var aadharNumber: String = "" // Added for Supabase function

    // Validation states
    @State private var nameError: String? = nil
    @State private var emailError: String? = nil
    @State private var contactError: String? = nil
    @State private var licenseError: String? = nil
    @State private var experienceError: String? = nil
    @State private var passwordError: String? = nil
    @State private var aadharError: String? = nil

    // State for loading and alert
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false

    var body: some View {
        NavigationStack {
            ZStack { // Use ZStack for overlaying the loading indicator
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Driver Details")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            InputFieldWithValidation(title: "Name", text: $name, placeholder: "Enter driver name", keyboardType: .default, error: nameError)
                                .accessibilityLabel("Driver name")
                                .onChange(of: name) { _ in validateName() }
                            
                            InputFieldWithValidation(title: "Email ID", text: $email, placeholder: "Enter email address", keyboardType: .emailAddress, error: emailError)
                                .autocapitalization(.none)
                                .accessibilityLabel("Driver email")
                                .onChange(of: email) { _ in validateEmail() }
                            
                            InputFieldWithValidation(title: "Contact Number", text: $contactNumber, placeholder: "Enter phone number", keyboardType: .phonePad, error: contactError)
                                .accessibilityLabel("Driver contact number")
                                .onChange(of: contactNumber) { _ in validateContactNumber() }
                            
                            InputFieldWithValidation(title: "License Number", text: $licenseNumber, placeholder: "Enter license number", keyboardType: .default, error: licenseError)
                                .accessibilityLabel("Driver license number")
                                .onChange(of: licenseNumber) { _ in validateLicenseNumber() }
                            
                            InputFieldWithValidation(title: "Aadhaar Number", text: $aadharNumber, placeholder: "Optional", keyboardType: .numberPad, error: aadharError)
                                .accessibilityLabel("Driver Aadhaar number")
                                .onChange(of: aadharNumber) { _ in validateAadharNumber() }
                            
                            InputFieldWithValidation(title: "Experience", text: $experience, placeholder: "Years as number", keyboardType: .numberPad, error: experienceError)
                                .accessibilityLabel("Driver experience")
                                .onChange(of: experience) { _ in validateExperience() }
                            
                            SecureInputFieldWithValidation(title: "Password", text: $password, placeholder: "Minimum 6 characters", error: passwordError)
                                .accessibilityLabel("Driver password")
                                .onChange(of: password) { _ in validatePassword() }
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        Button {
                            validateAllFields()
                            if formIsValid() {
                                Task { await saveDriver() }
                            }
                        } label: {
                            Text("Save Driver")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(formIsValid() && !isLoading ? Color.blue : Color.blue.opacity(0.3))
                                )
                                .foregroundColor(.white)
                        }
                        .disabled(!formIsValid() || isLoading)
                        .accessibilityLabel("Save driver")
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                    .padding(.top, 16)
                }
                .navigationTitle("Add Driver")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                        .foregroundColor(.blue)
                        .accessibilityLabel("Cancel adding driver")
                    }
                }
                
                // Overlay loading indicator
                if isLoading {
                    Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Adding Driver...")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .frame(width: 180, height: 180)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.regularMaterial)
                    )
                    .shadow(radius: 15)
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") {
                if isSuccess {
                    dismiss() // Dismiss view only on success
                }
                 isSuccess = false
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // Validation methods
    private func validateName() {
        if name.isEmpty {
            nameError = "Name is required"
        } else if name.count < 3 {
            nameError = "Name must be at least 3 characters"
        } else {
            nameError = nil
        }
    }
    
    private func validateEmail() {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if email.isEmpty {
            emailError = "Email is required"
        } else if !emailPredicate.evaluate(with: email) {
            emailError = "Please enter a valid email"
        } else {
            emailError = nil
        }
    }
    
    private func validateContactNumber() {
        let phoneRegex = "^[0-9]{10}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        
        if contactNumber.isEmpty {
            contactError = "Contact number is required"
        } else if !phonePredicate.evaluate(with: contactNumber) {
            contactError = "Please enter a valid 10-digit number"
        } else {
            contactError = nil
        }
    }
    
    private func validateLicenseNumber() {
        if licenseNumber.isEmpty {
            licenseError = "License number is required"
        } else if licenseNumber.count < 5 {
            licenseError = "Enter a valid license number"
        } else {
            licenseError = nil
        }
    }
    
    private func validateAadharNumber() {
        if !aadharNumber.isEmpty {
            let aadharRegex = "^[0-9]{12}$"
            let aadharPredicate = NSPredicate(format: "SELF MATCHES %@", aadharRegex)
            
            if !aadharPredicate.evaluate(with: aadharNumber) {
                aadharError = "Aadhaar must be 12 digits"
            } else {
                aadharError = nil
            }
        } else {
            aadharError = nil // Optional field
        }
    }
    
    private func validateExperience() {
        if !experience.isEmpty {
            if let expValue = Int(experience) {
                if expValue < 0 || expValue > 50 {
                    experienceError = "Enter a value between 0-50"
                } else {
                    experienceError = nil
                }
            } else {
                experienceError = "Please enter a valid number"
            }
        } else {
            experienceError = nil // Optional field
        }
    }
    
    private func validatePassword() {
        if password.isEmpty {
            passwordError = "Password is required"
        } else if password.count < 6 {
            passwordError = "Must be at least 6 characters"
        } else if !password.contains(where: { $0.isLowercase }) ||
                  !password.contains(where: { $0.isUppercase }) ||
                  !password.contains(where: { $0.isNumber }) {
            passwordError = "Include uppercase, lowercase and number"
        } else {
            passwordError = nil
        }
    }
    
    private func validateAllFields() {
        validateName()
        validateEmail()
        validateContactNumber()
        validateLicenseNumber()
        validateAadharNumber()
        validateExperience()
        validatePassword()
    }
    
    private func formIsValid() -> Bool {
        return nameError == nil &&
               emailError == nil &&
               contactError == nil &&
               licenseError == nil &&
               passwordError == nil &&
               aadharError == nil &&
               experienceError == nil &&
               !name.isEmpty &&
               !email.isEmpty &&
               !contactNumber.isEmpty &&
               !licenseNumber.isEmpty &&
               !password.isEmpty
    }

    // Async function to handle the save logic
    private func saveDriver() async {
        isLoading = true
        isSuccess = false

        // --- API Call ---
        do {
            print("Attempting to create driver: \(email)")
            try await SupabaseManager.shared.createDriver(
                email: email,
                password: password,
                name: name,
                driverLicense: licenseNumber,
                phone: contactNumber, // Pass contact number
                experience: experience // Pass as String
            )

            // --- Success ---
            print("Successfully created driver: \(email)")
            alertTitle = "Success"
            alertMessage = "Driver added successfully!"
            isSuccess = true
            isLoading = false
            showingAlert = true

        } catch {
            // --- Error ---
             print("Error adding driver: \(error)")
            alertTitle = "Error"
            let nsError = error as NSError
            if nsError.domain == "CreateDriver" {
                 alertMessage = nsError.localizedDescription
            } else {
                 alertMessage = "An unexpected error occurred. Please try again. (\(error.localizedDescription))"
            }
            isSuccess = false
            isLoading = false
            showingAlert = true
        }
    }
}

// Supporting custom input field components with validation
struct InputFieldWithValidation: View {
    var title: String
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType
    var error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(error != nil ? Color.red : (text.isEmpty ? Color.clear : Color.blue), lineWidth: 1)
                )
            
            if let errorText = error {
                Text(errorText)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
                    .transition(.opacity)
            }
        }
    }
}

struct SecureInputFieldWithValidation: View {
    var title: String
    @Binding var text: String
    var placeholder: String
    var error: String?
    
    @State private var showPassword: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
                
                Button(action: {
                    showPassword.toggle()
                }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(error != nil ? Color.red : (text.isEmpty ? Color.clear : Color.blue), lineWidth: 1)
            )
            
            if let errorText = error {
                Text(errorText)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
                    .transition(.opacity)
            }
        }
    }
}
//// Supporting custom input field components
//struct InputField: View {
//    var title: String
//    @Binding var text: String
//    var placeholder: String
//    var keyboardType: UIKeyboardType
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(title)
//                .font(.subheadline)
//                .fontWeight(.medium)
//                .foregroundColor(.secondary)
//            
//            TextField(placeholder, text: $text)
//                .keyboardType(keyboardType)
//                .padding()
//                .background(
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color(.systemGray6))
//                )
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(text.isEmpty ? Color.clear : Color.blue, lineWidth: 1)
//                )
//        }
//    }
//}
//
//struct SecureInputField: View {
//    var title: String
//    @Binding var text: String
//    var placeholder: String
//    
//    @State private var showPassword: Bool = false
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(title)
//                .font(.subheadline)
//                .fontWeight(.medium)
//                .foregroundColor(.secondary)
//            
//            HStack {
//                if showPassword {
//                    TextField(placeholder, text: $text)
//                } else {
//                    SecureField(placeholder, text: $text)
//                }
//                
//                Button(action: {
//                    showPassword.toggle()
//                }) {
//                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
//                        .foregroundColor(.secondary)
//                }
//            }
//            .padding()
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(Color(.systemGray6))
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(text.isEmpty ? Color.clear : Color.blue, lineWidth: 1)
//            )
//        }
//    }
//}
