import SwiftUI

struct TOTPChallengeView: View {
  let factorId: String
  let onVerified: () -> Void

  @State private var code = ""
  @State private var errorMessage = ""    // make mutable String

  var body: some View {
    VStack(spacing: 16) {
      Text("Enter your MFA code")
      TextField("123456", text: $code)
        .textFieldStyle(.roundedBorder)
        .keyboardType(.numberPad)
      Button("Verify") {
        Task { await verifyExistingFactor() }
      }
      .buttonStyle(.borderedProminent)
      if !errorMessage.isEmpty {
        Text(errorMessage).foregroundColor(.red)
      }
    }
    .padding()
  }
  
  private func verifyExistingFactor() async {
    do {
      let challenge = try await SupabaseManager.shared.createChallenge(factorId: factorId)
      _ = try await SupabaseManager.shared.verifyChallenge(
        factorId: factorId,
        challengeId: challenge.id,
        code: code
      )
      onVerified()
    } catch {
      // assign to the mutable String
      errorMessage = error.localizedDescription
    }
  }
}
