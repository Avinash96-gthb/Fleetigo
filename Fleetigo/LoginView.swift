import SwiftUI
import SVGKit


struct LoginView: View {
    @StateObject private var manager = SupabaseManager.shared
      @AppStorage("hasRegisteredMFA") private var hasRegisteredMFA = false

      @State private var email = ""
      @State private var password = ""
      @State private var errorMessage = ""

      // MFA UI state
      @State private var showEnroll = false
      @State private var factorId = ""
      @State private var qrCodeSVG = ""
      @State private var navigateToHome = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                Button("Sign In") {
                    Task { await handleSignIn() }
                }
                .buttonStyle(.borderedProminent)
                if !errorMessage.isEmpty {
                    Text(errorMessage).foregroundColor(.red)
                }
                NavigationLink("", destination: HomeView(), isActive: $navigateToHome)
            }
            .padding()
            .sheet(isPresented: $showEnroll) {
                  TOTPEnrollView(
                    factorId: factorId,
                    qrCodeSVG: qrCodeSVG
                  ) {
                    // On enrolled or skipped
                    hasRegisteredMFA = true
                    navigateToHome = true
                  }
                }
        }
    }
    private func handleSignIn() async {
        do {
          try await manager.signIn(email: email, password: password)
          // If they’ve already registered in a prior session → go Home
          if hasRegisteredMFA {
            navigateToHome = true
          } else {
            // Enroll immediately (no need to listFactors)
              let uniqueFriendlyName = "\(email)-\(UUID().uuidString)"
              let enroll = try await manager.enrollTOTP(
                  issuer: "MyApp",
                  friendlyName: uniqueFriendlyName
              )
 // returns QR + secret :contentReference[oaicite:2]{index=2}
            factorId = enroll.id
            qrCodeSVG = enroll.totp?.qrCode ?? ""
            showEnroll = true
            print(qrCodeSVG)
          }
        } catch {
          errorMessage = error.localizedDescription
        }
      }
    }



