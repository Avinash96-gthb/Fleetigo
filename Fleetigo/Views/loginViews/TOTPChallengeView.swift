import SwiftUI
// Assuming SupabaseManager and Role are defined elsewhere

struct TOTPChallengeView: View {
    // Receive necessary data directly
    let userId: String
    let role: String
    let factorId: String
    @State var challengeId: String // Make mutable for resend
    let onVerified: () -> Void

    // Remove states related to initialization
    // @State private var isLoading = true // Removed

    @State private var code = ""
    @State private var errorMessage = ""
    @State private var isVerifying = false
    @State private var isResending = false


    var body: some View {
        VStack(spacing: 20) {
            // Remove the isLoading check wrapper
            // if isLoading { ... } else { ... } // Removed

            Text("Two-Factor Authentication")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 20)

            Text("Enter the 6-digit code from your authenticator app")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("123456", text: $code)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .frame(maxWidth: 180)
                .multilineTextAlignment(.center)
                .font(.title3)
                .padding(.vertical, 10)
                .onChange(of: code) { newValue in
                    code = newValue.filter { "0123456789".contains($0) }
                    if code.count > 6 {
                        code = String(code.prefix(6))
                    }
                }

            Button(action: {
                Task { await verifyCode() }
            }) {
                if isVerifying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Verify Code")
                        .fontWeight(.medium)
                }
            }
            .frame(minWidth: 200, minHeight: 44)
            .background(code.count == 6 ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(22)
            .disabled(isVerifying || code.count != 6 || isResending)

            Button("Resend Code") {
                Task { await fetchNewChallenge() }
            }
            .font(.footnote)
            .padding(.top, 8)
            .disabled(isVerifying || isResending)

            if isResending {
                ProgressView("Requesting new challenge...") // Changed text slightly
                    .padding(.top, 10)
            }

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.top, 10)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            #if DEBUG
            VStack(alignment: .leading, spacing: 4) {
                Divider()
                Text("Debug Info:").font(.caption).foregroundColor(.gray)
                Text("User ID: \(userId)").font(.caption).foregroundColor(.gray)
                Text("Role: \(role)").font(.caption).foregroundColor(.gray)
                Text("Factor ID: \(factorId)").font(.caption).foregroundColor(.gray)
                Text("Challenge ID: \(challengeId)").font(.caption).foregroundColor(.gray) // Use the @State var
                Text("Code Length: \(code.count)").font(.caption).foregroundColor(.gray)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            #endif
        }
        .padding()
        // Remove .onAppear { Task { await initializeChallenge() } }
    }

    // Removed initializeChallenge() function

    private func verifyCode() async {
        guard code.count == 6 else {
            errorMessage = "Please enter a 6-digit verification code."
            return
        }

        isVerifying = true
        errorMessage = ""

        do {
            // Use the passed factorId and the current challengeId
            print("Verifying code: \(code) for challenge: \(challengeId) with factor: \(factorId)")
            try await SupabaseManager.shared.verifyMFA(
                factorId: factorId,
                challengeId: challengeId, // Use the state variable
                code: code
            )
            print("Verification successful")
            DispatchQueue.main.async {
                self.onVerified() // Call the closure passed from LoginView
            }
        } catch {
            print("Verification failed: \(error)")
            errorMessage = "Verification failed: \(error.localizedDescription)"
            // Suggest resending if the error indicates expiry or invalid challenge
             if let nsError = error as NSError?, nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCannotParseResponse {
                 errorMessage = "Verification failed. The code might be invalid or expired. Try requesting a new code."
             } else if error.localizedDescription.lowercased().contains("expired") || error.localizedDescription.lowercased().contains("invalid") || error.localizedDescription.lowercased().contains("not found") {
                 errorMessage += "\nTry requesting a new code."
             }
        }
        isVerifying = false
    }

    private func fetchNewChallenge() async {
        isResending = true
        errorMessage = ""

        do {
            // Use the passed factorId to create a NEW challenge
            print("Requesting new challenge for factor: \(factorId)")
            let newChallengeId = try await SupabaseManager.shared.createMFAChallenge(factorId: factorId)
            // Update the state variable for the next verification attempt
            self.challengeId = newChallengeId
            self.code = "" // Clear the old code
            self.errorMessage = "A new verification challenge has been initiated. Enter the code from your app." // Updated message
             print("New challengeId: \(newChallengeId)")
        } catch {
            print("Challenge request failed: \(error)")
            errorMessage = "Failed to get a new challenge: \(error.localizedDescription)"
        }

        isResending = false
    }
}
