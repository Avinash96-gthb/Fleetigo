////
////  ProfileSheet.swift
////  Fleetigo
////
////  Created by Avinash on 21/04/25.
////
//
//import SwiftUI
//
//struct ProfileSheet: View {
//    @State private var show2FAQRCode = false
//    @State private var qrURL: String?
//
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("Profile Settings")
//                .font(.title2)
//
//            Text(SupabaseManager.shared.getUser()?.email ?? "")
//                .font(.subheadline)
//
////            Button("Enable 2FA") {
////                Task {
////                    do {
////                        let factor = try await SupabaseManager.shared.enable2FA()
////                        qrURL = factor.totp?.qrCode
////                        show2FAQRCode = true
////                    } catch {
////                        print("2FA Error: \(error)")
////                    }
////                }
////            }
//
//            if show2FAQRCode, let qr = qrURL {
//                AsyncImage(url: URL(string: qr)) { image in
//                    image.resizable()
//                } placeholder: {
//                    ProgressView()
//                }
//                .frame(width: 200, height: 200)
//            }
//        }
//        .padding()
//    }
//}
