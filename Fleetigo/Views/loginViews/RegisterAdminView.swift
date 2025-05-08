//
//  RegisterAdminView.swift
//  Fleetigo
//
//  Created by Avinash on 25/04/25.
//


import SwiftUI

struct RegisterAdminView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var gender: String = "Male"
    @State private var dob: Date = Date()
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = "Registration Failed"
    @State private var nameError: String? = nil
    @State private var emailError: String? = nil
    @State private var phoneError: String? = nil
    @State private var passwordError: String? = nil
    @State private var confirmPasswordError: String? = nil
    @State private var ageError: String? = nil
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false


    private let genders = ["Male", "Female"]

    var body: some View {
        ZStack {
            backgroundView
            mainContentView
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: backButton)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if alertTitle == "Congratulations!" {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }

    private var backgroundView: some View {
        Color(colorScheme == .dark ? .black : .white)
            .ignoresSafeArea()
    }

    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                titleView
                nameFieldView
                emailFieldView
                phoneNumberFieldView
                passwordFieldView
                confirmPasswordFieldView
                genderPickerView
                dobPickerView
                registerButtonView
                loginLinkView
                Spacer()
            }
            .padding()
        }
    }

    private var titleView: some View {
        HStack {
            Text("Register as ")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .gray : .black)
            Text("Admin")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.red)
            Spacer()
        }
        .padding(.bottom, 10)
    }

    private var backButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "chevron.left")
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .accessibilityLabel("Back button")
    }

    private var nameFieldView: some View {
        VStack(alignment: .leading) {
            TextField("Enter your full name", text: $name)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(fieldBackgroundView)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .onChange(of: name) { _ in validateName() }
                .accessibilityLabel("Full name input")
            if let error = nameError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var emailFieldView: some View {
        VStack(alignment: .leading) {
            TextField("Enter your email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(fieldBackgroundView)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .onChange(of: email) { _ in validateEmail() }
                .accessibilityLabel("Email input")
            if let error = emailError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var phoneNumberFieldView: some View {
        VStack(alignment: .leading) {
            TextField("Enter your phone number", text: $phoneNumber)
                .keyboardType(.phonePad)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(fieldBackgroundView)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .onChange(of: phoneNumber) { newValue in
                    let digits = newValue.filter { $0.isNumber }
                    phoneNumber = String(digits.prefix(10))
                    validatePhone()
                }
                .accessibilityLabel("Phone number input")
            if let error = phoneError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var passwordFieldView: some View {
        VStack(alignment: .leading) {
            HStack {
                if showPassword {
                    TextField("Enter your password", text: $password)
                } else {
                    SecureField("Enter your password", text: $password)
                }
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
            .autocapitalization(.none)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(fieldBackgroundView)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .onChange(of: password) { _ in validatePassword() }
            .accessibilityLabel("Password input")
            if let error = passwordError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var confirmPasswordFieldView: some View {
        VStack(alignment: .leading) {
            HStack {
                if showConfirmPassword {
                    TextField("Confirm your password", text: $confirmPassword)
                } else {
                    SecureField("Confirm your password", text: $confirmPassword)
                }
                Button(action: { showConfirmPassword.toggle() }) {
                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
            .autocapitalization(.none)
            .padding()
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(fieldBackgroundView)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .onChange(of: confirmPassword) { _ in validateConfirmPassword() }
            .accessibilityLabel("Confirm password input")
            if let error = confirmPasswordError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var genderPickerView: some View {
        Menu {
            ForEach(genders, id: \.self) { genderOption in
                Button(action: { gender = genderOption }) {
                    Text(genderOption)
                }
            }
        } label: {
            HStack {
                Text("Gender: \(gender)")
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()
                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(fieldBackgroundView)
        }
        .accessibilityLabel("Gender selection")
    }

    private var dobPickerView: some View {
        VStack(alignment: .leading) {
            DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .padding()
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(fieldBackgroundView)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .onChange(of: dob) { _ in validateAge() }
                .accessibilityLabel("Date of birth picker")
            if let error = ageError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var registerButtonView: some View {
        Button(action: {
            if validateForm() {
                isLoading = true
                Task {
                    do {
                        try await SupabaseManager.shared.createAdmin(
                            email: email,
                            password: password,
                            fullName: name,
                            phone: phoneNumber,
                            gender: gender,
                            dateOfBirth: dob
                        )
                        alertTitle = "Congratulations!"
                        alertMessage = "Registration Successful"
                        showAlert = true

                        // Perform navigation or additional actions after successful registration
                        DispatchQueue.main.async {
                            // Add navigation logic here
                            // For example, pop the view, navigate to another view, etc.
                            // If using NavigationStack:
                            // isRegistered = true // This can trigger the navigation to the root view
                            presentationMode.wrappedValue.dismiss()

                        }

                    } catch {
                        alertTitle = "Registration Failed"
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                    isLoading = false
                }
            } else {
                showAlert = true
            }
        }) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(Color.black))
            } else {
                Text("Register")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(Color.black))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 20)
        .disabled(isLoading || !formIsValid())
        .accessibilityLabel("Register button")
    }


    private var loginLinkView: some View {
        HStack(spacing: 4) {
            Text("Already have an account?")
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .gray : .black)
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("Login Now")
                    .font(.caption)
                    .foregroundColor(.red)
                    .bold()
            }
        }
        .padding(.top, 10)
        .accessibilityLabel("Login link")
    }

    private var fieldBackgroundView: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
    }

    // Validation Functions
    private func validateName() {
        nameError = name.isEmpty ? "Full name is required" : nil
    }

    private func validateEmail() {
        if email.isEmpty {
            emailError = "Email is required"
        } else {
            let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: email.utf16.count)
                emailError = regex.firstMatch(in: email, options: [], range: range) == nil ? "Invalid email format" : nil
            } else {
                emailError = "Invalid email format"
            }
        }
    }

    private func validatePhone() {
        let digits = phoneNumber.filter { $0.isNumber }
        phoneError = digits.count != 10 ? "Phone number must be 10 digits" : nil
    }

    private func validatePassword() {
        if password.isEmpty {
            passwordError = "Password is required"
        } else if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
        } else {
            passwordError = nil
        }
    }

    private func validateConfirmPassword() {
        confirmPasswordError = confirmPassword != password ? "Passwords do not match" : nil
    }

    private func validateAge() {
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: dob, to: now)
        ageError = (ageComponents.year ?? 0) < 18 ? "You must be at least 18" : nil
    }

    private func validateForm() -> Bool {
        validateName()
        validateEmail()
        validatePhone()
        validatePassword()
        validateConfirmPassword()
        validateAge()

        let errors = [nameError, emailError, phoneError, passwordError, confirmPasswordError, ageError]
        if let firstError = errors.compactMap({ $0 }).first {
            alertTitle = "Registration Failed"
            alertMessage = firstError
            return false
        }
        return true
    }

    private func formIsValid() -> Bool {
        return nameError == nil && emailError == nil && phoneError == nil && passwordError == nil && confirmPasswordError == nil && ageError == nil
            && !name.isEmpty && !email.isEmpty && !phoneNumber.isEmpty && !password.isEmpty && !confirmPassword.isEmpty
    }
}

struct RegisterAdminView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RegisterAdminView()
                .preferredColorScheme(.light)
        }
        NavigationView {
            RegisterAdminView()
                .preferredColorScheme(.dark)
        }
    }
}
