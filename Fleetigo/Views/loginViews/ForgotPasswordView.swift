//
//  ForgotPasswordView.swift
//  Fleetigo
//
//  Created by Deeptanshu Pal on 05/05/25.
//


import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appState: AppState // Add this to access selectedRole
    
    @State private var email: String = ""
    @State private var emailValid: Bool = true
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        ZStack {
            backgroundView
            
            VStack(alignment: .leading, spacing: 20) {
                backButtonView
                
                titleSection
                
                emailFieldView
                
                sendCodeButtonView
                
                Spacer()
                
                rememberPasswordView
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            if isLoading {
                GlassmorphicLoadingIndicator(message: "Sending reset link")
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Notification"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var backgroundView: some View {
        Color(colorScheme == .dark ? .black : .white)
            .ignoresSafeArea()
    }
    
    private var backButtonView: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(10)
                .background(
                    Circle()
                        .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                )
        }
        .accessibilityLabel("Back button")
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Forgot Password?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text("Don't worry! It occurs. Please enter the email address linked with your account.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 16)
        }
    }
    
    private var emailFieldView: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Enter your email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .frame(maxHeight: 50)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                )
                .onChange(of: email) { _ in
                    validateEmail()
                }
                .accessibilityLabel("Email input")
            
            if !emailValid && !email.isEmpty {
                Text("Invalid email format")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private var sendCodeButtonView: some View {
        Button(action: {
            handleSendCode()
        }) {
            Text("Send Code")
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.black)
                )
                .foregroundColor(.white)
        }
        .disabled(email.isEmpty || !emailValid || isLoading)
        .padding(.top, 20)
        .accessibilityLabel("Send code button")
    }
    
    // Dynamic button color based on selected role
    private var buttonColor: Color {
        appState.selectedRole.color
    }
    
    private var rememberPasswordView: some View {
        HStack(spacing: 4) {
            Text("Remember Password?")
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .gray : .black)
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Login")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(buttonColor) // Changed from .blue to use the dynamic color
            }
            .accessibilityLabel("Return to login")
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 20)
    }
    
    private func validateEmail() {
        if email.isEmpty {
            emailValid = true
            return
        }
        
        let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: email.utf16.count)
            emailValid = regex.firstMatch(in: email, options: [], range: range)?.range.length == email.utf16.count
        } else {
            emailValid = false
        }
    }
    
    private func handleSendCode() {
        validateEmail()
        
        if !emailValid {
            alertMessage = "Please enter a valid email address."
            showAlert = true
            return
        }
        
        // Simulate sending the code
        isLoading = true
        
        // This is where you would implement the actual password reset functionality
        // For now, we'll just simulate a delay and show a success message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            alertMessage = "A password reset link has been sent to your email address if it exists in our system."
            showAlert = true
        }
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ForgotPasswordView()
        }
        .preferredColorScheme(.light)
        
        NavigationView {
            ForgotPasswordView()
        }
        .preferredColorScheme(.dark)
    }
}