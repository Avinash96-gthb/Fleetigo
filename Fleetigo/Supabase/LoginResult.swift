//
//  LoginResult.swift
//  Fleetigo
//
//  Created by Avinash on 25/04/25.
//


import UIKit

struct LoginResult {
    let shouldEnroll: Bool
    let shouldChallenge: Bool
    let qrImage: UIImage?
    let secret: String?
    let factorId: String?
    let challengeId: String?
    let userId: String
    let role: Role
}
