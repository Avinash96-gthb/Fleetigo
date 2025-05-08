//
//  AuthManager.swift
//  Fleetigo
//
//  Created by Avinash on 25/04/25.
//


import Foundation
import Supabase
import UIKit

class AuthManager {
    
    static let shared = AuthManager()
    
    // This method handles login and returns the result
    func performLogin(email: String, password: String, role: Role) async throws -> LoginResult {
        let session = try await SupabaseManager.shared.signIn(email: email, password: password)
        let userId = session.user.id.uuidString

        let roleTable = "\(role.rawValue.lowercased())_profiles"
        
        let emailExists = try await SupabaseManager.shared.verifyRoleForEmail(email: email, role: role)
        
        if !emailExists {
            throw NSError(domain: "AuthError", code: 403, userInfo: [NSLocalizedDescriptionKey: "This email does not have the correct role for \(role.rawValue)"])
        }
        
        let profile = try await SupabaseManager.shared.fetchProfile(userId: userId, roleTable: roleTable)
        
        if profile.is_2fa_enabled, let fid = profile.factor_id {
            let challengeId = try await SupabaseManager.shared.createMFAChallenge(factorId: fid)
            return LoginResult(
                shouldEnroll: false,
                shouldChallenge: true,
                qrImage: nil,
                secret: nil,
                factorId: fid,
                challengeId: challengeId,
                userId: userId,
                role: role
            )
        } else {
            let result = try await SupabaseManager.shared.enrollTOTP(email: email, userId: userId)
            return LoginResult(
                shouldEnroll: true,
                shouldChallenge: false,
                qrImage: result.qrCode,
                secret: result.secret,
                factorId: result.factorId,
                challengeId: nil,
                userId: userId,
                role: role
            )
        }
    }

}
