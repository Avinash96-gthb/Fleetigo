import SwiftUI
import PhotosUI
import UIKit

struct DriverOnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var hasUploadedProfilePicture = false
    @State private var hasUploadedAadhaarCard = false
    @State private var hasUploadedDrivingLicense = false
    @State private var hasUploadedFitnessCertificate = false
    
    // Photo Picker State
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var profileImage: Image? = nil
    
    // File Picker State
    @State private var showDocumentPicker = false
    @State private var selectedFileURL: URL? = nil
    @State private var currentDocumentType: Document1Type? = nil
    
    private var isGetStartedEnabled: Bool {
        return hasUploadedProfilePicture && hasUploadedAadhaarCard && hasUploadedDrivingLicense && hasUploadedFitnessCertificate
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#B1CEFF"), location: 0.0),
                    .init(color: Color.white, location: 0.20)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Registration")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 40)
                    .padding(.horizontal, 20)

                Text("Welcome! Please follow the following steps to get onboarded into fleetigo.")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                // Profile Picture Section
                OnboardingSectionView(
                    icon: Document1Type.profilePicture.iconName,
                    title: Document1Type.profilePicture.rawValue,
                    subtitle: Document1Type.profilePicture.subtitle,
                    statusText: hasUploadedProfilePicture ? "Uploaded" : "Upload",
                    statusColor: hasUploadedProfilePicture ? Color.green : Color(hex: "#4E8FFF"),
                    showCheckmark: hasUploadedProfilePicture,
                    content: {
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images,
                            photoLibrary: .shared()
                        ) {
                            HStack(spacing: 8) {
                                Text(hasUploadedProfilePicture ? "Uploaded" : "Upload")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(hasUploadedProfilePicture ? Color.green : Color(hex: "#4E8FFF"))

                                if hasUploadedProfilePicture {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "#4E8FFF"))
                                }
                            }
                        }
                        .onChange(of: selectedPhotoItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    profileImage = Image(uiImage: uiImage)
                                    hasUploadedProfilePicture = true
                                }
                            }
                        }
                    }
                )
                .padding(.horizontal, 20)

                // Aadhaar Card Section
                OnboardingSectionView(
                    icon: Document1Type.aadhaarCard.iconName,
                    title: Document1Type.aadhaarCard.rawValue,
                    subtitle: Document1Type.aadhaarCard.subtitle,
                    statusText: hasUploadedAadhaarCard ? "Uploaded" : "Upload",
                    statusColor: hasUploadedAadhaarCard ? Color.green : Color(hex: "#4E8FFF"),
                    showCheckmark: hasUploadedAadhaarCard,
                    content: {
                        Button(action: {
                            currentDocumentType = .aadhaarCard
                            showDocumentPicker = true
                        }) {
                            HStack(spacing: 8) {
                                Text(hasUploadedAadhaarCard ? "Uploaded" : "Upload")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(hasUploadedAadhaarCard ? Color.green : Color(hex: "#4E8FFF"))

                                if hasUploadedAadhaarCard {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "#4E8FFF"))
                                }
                            }
                        }
                    }
                )
                .padding(.horizontal, 20)

                // Driving License Section
                OnboardingSectionView(
                    icon: Document1Type.drivingLicense.iconName,
                    title: Document1Type.drivingLicense.rawValue,
                    subtitle: Document1Type.drivingLicense.subtitle,
                    statusText: hasUploadedDrivingLicense ? "Uploaded" : "Upload",
                    statusColor: hasUploadedDrivingLicense ? Color.green : Color(hex: "#4E8FFF"),
                    showCheckmark: hasUploadedDrivingLicense,
                    content: {
                        Button(action: {
                            currentDocumentType = .drivingLicense
                            showDocumentPicker = true
                        }) {
                            HStack(spacing: 8) {
                                Text(hasUploadedDrivingLicense ? "Uploaded" : "Upload")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(hasUploadedDrivingLicense ? Color.green : Color(hex: "#4E8FFF"))

                                if hasUploadedDrivingLicense {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "#4E8FFF"))
                                }
                            }
                        }
                    }
                )
                .padding(.horizontal, 20)

                // Fitness Certificate Section
                OnboardingSectionView(
                    icon: Document1Type.fitnessCertificate.iconName,
                    title: Document1Type.fitnessCertificate.rawValue,
                    subtitle: Document1Type.fitnessCertificate.subtitle,
                    statusText: hasUploadedFitnessCertificate ? "Uploaded" : "Upload",
                    statusColor: hasUploadedFitnessCertificate ? Color.green : Color(hex: "#4E8FFF"),
                    showCheckmark: hasUploadedFitnessCertificate,
                    content: {
                        Button(action: {
                            currentDocumentType = .fitnessCertificate
                            showDocumentPicker = true
                        }) {
                            HStack(spacing: 8) {
                                Text(hasUploadedFitnessCertificate ? "Uploaded" : "Upload")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(hasUploadedFitnessCertificate ? Color.green : Color(hex: "#4E8FFF"))

                                if hasUploadedFitnessCertificate {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "#4E8FFF"))
                                }
                            }
                        }
                    }
                )
                .padding(.horizontal, 20)

                Spacer()

                // Get Started Button
                Button(action: {
                    if isGetStartedEnabled {
                        UserDefaults.standard.set(true, forKey: "hasCompletedRegistration")
                        UserDefaults.standard.synchronize() // Ensure immediate save
                        hasCompletedOnboarding = true
                    }
                }) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isGetStartedEnabled ? Color(hex: "#4E8FFF") : Color(hex: "#4E8FFF").opacity(0.5))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .disabled(!isGetStartedEnabled)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker2(selectedFileURL: $selectedFileURL, hasUploaded: bindingForCurrentDocumentType())
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }
    
    private func bindingForCurrentDocumentType() -> Binding<Bool> {
        switch currentDocumentType {
        case .aadhaarCard:
            return $hasUploadedAadhaarCard
        case .drivingLicense:
            return $hasUploadedDrivingLicense
        case .fitnessCertificate:
            return $hasUploadedFitnessCertificate
        default:
            return .constant(false)
        }
    }
}

struct OnboardingSectionView<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let statusText: String
    let statusColor: Color
    let showCheckmark: Bool
    let content: () -> Content

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 23, height: 23)
                .foregroundColor(Color(hex: "#4E8FFF"))
                .padding(12)
                .background(Circle().fill(Color(hex: "#4E8FFF").opacity(0.2)))

            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            content()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct DocumentPicker2: UIViewControllerRepresentable {
    @Binding var selectedFileURL: URL?
    @Binding var hasUploaded: Bool

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker2

        init(_ parent: DocumentPicker2) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.selectedFileURL = url
            parent.hasUploaded = true
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}


