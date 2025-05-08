import SwiftUI
import UIKit // Needed for UIImage
import AnyCodable
// Assume AuthManager and SupabaseManager are available

struct TOTPEnrollView: View {
    // 1. Accept the data struct instead of individual parameters
    let data: TOTPEnrollmentSheetData
    let onComplete: () -> Void

    @State private var code = ""
    @State private var errorMessage = ""
    @State private var challengeId: String? // State for the challenge ID needed for verification

    var body: some View {
        NavigationView { // Add NavigationView for potential title/toolbar
            VStack(spacing: 16) {
                Text("Enroll in Two-Factor Authentication")
                    .font(.headline)

                // Display QR code from the data struct
                Image(uiImage: data.qrImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)

                if !data.secret.isEmpty {
                    Text("Manual key:").font(.footnote)
                    // Display secret key from the data struct
                    Text(data.secret)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .contextMenu { // Add context menu for easy copy
                            Button {
                                UIPasteboard.general.string = data.secret
                            } label: {
                                Label("Copy Secret Key", systemImage: "doc.on.doc")
                            }
                        }
                }

                TextField("Enter code from app", text: $code)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .padding(.horizontal)


                if !errorMessage.isEmpty {
                    Text(errorMessage).foregroundColor(.red).font(.caption)
                }

                // Buttons
                HStack {
                    Button("Verify and Activate") {
                        Task { await verifyEnrollment() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(code.isEmpty) // Disable if code is empty

                    // Resend Code button might not make sense for *initial* setup.
                    // A challenge is needed *before* verification, not after a failed code entry.
                    // The challenge is created `onAppear`. If the challenge expires,
                    // attempting verify will fail, and the user needs to try again.
                    // Keeping the button for demonstration, but its behavior might need refinement.
                     Button("Get New Challenge") { Task { await newChallenge() } }
                         .buttonStyle(.bordered)
                         .disabled(challengeId == nil) // Can only get new if old existed
                }
                .padding(.top)

                Spacer() // Push content to the top


            }
            .padding()
            .navigationTitle("MFA Setup") // Title for the sheet
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                 print("TOTPEnrollView appeared. Getting initial challenge for factor: \(data.factorId)")
                 // Get the initial challenge ID when the view appears
                 Task { await newChallenge() }
             }
        }
    }

    // Function to request a new challenge ID
    private func newChallenge() async {
        errorMessage = "" // Clear previous errors
        do {
            // Use the factor ID from the data struct
            let id = try await SupabaseManager.shared.createMFAChallenge(factorId: data.factorId)
            await MainActor.run {
                 challengeId = id
                 print("New challenge ID obtained: \(id)")
            }
        } catch {
            await MainActor.run {
                 errorMessage = "Failed to get verification code challenge: \(error.localizedDescription)"
                 print("Error getting new challenge: \(error)")
            }
        }
    }

    // Function to verify the user-entered code
    private func verifyEnrollment() async {
        guard let cid = challengeId else {
            // If challengeId is nil, we can't verify. Maybe show an error or retry getting challenge.
            print("Verification failed: No challenge ID available.")
            await MainActor.run {
                errorMessage = "Verification failed. Please try getting a new challenge."
            }
            return
        }

        errorMessage = "" // Clear previous errors
        // You might want a loading indicator here

        do {
            // Call the AuthManager to verify the code using the factor ID and challenge ID
            // AuthManager.verifyEnrollment combines creating challenge and verifying
            // OR AuthManager.verifyMFA takes challenge and code directly.
            // Let's use AuthManager.verifyEnrollment as defined in the conceptual AuthManager,
            // which internally calls SupabaseManager.shared.challengeAndVerifyTOTP
            // (which in turn calls createMFAChallenge and verifyMFA).
            // *Correction*: The current structure of TOTPEnrollView calls `newChallenge` on appear
            // and then `verifyEnrollment` which calls `verifyMFA`. This is a more direct
            // approach than calling `challengeAndVerifyTOTP`. Let's stick to this.
            // Need to ensure the profile update happens *after* successful MFA verification.
            // The profile update is needed *after* the initial enrollment & first verification.

            print("Attempting verification for factor \(data.factorId) with challenge \(cid) and code \(code)")
            try await SupabaseManager.shared.verifyMFA(
                factorId: data.factorId, // Use factor ID from data struct
                challengeId: cid,
                code: code
            )
            print("MFA Verification Successful for enrollment.")

            // --- Profile Update AFTER Successful Verification ---
            // This marks the user's profile in YOUR database as 2FA enabled.
            // This step should use the userId and role passed in the data struct.
             print("Updating profile after successful enrollment verification...")
            let tableName = "\(data.role.rawValue.lowercased())_profiles"
            let updateData: [String: AnyEncodable] = [ // Use AnyEncodable as per previous fix
                 "is_2fa_enabled": AnyEncodable(true)
                 // Note: factor_id was already set during the initial enrollTOTPAndGetSetupInfo call
             ]
            try await SupabaseManager.shared.client.database
                .from(tableName)
                .update(updateData)
                .eq("id", value: data.userId) // Use userId from data struct
                .execute()
             print("Profile updated successfully.")


            // Call the completion closure to signal success back to LoginView
            await MainActor.run {
                onComplete()
            }

        } catch {
            print("MFA Verification Failed: \(error.localizedDescription)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                // Consider clearing the code or getting a new challenge on failure
            }
        }
    }
}
