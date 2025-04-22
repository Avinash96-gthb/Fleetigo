import SwiftUI
import SVGKit

struct TOTPEnrollView: View {
  let factorId: String
  let qrCodeSVG: String
  let onComplete: () -> Void  // called on both register and skip

  @State private var code = ""
  @State private var errorMessage = ""

  var body: some View {
    VStack(spacing: 16) {
      // Display QR code (SVG) via WebView or other renderer
        if let uiImage = svgStringToUIImage(qrCodeSVG) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 200, height: 200)
                    } else {
                        Text("Failed to load QR code")
                            .foregroundColor(.red)
                    }

      Text("Enter the 6‑digit code from your authenticator app")
      TextField("123456", text: $code)
        .textFieldStyle(.roundedBorder)
        .keyboardType(.numberPad)

      HStack {
        Button("Register") {
          Task { await verifyEnrollment() }
        }
        .buttonStyle(.borderedProminent)

        Button("Skip") {
          onComplete()  // mark as registered and dismiss
        }
        .buttonStyle(.bordered)
      }

      if !errorMessage.isEmpty {
        Text(errorMessage).foregroundColor(.red)
      }
    }
    .padding()
  }

  private func verifyEnrollment() async {
    do {
      // Create a challenge & verify the code
      let challenge = try await SupabaseManager.shared.createChallenge(factorId: factorId)
      _ = try await SupabaseManager.shared.verifyChallenge(
        factorId: factorId,
        challengeId: challenge.id,
        code: code
      )
      onComplete()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

func svgStringToUIImage(_ svgString: String) -> UIImage? {
    guard let data = svgString.data(using: .utf8) else { return nil }
    let svgImage = SVGKImage(data: data)

    if svgImage == nil {
        print("SVGKImage failed to parse")
    }

    return svgImage?.uiImage
}



