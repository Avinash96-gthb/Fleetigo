import SwiftUI
import LocalAuthentication // Added for Face ID verification

enum Role: String, CaseIterable, Identifiable {
    case admin = "Admin"
    case driver = "Driver"
    case maintenance = "Technician"

    var id: String { rawValue }

    var logoImage: String {
        switch self {
        case .admin: return "FleetigoAdminLogo"
        case .driver: return "FleetigoDriverLogo"
        case .maintenance: return "FleetigoGarageLogo"
        }
    }
}

struct TOTPChallengeSheetData: Identifiable {
    let id = UUID()
    let userId: String
    let role: Role
    let factorId: String
    let challengeId: String
}

struct TOTPEnrollmentSheetData: Identifiable {
    let id = UUID()
    let userId: String
    let role: Role
    let qrImage: UIImage
    let secret: String
    let factorId: String
}

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var emailValid: Bool = true
    @State private var showLoginAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isRegistering: Bool = false
    @EnvironmentObject var appState: AppState

    @State private var totpEnrollmentSheetData: TOTPEnrollmentSheetData? = nil
    @State private var totpChallengeSheetData: TOTPChallengeSheetData? = nil
    @Environment(\.colorScheme) var colorScheme
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                mainContentView
                if isLoading {
                    ProgressView("Logging in...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(20)
                        .background(Color.secondary.opacity(0.3))
                        .cornerRadius(10)
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showLoginAlert) {
                Alert(
                    title: Text("Login Failed"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .sheet(item: $totpEnrollmentSheetData) { data in
                TOTPEnrollView(data: data) {
                    self.appState.isLoggedIn = true
                    totpEnrollmentSheetData = nil
                }
            }
            .sheet(item: $totpChallengeSheetData) { data in
                TOTPChallengeView(
                    userId: data.userId,
                    role: data.role.rawValue,
                    factorId: data.factorId,
                    challengeId: data.challengeId
                ) {
                    self.appState.isLoggedIn = true
                    totpChallengeSheetData = nil
                }
            }
            .background(
                NavigationLink(
                    destination: RegisterAdminView(),
                    isActive: $isRegistering,
                    label: { EmptyView() }
                )
            )
        }
    }

    private var backgroundView: some View {
        Color(colorScheme == .dark ? .black : .white)
            .ignoresSafeArea()
    }

    private var mainContentView: some View {
        VStack(spacing: 30) {
            topSpacerView
            logoSectionView
            rolePickerSectionView
            inputFieldsSectionView
            loginButtonSectionView
            registerLinkSectionView
            Spacer()
        }
        .padding()
        .onChange(of: appState.selectedRole) { _ in
            email = ""
            password = ""
            emailValid = true
        }
    }

    private var topSpacerView: some View {
        Spacer().frame(height: 80)
    }

    private var logoSectionView: some View {
        logoImageView
            .padding(.bottom, 20)
    }

    private var logoImageView: some View {
        Image(appState.selectedRole.logoImage)
            .resizable()
            .scaledToFit()
            .frame(width: 250, height: 100)
            .padding(.leading, 35)
            .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.3), value: appState.selectedRole)
            .accessibilityLabel("Fleetigo \(appState.selectedRole.rawValue) logo")
    }

    private var rolePickerSectionView: some View {
        Picker("Role", selection: $appState.selectedRole) {
            ForEach(Role.allCases) { role in
                Text(role.rawValue)
                    .tag(role)
                    .font(.system(size: 18, weight: .medium))
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .frame(height: 50)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .accessibilityLabel("Role selection")
        .accessibilityHint("Select your role")
    }

    private var inputFieldsSectionView: some View {
        VStack(spacing: 15) {
            emailFieldView
            passwordFieldView
            forgotPasswordLinkView
        }
        .padding(.horizontal, 20)
    }

    private var emailFieldView: some View {
        VStack(alignment: .leading) {
            emailTextFieldView
            if !emailValid && !email.isEmpty {
                Text("Invalid email format")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var emailTextFieldView: some View {
        TextField("Enter your email", text: $email)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 50)
            .background(emailFieldBackgroundView)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .onChange(of: email) { _ in
                validateEmail()
            }
            .accessibilityLabel("Email input")
    }

    private var emailFieldBackgroundView: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
    }

    private var passwordFieldView: some View {
        VStack(alignment: .leading) {
            passwordInputView
            if !password.isEmpty && password.count < 6 {
                Text("Password must be at least 6 characters")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var passwordInputView: some View {
        HStack {
            passwordTextFieldView
            passwordEyeButtonView
        }
        .background(passwordFieldBackgroundView)
        .foregroundColor(colorScheme == .dark ? .white : .black)
    }

    private var passwordTextFieldView: some View {
        Group {
            if showPassword {
                TextField("Enter your password", text: $password)
            } else {
                SecureField("Enter your password", text: $password)
            }
        }
        .autocapitalization(.none)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 50, alignment: .leading)
        .accessibilityLabel("Password input")
    }

    private var passwordEyeButtonView: some View {
        Button(action: { showPassword.toggle() }) {
            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .gray)
                .padding(.trailing, 12)
        }
        .accessibilityLabel("Toggle password visibility")
    }

    private var passwordFieldBackgroundView: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
    }

    private var forgotPasswordLinkView: some View {
        HStack {
            Spacer()
            NavigationLink(destination: ForgotPasswordView()) {
                Text("Forgot Password?")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .accessibilityLabel("Forgot password link")
        }
    }

    private var loginButtonSectionView: some View {
        Button(action: {
            validateEmail()
            if !emailValid && !email.isEmpty {
                alertMessage = "Invalid email format"
                showLoginAlert = true
                return
            }
            if password.isEmpty || password.count < 6 {
                alertMessage = "Password is required and must be at least 6 characters"
                showLoginAlert = true
                return
            }
            Task {
                await performLogin()
            }
        }) {
            loginButtonContentView
        }
        .padding(.horizontal, 20)
        .disabled(email.isEmpty || password.isEmpty || !emailValid)
        .accessibilityLabel("Login button")
    }

    private var loginButtonContentView: some View {
        Text("Login")
            .font(.headline)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .frame(maxHeight: 50)
            .background(RoundedRectangle(cornerRadius: 30).fill(Color.black))
            .foregroundColor(.white)
    }

    private var registerLinkSectionView: some View {
        Group {
            if appState.selectedRole == .admin {
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .gray : .black)
                    Button(action: { isRegistering = true }) {
                        Text("Register Now")
                            .font(.caption)
                            .foregroundColor(.red)
                            .bold()
                    }
                }
                .padding(.top, 10)
                .accessibilityLabel("Register link")
            }
        }
    }

    private func validateEmail() {
        if email.isEmpty {
            emailValid = true
            return
        }
        let pattern = "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: email.utf16.count)
            emailValid = regex.firstMatch(in: email, options: [], range: range)?.range.length == email.utf16.count
        } else {
            emailValid = false
        }
    }

    private func performLogin() async {
        await MainActor.run {
            self.isLoading = true
            self.alertMessage = ""
            self.showLoginAlert = false
        }

        do {
            print("Performing login for role: \(appState.selectedRole.rawValue)...")
            let result = try await AuthManager.shared.performLogin(
                email: email,
                password: password,
                role: appState.selectedRole
            )

            print("Login result: \(result)")

            // Face ID verification
            let biometricsSuccess = await authenticateWithBiometrics()
            if !biometricsSuccess {
                await MainActor.run {
                    self.isLoading = false
                    self.alertMessage = "Face ID authentication failed."
                    self.showLoginAlert = true
                }
                return
            }

            await MainActor.run {
                self.isLoading = false

                if result.shouldEnroll {
                    guard let qrImage = result.qrImage,
                          let secret = result.secret,
                          let factorId = result.factorId else {
                        print("Error: Enrollment required but QR/Secret/Factor ID missing from LoginResult.")
                        self.alertMessage = "Failed to get enrollment details. Please try again."
                        self.showLoginAlert = true
                        return
                    }

                    print("Preparing TOTP Enrollment Data: userId=\(result.userId), role=\(appState.selectedRole), factorId=\(factorId)")
                    self.totpEnrollmentSheetData = TOTPEnrollmentSheetData(
                        userId: result.userId,
                        role: appState.selectedRole,
                        qrImage: qrImage,
                        secret: secret,
                        factorId: factorId
                    )
                    print("TOTP Enrollment triggered by setting sheet data")

                } else if result.shouldChallenge {
                    guard let factorId = result.factorId,
                          let cId = result.challengeId else {
                        print("Error: Challenge required but Factor ID or Challenge ID missing from LoginResult.")
                        self.alertMessage = "Failed to get challenge details. Please try again."
                        self.showLoginAlert = true
                        return
                    }

                    print("Preparing TOTP Challenge Data: userId=\(result.userId), role=\(appState.selectedRole), factorId=\(factorId), challengeId=\(cId)")
                    self.totpChallengeSheetData = TOTPChallengeSheetData(
                        userId: result.userId,
                        role: appState.selectedRole,
                        factorId: factorId,
                        challengeId: cId
                    )
                    print("TOTP Challenge triggered by setting sheet data")

                } else {
                    self.appState.isLoggedIn = true
                    print("Login successful, no 2FA step needed.")
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.alertMessage = error.localizedDescription
                self.showLoginAlert = true
            }
            print("Login error: \(error)")
        }
    }

    private func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return await withCheckedContinuation { continuation in
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to access the app") { success, authenticationError in
                    continuation.resume(returning: success)
                }
            }
        } else {
            // Biometrics not available or not enrolled
            return true // Proceed without Face ID
        }
    }
}
