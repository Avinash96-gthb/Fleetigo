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
                Form {
                    Section(header: Text("Technician Details")) {
                        TextField("Name", text: $name)
                            .accessibilityLabel("Technician name")

                        TextField("Email ID", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .accessibilityLabel("Technician email")

                        TextField("Contact Number", text: $contactNumber) // Removed placeholder format
                            .keyboardType(.phonePad)
                            .accessibilityLabel("Technician contact number")

                        TextField("Experience (Years as number)", text: $experience) // Clarified input
                            .keyboardType(.numberPad) // Use number pad for experience
                            .accessibilityLabel("Technician experience")

                        TextField("Specialty (e.g., Electrical)", text: $specialty)
                            .accessibilityLabel("Technician specialty")

                        TextField("Rating (e.g., 4.5)", text: $ratingString)
                           .keyboardType(.decimalPad)
                           .accessibilityLabel("Technician rating")

                        SecureField("Password (minimum 6 characters)", text: $password)
                                .accessibilityLabel("Technician password")
                    }
                }
                .navigationTitle("Add Technician")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.blue) // Consider theme color
                        .accessibilityLabel("Cancel adding technician")
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            Task {
                                await saveTechnician()
                            }
                        }
                        .foregroundColor(.blue) // Consider theme color
                        // Disable save button if required fields are empty or loading
                        .disabled(name.isEmpty || email.isEmpty || password.isEmpty || contactNumber.isEmpty || isLoading) // Added contactNumber check
                        .accessibilityLabel("Save technician")
                    }
                }
                // Overlay loading indicator
                if isLoading {
                    Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                    ProgressView("Adding Technician...")
                        .padding()
                        .background(.regularMaterial) // Use material background
                        .cornerRadius(10)
                        .shadow(radius: 5)
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

    // State for loading and alert
    @State private var isLoading = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false

    var body: some View {
        NavigationStack {
            ZStack { // Use ZStack for overlaying the loading indicator
                Form {
                    Section(header: Text("Driver Details")) {
                        TextField("Name", text: $name)
                            .accessibilityLabel("Driver name")

                        TextField("Email ID", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .accessibilityLabel("Driver email")

                        TextField("Contact Number", text: $contactNumber)
                            .keyboardType(.phonePad)
                            .accessibilityLabel("Driver contact number")

                        TextField("License Number", text: $licenseNumber) // Removed placeholder
                            .accessibilityLabel("Driver license number")

                        TextField("Aadhaar Number (Optional)", text: $aadharNumber) // Added field
                           .keyboardType(.numberPad)
                           .accessibilityLabel("Driver Aadhaar number")

                        TextField("Experience (Years as number)", text: $experience) // Clarified input
                            .keyboardType(.numberPad)
                            .accessibilityLabel("Driver experience")

                        SecureField("Password (minimum 6 characters)", text: $password)
                                .accessibilityLabel("Driver password")
                    }
                }
                .navigationTitle("Add Driver")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { dismiss() }
                        .foregroundColor(.blue) // Consider theme color
                        .accessibilityLabel("Cancel adding driver")
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            Task { await saveDriver() }
                        }
                        .foregroundColor(.blue) // Consider theme color
                        // Disable save button if required fields are empty or loading
                        .disabled(name.isEmpty || email.isEmpty || password.isEmpty || licenseNumber.isEmpty || contactNumber.isEmpty || isLoading) // Added contactNumber check
                        .accessibilityLabel("Save driver")
                    }
                }
                // Overlay loading indicator
                if isLoading {
                    Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
                    ProgressView("Adding Driver...")
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(10)
                        .shadow(radius: 5)
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

    // Async function to handle the save logic
    private func saveDriver() async {
        isLoading = true
        isSuccess = false

        // --- Validation ---
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty, !licenseNumber.isEmpty, !contactNumber.isEmpty else {
            alertTitle = "Missing Information"
            alertMessage = "Name, Email, Password, License Number, and Contact Number are required."
            isLoading = false
            showingAlert = true
            return
        }
        guard email.contains("@") else {
            alertTitle = "Invalid Email"
            alertMessage = "Please enter a valid email address."
            isLoading = false
            showingAlert = true
            return
        }
        guard password.count >= 6 else {
             alertTitle = "Password Too Short"
             alertMessage = "Password must be at least 6 characters long."
             isLoading = false
             showingAlert = true
             return
        }
        // Optional: Add validation for license number format, Aadhaar format, experience number

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
