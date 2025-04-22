import Supabase
import Foundation
import UIKit
import WebKit


struct MfaFactor: Decodable {
    let id: String
    let factorType: String
    let status: String
}

/// Response when enrolling a new TOTP factor
struct MFAEnrollResponse: Decodable {
    let id: String
    let secret: String
    let uri: String
    let totp: TOTPInfo?
}

/// Holds QR code and secret for TOTP
struct TOTPInfo: Decodable {
    let qrCode: String
    let secret: String
    let uri: String
}

/// Response when creating a challenge
struct MFAChallengeResponse: Decodable {
    let id: String
}


class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    private let client: SupabaseClient
    @Published var session: Session?

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: " ")!,
            supabaseKey: " "
        )
    }

    func signIn(email: String, password: String) async throws {
            let result = try await client.auth.signIn(email: email, password: password)
            DispatchQueue.main.async { self.session = result }
        }

        func signOut() async throws {
            try await client.auth.signOut()
            DispatchQueue.main.async { self.session = nil }
        }

        // MARK: — MFA Flows
        /// List existing TOTP factors
    func getAuthenticatorAssuranceLevel() async throws
       -> AuthMFAGetAuthenticatorAssuranceLevelResponse
     {
       try await client.auth.mfa.getAuthenticatorAssuranceLevel()
     }

     /// List all enrolled factors
     func listMFAFactors() async throws
       -> AuthMFAListFactorsResponse
     {
       try await client.auth.mfa.listFactors()
     }

     /// Begin TOTP enrollment (returns QR code & secret)
     func enrollTOTP(
       issuer: String? = nil,
       friendlyName: String? = nil
     ) async throws
       -> AuthMFAEnrollResponse
     {
       try await client.auth.mfa.enroll(
         params: MFAEnrollParams(issuer: issuer, friendlyName: friendlyName)
       )
     }

     /// Create a TOTP challenge (sends a code)
     func createChallenge(factorId: String) async throws
       -> AuthMFAChallengeResponse
     {
       try await client.auth.mfa.challenge(
         params: MFAChallengeParams(factorId: factorId)
       )
     }

     /// Verify the TOTP code and return an updated session
     func verifyChallenge(
       factorId: String,
       challengeId: String,
       code: String
     ) async throws -> Session
     {
       try await client.auth.mfa.verify(
         params: MFAVerifyParams(
           factorId: factorId,
           challengeId: challengeId,
           code: code
         )
       )
     }
}
