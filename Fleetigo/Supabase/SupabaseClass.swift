import Supabase
import Foundation
import UIKit
import WebKit
import CoreImage.CIFilterBuiltins
import PostgREST


class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    public let client: SupabaseClient
    public let serviceClient: SupabaseClient
    private let storageClient: Supabase.StorageApi


    @Published var session: Session?

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Supabaseurl)!,
            supabaseKey: supabaseServiceKey
        )
        
        serviceClient = SupabaseClient(
            supabaseURL: URL(string: Supabaseurl)!,
            supabaseKey: supabaseServiceKey
            )
        
        self.storageClient = client.storage
    }

    func signIn(email: String, password: String) async throws -> Session {
        let sess = try await client.auth.signIn(email: email, password: password)
        DispatchQueue.main.async { self.session = sess }
        print(sess)
        return sess
    }

    func signOut() async throws {
        try await client.auth.signOut()
        DispatchQueue.main.async { self.session = nil }
    }
    
    func getUserRole() async -> UserRole? {
        // Check if there's a current user with email
        guard let currentUserEmail = client.auth.currentUser?.email else {
            print("❌ No authenticated user or email not available")
            return nil
        }
        
        print("🔍 Looking up role for email: \(currentUserEmail)")
        
        // Function to check profile data
        func checkProfile(tableName: String, role: UserRole) async -> UserRole? {
            do {
                print("Checking \(tableName) table...")
                let result = try await client.database
                    .from(tableName)
                    .select("id, email") // Selecting necessary fields
                    .eq("email", value: currentUserEmail)
                    .limit(1)
                    .execute()
                
                // Print raw response for debugging
                print("📊 \(tableName) query raw response: \(result)")
                
                // Attempt to decode the response data as a UTF-8 string
                if let data = result.data as? Data, let decodedString = String(data: data, encoding: .utf8) {
                    print("📊 \(tableName) data as string: \(decodedString)")
                    
                    // Try to convert the string back to JSON format
                    if let jsonData = decodedString.data(using: .utf8),
                       let jsonArray = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]],
                       !jsonArray.isEmpty {
                        print("✅ User is a \(role)")
                        return role
                    } else {
                        print("⚠️ Failed to parse JSON or empty data for \(tableName)")
                    }
                } else {
                    print("⚠️ Could not decode response data as UTF-8 string for \(tableName)")
                }
            } catch {
                print("❌ Error querying \(tableName): \(error.localizedDescription)")
            }
            return nil
        }
        
        // Check each role profile table
        if let adminRole = await checkProfile(tableName: "admin_profiles", role: .admin) {
            return adminRole
        }
        
        if let driverRole = await checkProfile(tableName: "driver_profiles", role: .driver) {
            return driverRole
        }
        
        if let technicianRole = await checkProfile(tableName: "technician_profiles", role: .technician) {
            return technicianRole
        }
        
        print("❌ No matching role found for email: \(currentUserEmail)")
        return nil
    }

    
    func fetchAdminProfile() async throws -> AdminProfile? {
        guard let currentUserEmail = client.auth.currentUser?.email else {
            return nil
        }

        let response = try await client.database
            .from("admin_profiles")
            .select()
            .eq("email", value: currentUserEmail)
            .limit(1)
            .execute()

        let jsonData = response.data

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Raw JSON string from Supabase: \(jsonString)")
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder -> Date in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)

                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = isoFormatter.date(from: dateStr) {
                    return date
                }

                let simpleFormatter = DateFormatter()
                simpleFormatter.dateFormat = "yyyy-MM-dd"
                simpleFormatter.locale = .init(identifier: "en_US_POSIX")
                if let date = simpleFormatter.date(from: dateStr) {
                    return date
                }

                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date format: \(dateStr)")
            }

            let decoded = try decoder.decode([AdminProfile].self, from: jsonData)
            return decoded.first
        } catch {
            print("JSON decoding error: \(error)")
            return nil
        }
    }




    func fetchDriverProfile() async throws -> DriverProfile? {
        guard let currentUserEmail = client.auth.currentUser?.email else {
            return nil
        }

        let response = try await client.database
            .from("driver_profiles")
            .select()
            .eq("email", value: currentUserEmail)
            .limit(1)
            .execute()

        let jsonData = response.data

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Raw JSON string from Supabase (driver): \(jsonString)")
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)

                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = isoFormatter.date(from: dateStr) {
                    return date
                }

                let simpleFormatter = DateFormatter()
                simpleFormatter.dateFormat = "yyyy-MM-dd"
                simpleFormatter.locale = .init(identifier: "en_US_POSIX")
                if let date = simpleFormatter.date(from: dateStr) {
                    return date
                }

                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date format: \(dateStr)")
            }

            let decoded = try decoder.decode([DriverProfile].self, from: jsonData)
            return decoded.first
        } catch {
            print("Driver profile JSON decoding error: \(error)")
            return nil
        }
    }


    func fetchTechnicianProfile() async throws -> TechnicianProfile? {
        guard let currentUserEmail = client.auth.currentUser?.email else {
            return nil
        }

        let response = try await client.database
            .from("technician_profiles")
            .select()
            .eq("email", value: currentUserEmail)
            .limit(1)
            .execute()

        let jsonData = response.data

        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Raw JSON string from Supabase (technician): \(jsonString)")
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateStr = try container.decode(String.self)

                let isoFormatter = ISO8601DateFormatter()
                isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = isoFormatter.date(from: dateStr) {
                    return date
                }

                let simpleFormatter = DateFormatter()
                simpleFormatter.dateFormat = "yyyy-MM-dd"
                simpleFormatter.locale = .init(identifier: "en_US_POSIX")
                if let date = simpleFormatter.date(from: dateStr) {
                    return date
                }

                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date format: \(dateStr)")
            }

            let decoded = try decoder.decode([TechnicianProfile].self, from: jsonData)
            return decoded.first
        } catch {
            print("Technician profile JSON decoding error: \(error)")
            return nil
        }
    }
}

extension SupabaseManager {
    
    struct TOTPResponse: Decodable {
        let factorId: String
        let secret: String
        let issuer: String
        let account: String
    }
    
    func enrollTOTP(email: String, userId: String) async throws -> (qrCode: UIImage, secret: String, factorId: String) {
        let url = URL(string: "https://iduirgpqjxjiomekomwr.supabase.co/functions/v1/create_mfa_with_qr")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email, "user_id": userId])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // For debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Response: \(jsonString)")
        }
        
        // Check if we got an error response
        if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
           let errorMessage = errorResponse["error"] {
            throw NSError(domain: "SupabaseError", code: 401, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        let result = try JSONDecoder().decode(TOTPResponse.self, from: data)
        
        // Generate QR code locally using the secret
        let otpAuthURL = "otpauth://totp/\(result.issuer):\(result.account)?secret=\(result.secret)&issuer=\(result.issuer)"
        let qrImage = try generateQRCode(from: otpAuthURL)
        
        return (qrImage, result.secret, result.factorId)
    }
    
    func generateQRCode(from string: String) throws -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        guard let data = string.data(using: .utf8) else {
            throw NSError(domain: "QRGenerationError", code: 100,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to convert string to data"])
        }
        
        filter.message = data
        filter.correctionLevel = "M"  // Medium error correction
        
        guard let outputImage = filter.outputImage else {
            throw NSError(domain: "QRGenerationError", code: 101,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to generate QR code"])
        }
        
        // Scale the QR code to a reasonable size
        let scale = 10.0
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            throw NSError(domain: "QRGenerationError", code: 102,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create CGImage from CIImage"])
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    struct ChallengeResponse: Decodable {
        let id: String
        let type: String
        let expires_at: Int
    }
    
    func createMFAChallenge(factorId: String) async throws -> String {
        let url = URL(string: "https://iduirgpqjxjiomekomwr.supabase.co/auth/v1/factors/\(factorId)/challenge")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set the proper Supabase auth headers
        request.setValue("Bearer \(session?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseServiceKey, forHTTPHeaderField: "apikey")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        print("Challenge direct API response: \(String(data: data, encoding: .utf8) ?? "no data")")
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            throw NSError(domain: "SupabaseError", code: httpResponse.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create challenge: \(httpResponse.statusCode)"])
        }
        
        let decoded = try JSONDecoder().decode(ChallengeResponse.self, from: data)
        return decoded.id
    }
    
    func verifyMFA(factorId: String, challengeId: String, code: String) async throws {
        let url = URL(string: "https://iduirgpqjxjiomekomwr.supabase.co/auth/v1/factors/\(factorId)/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set the proper Supabase auth headers
        request.setValue("Bearer \(session?.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseServiceKey, forHTTPHeaderField: "apikey")
        
        // Create the verification payload
        let payload = ["challenge_id": challengeId, "code": code]
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Print response for debugging
        print("Verification direct API response: \(String(data: data, encoding: .utf8) ?? "no data")")
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            if let json = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = json["error_description"] ?? json["error"] {
                throw NSError(domain: "SupabaseError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: errorMessage])
            } else {
                throw NSError(domain: "SupabaseError", code: httpResponse.statusCode,
                              userInfo: [NSLocalizedDescriptionKey: "Verification failed: \(httpResponse.statusCode)"])
            }
        }
    }
    
    struct Profile: Decodable {
        let is_2fa_enabled: Bool
        let factor_id: String?
    }
    
    func fetchProfile(userId: String, roleTable: String? = nil) async throws -> Profile {
        // Determine which table to query based on the roleTable parameter
        let tableName = roleTable ?? "user_profiles"
        
        let response = try await client.from(tableName)
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
        
        print(response)
        
        // Ensure response.data is not nil
        guard let data = response.data as? Data else {
            throw NSError(domain: "SupabaseError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Profile data not found in \(tableName)"])
        }
        
        // Decode the profile data
        let decoder = JSONDecoder()
        let profile = try decoder.decode(Profile.self, from: data)
        
        return profile
    }
    
    func createTechnician(email: String, password: String, name: String, experience: String, specialty: String, rating: Double) async throws {
        guard let url = URL(string: "https://iduirgpqjxjiomekomwr.supabase.co/functions/v1/create_technician_user") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let serviceRoleKey = supabaseServiceKey
        request.setValue("Bearer \(serviceRoleKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "name": name,
            "experience": experience,
            "specialty": specialty,
            "rating": rating
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            throw NSError(domain: "CreateTechnician", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage?["error"] ?? "Unknown error"])
        }
    }
    
    func createDriver(email: String, password: String, name: String, driverLicense: String, phone: String, experience: String) async throws {
        guard let url = URL(string: "https://iduirgpqjxjiomekomwr.supabase.co/functions/v1/create_driver_user") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let serviceRoleKey = supabaseServiceKey // Replace with your actual Service Role Key
        request.setValue("Bearer \(serviceRoleKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "name": name,
            "driver_license": driverLicense,
            "phone": phone,
            "experience": experience
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            throw NSError(domain: "CreateDriver", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage?["error"] ?? "Unknown error"])
        }
    }
    
    func createAdmin(
        email: String,
        password: String,
        fullName: String,
        phone: String,
        gender: String,
        dateOfBirth: Date
    ) async throws {
        // Endpoint URL
        guard let url = URL(string: "https://iduirgpqjxjiomekomwr.supabase.co/functions/v1/create_admin_user") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set the required headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Make sure to use the correct Service Role Key in the Authorization header
        let serviceRoleKey = supabaseServiceKey// Replace with your actual Service Role Key
        request.setValue("Bearer \(serviceRoleKey)", forHTTPHeaderField: "Authorization")
        
        // Format the date to match the expected format ("yyyy-MM-dd")
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let formattedDateOfBirth = formatter.string(from: dateOfBirth)
        
        // Prepare the JSON body for the request
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "full_name": fullName,
            "phone": phone,
            "gender": gender,
            "date_of_birth": formattedDateOfBirth
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Perform the HTTP request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Handle non-200 responses
        if httpResponse.statusCode != 200 {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            throw NSError(
                domain: "CreateAdmin",
                code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: errorMessage?["error"] ?? "Unknown error"]
            )
        }
        
        // Success log (You can print or log the response body here)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Success: \(responseString)")
        }
    }
    
    
    func verifyRoleForEmail(email: String, role: Role) async -> Bool {
        let url = URL(string: "https://iduirgpqjxjiomekomwr.supabase.co/functions/v1/verify_role")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let serviceRoleKey = supabaseServiceKey// Replace with your actual Service Role Key
        request.setValue("Bearer \(serviceRoleKey)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "email": email,
            "role": role.rawValue
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try! await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let valid = json["valid"] as? Bool {
                return valid
            }
        }
        
        return false
    }
    
    func fetchFactorID(for userId: String, role: Role) async throws -> String {
        let roleTable = "\(role.rawValue.lowercased())_profiles"
        let profile = try await SupabaseManager.shared.fetchProfile(userId: userId, roleTable: roleTable)
        
        guard let factorId = profile.factor_id else {
            throw NSError(domain: "AuthError", code: 404, userInfo: [NSLocalizedDescriptionKey: "No factorId found for user"])
        }
        
        return factorId
    }
    
    func addNewVehicle(
        licensePlateNo: String,
        type: String?,
        model: String?,
        fastagNo: String?,
        imageUrl: String?,
        rcCertificateUrl: String?,
        pollutionCertificateUrl: String?,
        permitUrl: String?
    ) async throws {
        // Create the request body using the NewVehicle struct
        let newVehicle = NewVehicle(
            license_plate_no: licensePlateNo,
            type: type,
            model: model,
            fastag_no: fastagNo,
            image_url: imageUrl,
            rc_certificate_url: rcCertificateUrl,
            pollution_certificate_url: pollutionCertificateUrl,
            permit_url: permitUrl
        )
        
        // Encode the struct to JSON data
        let jsonData = try JSONEncoder().encode(newVehicle)
        
        // Create the URLRequest
        let URL = URL(string: "https://iduirgpqjxjiomekomwr.supabase.co/functions/v1/create_vehichle")!
        var request = URLRequest(url: URL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let serviceRoleKey = supabaseServiceKey
        request.setValue("Bearer \(serviceRoleKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        // Perform the network request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the HTTP response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // Handle successful response (status code 200-299)
        if (200..<300).contains(httpResponse.statusCode) {
            // Optionally decode the success message if needed
            // let successResponse = try JSONDecoder().decode(CreateVehicleSuccessResponse.self, from: data)
            print("Vehicle added successfully!")
            // No need to throw an error, the operation was successful
        } else {
            // Handle error response (status code outside 200-299)
            let errorResponse = try? JSONDecoder().decode(CreateVehicleErrorResponse.self, from: data)
            let errorMessage = errorResponse?.error ?? String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "SupabaseService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to add vehicle: \(errorMessage)"])
        }
    }
    
    func addVehicleDocuments(
        imageData: Data?,
        rcCertData: Data?,
        pollutionCertData: Data?,
        permitData: Data?
    ) async throws -> VehicleDocumentURLs {
        var imageUrl: String?
        var rcCertificateUrl: String?
        var pollutionCertificateUrl: String?
        var permitUrl: String?
        
        // Define bucket names and base paths (adjust as needed)
        let imageBucket = "vehichle-images" // Example bucket for images
        let docBucket = "vehicle-details" // Example bucket for documents
        
        // Ensure buckets exist and have appropriate RLS policies configured in Supabase
        
        // Upload Image if data is provided
        if let data = imageData {
            let filePath = "images/\(UUID().uuidString).jpg" // Generate unique filename
            imageUrl = try await uploadFile(fileData: data, bucketName: imageBucket, filePath: filePath, contentType: "image/jpeg") // Adjust content type
        }
        
        // Upload RC Certificate if data is provided
        if let data = rcCertData {
            let filePath = "rc_certs/\(UUID().uuidString).pdf" // Generate unique filename
            rcCertificateUrl = try await uploadFile(fileData: data, bucketName: docBucket, filePath: filePath, contentType: "application/pdf")
        }
        
        // Upload Pollution Certificate if data is provided
        if let data = pollutionCertData {
            let filePath = "pollution_certs/\(UUID().uuidString).pdf" // Generate unique filename
            pollutionCertificateUrl = try await uploadFile(fileData: data, bucketName: docBucket, filePath: filePath, contentType: "application/pdf")
        }
        
        // Upload Permit if data is provided
        if let data = permitData {
            let filePath = "permits/\(UUID().uuidString).pdf" // Generate unique filename
            permitUrl = try await uploadFile(fileData: data, bucketName: docBucket, filePath: filePath, contentType: "application/pdf")
        }
        
        // Return the struct with all the obtained URLs
        return VehicleDocumentURLs(
            imageUrl: imageUrl,
            rcCertificateUrl: rcCertificateUrl,
            pollutionCertificateUrl: pollutionCertificateUrl,
            permitUrl: permitUrl
        )
    }
    
    /// Uploads raw Data into the given bucket at the specified path,
    /// then returns exactly that `filePath` so you can store it in your DB.
    private func uploadFile(
        fileData: Data,
        bucketName: String,
        filePath: String,
        contentType: String
    ) async throws -> String {
        // 1) Perform the upload against the bucket’s StorageBucketApi
        try await serviceClient.storage
            .from(bucketName)                             // scope to bucket :contentReference[oaicite:0]{index=0}
            .upload(
                path: filePath,
                file: fileData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: contentType,
                    upsert: false
                )
            )                                              // now the file is safely in storage :contentReference[oaicite:1]{index=1}
        
        // 2) Simply return the path string — this never expires
        return filePath
    }
    
    
    func fetchVehicles() async throws -> [Vehicle] {
        // Fetch data from Supabase
        let response = try await client
            .from("vehicle_details")
            .select()
            .execute()
        
        // Log the raw response data
        print("Raw Response: \(String(data: response.data, encoding: .utf8) ?? "Invalid data")")
        
        // Decode response data
        let decoder = JSONDecoder()
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX" // Adjust date format as needed
        decoder.dateDecodingStrategy = .formatted(df)
        
        var vehicles: [Vehicle] = [] // Declare the vehicles array before using it in the task group
        
        do {
            // Decode the response into an array of `Vehicle` objects
            vehicles = try decoder.decode([Vehicle].self, from: response.data)
            print("Successfully decoded \(vehicles.count) vehicles")
        } catch {
            print("Error decoding vehicles: \(error)")
            throw error
        }
        
        // Download files in parallel using a task group
        try await withThrowingTaskGroup(of: (Int, Vehicle).self) { group in
            for idx in vehicles.indices {
                var v = vehicles[idx] // Copy to avoid mutating directly in the loop
                
                group.addTask {
                    // Update the field names to match the Vehicle model
                    async let imageData = v.imageURL != nil ? try? self.downloadFile(bucket: "vehicle_images", path: v.imageURL!) : nil
                    async let rcCertData = v.rcCertificateURL != nil ? try? self.downloadFile(bucket: "rc_certs", path: v.rcCertificateURL!) : nil
                    async let pollutionCertData = v.pollutionCertificateURL != nil ? try? self.downloadFile(bucket: "pollution_certs", path: v.pollutionCertificateURL!) : nil
                    async let permitData = v.permitURL != nil ? try? self.downloadFile(bucket: "permit_certs", path: v.permitURL!) : nil
                    
                    // Use non-throwing awaits for the try? downloads
                    v.imageData = await imageData
                    v.rcCertificateData = await rcCertData
                    v.pollutionCertificateData = await pollutionCertData
                    v.permitData = await permitData
                    
                    return (idx, v)
                }
            }
            
            // Collect the updated vehicles from the task group
            for try await (idx, updatedVehicle) in group {
                vehicles[idx] = updatedVehicle
            }
        }
        
        print("Finished downloading files for vehicles") // Add logging for file download completion
        
        return vehicles
    }
    
    /// Helper to get signed URL and fetch raw Data
    private func downloadFile(bucket: String, path: String) async throws -> Data {
        let url = try await SupabaseManager.shared.serviceClient.storage
            .from(bucket)
            .createSignedURL(path: path, expiresIn: 3600)
        
        print("Downloading file from: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
    
    public func fetchAllEmployees() async throws -> [Employee] {
        print("Fetching all employees (Drivers and Technicians)...")
        do {
            // Fetch concurrently
            async let drivers = fetchDriversInternal()
            async let technicians = fetchTechniciansInternal()
            
            // Await and combine
            let combinedEmployees = try await drivers + technicians
            
            // Sort (optional)
            let sortedEmployees = combinedEmployees.sorted { ($0.name) < ($1.name) }
            print("Successfully fetched and combined \(sortedEmployees.count) employees.")
            return sortedEmployees
        } catch {
            print("Error fetching all employees: \(error)")
            if let postgrestError = error as? PostgrestError {
                print("PostgrestError Details: \(postgrestError.message), Hint: \(postgrestError.hint ?? "N/A"), Code: \(postgrestError.code ?? "N/A")")
            }
            throw error // Re-throw the error
        }
    }
    
    /// Fetches driver details and maps them to the Employee model.
    /// Uses the standard client (Anon Key) assuming RLS is in place.
    private func fetchDriversInternal() async throws -> [Employee] {
        print("Fetching internal driver details...")
        // Use the standard 'client' which uses the Anon Key
        let driverDetails: [DriverDetail] = try await client.database
            .from("driver_profiles") // Ensure this table name is correct
            .select("id, email, name, aadhar_number, driver_license, phone, experience, rating, created_at, status")
            .execute()
            .value // Decode into [DriverDetail]
        
        print("Decoded \(driverDetails.count) driver details.")
        // Map DriverDetail to Employee
        return driverDetails.map { detail in
            Employee(
                id: detail.id,
                name: detail.name ?? "Unnamed Driver",
                status: detail.status, // Default or fetch status if available elsewhere
                role: "Driver",
                email: detail.email, // Assumes email is not null in DB
                experience: detail.experience,
                specialty: nil,
                consignmentId: nil,
                hireDate: detail.created_at,
                location: nil,
                rating: detail.rating,
                earnings: nil,
                totalTrips: nil,
                totalDistance: nil,
                contactNumber: detail.phone,
                licenseNumber: detail.driver_license,
                aadhaarNumber: detail.aadhar_number
            )
        }
    }
    
    /// Fetches technician details and maps them to the Employee model.
    /// Uses the standard client (Anon Key) assuming RLS is in place.
    private func fetchTechniciansInternal() async throws -> [Employee] {
        print("Fetching internal technician details...")
        // Use the standard 'client' which uses the Anon Key
        let technicianDetails: [TechnicianDetail] = try await client.database
            .from("technician_profiles") // Ensure this table name is correct
            .select("id, email, name, experience, specialty, rating, created_at, phone, status")
            .execute()
            .value // Decode into [TechnicianDetail]
        
        print("Decoded \(technicianDetails.count) technician details.")
        // Map TechnicianDetail to Employee
        return technicianDetails.map { detail in
            Employee(
                id: detail.id,
                name: detail.name ?? "Unnamed Technician",
                status: detail.status, // Default or fetch status if available elsewhere
                role: "Technician",
                email: detail.email, // Assumes email is not null in DB
                experience: detail.experience,
                specialty: detail.specialty,
                consignmentId: nil,
                hireDate: detail.created_at,
                location: nil,
                rating: detail.rating,
                earnings: nil,
                totalTrips: nil,
                totalDistance: nil,
                contactNumber: detail.phone,
                licenseNumber: nil,
                aadhaarNumber: nil
            )
        }
    }
    
    
    func fetchConsignments() async throws -> [Consignment] {
        let response = try await serviceClient
            .from("consignments")
            .select()
            .execute()
        
        let data = response.data  // No optional binding needed
        
        if let rawJSONString = String(data: data, encoding: .utf8) {
            print("📦 Raw JSON string:")
            print(rawJSONString)
        } else {
            print("⚠️ Could not decode data as UTF-8")
        }
        
        do {
            let consignments = try decodeConsignments(from: data)
            return consignments
        } catch {
            print("Failed to decode consignments: \(error.localizedDescription)")
            throw error // Rethrow the error if decoding fails
        }
    }
    
    
    func addConsignment(consignment: Consignment) async throws -> Consignment {
        do {
            let response = try await serviceClient
                .from("consignments")
                .insert([consignment])
                .select() // Ensures the inserted row is returned
                .execute()
            
            let data = response.data
            
            if let rawJSONString = String(data: data, encoding: .utf8) {
                print("✅ Inserted Consignment JSON:")
                print(rawJSONString)
            }
            
            let decoder = JSONDecoder()
            
            // 🔁 Custom date decoding strategy
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                // Try multiple formats
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
                if let fallbackDate = formatter.date(from: dateString) {
                    return fallbackDate
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
            }
            
            // Decode the returned consignment
            let inserted = try decoder.decode([Consignment].self, from: data)
            
            guard let createdConsignment = inserted.first else {
                throw NSError(domain: "AddConsignment", code: -1, userInfo: [NSLocalizedDescriptionKey: "No consignment returned"])
            }
            
            return createdConsignment
        } catch {
            print("❌ Failed to add consignment: \(error)")
            throw error
        }
    }
    
    
    func decodeConsignments(from data: Data) throws -> [Consignment] {
        let decoder = JSONDecoder()
        
        // Custom date decoding strategy
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0) // Assuming UTC
            
            // 1. Format without fractional seconds and without timezone
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // 2. Format with fractional seconds and timezone
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // 3. Fallback format without fractional seconds but with timezone
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let fallbackDate = formatter.date(from: dateString) {
                return fallbackDate
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        
        // Decode the JSON data into Consignment array
        do {
            let consignments = try decoder.decode([Consignment].self, from: data)
            return consignments
        } catch {
            print("Failed to decode consignments: \(error)") // Print the full error
            throw error // Rethrow the error if decoding fails
        }
    }
    
    func addTrip(trip: Trip) async throws {
        do {
            // Insert trip into Supabase
            let response = try await serviceClient
                .from("trips")
                .insert([trip])
                .execute() // No need to select the inserted row
            
            let data = response.data
            
            if let rawJSONString = String(data: data, encoding: .utf8) {
                print("🚚 Inserted Trip JSON:")
                print(rawJSONString)
            }
            
            // If the response is successful, print success message
            print("✅ Trip successfully added.")
        } catch {
            print("❌ Failed to add trip: \(error)")
            throw error
        }
    }
    
    func updateVehicleStatus(vehicleId: UUID, newStatus: Vehicle.VehicleStatus) async throws {
        try await serviceClient
            .from("vehicle_details") // Use the correct table name
            .update(["status": newStatus.rawValue])
            .eq("id", value: vehicleId)
            .execute()
    }
    
    
    func updateDriverStatus(driverId: UUID, newStatus: String) async throws {
        try await serviceClient
            .from("driver_profiles")
            .update(["status": newStatus])
            .eq("id", value: driverId)
            .execute()
    }
    
    func updateConsignmentStatus(consignmentId: UUID, newStatus: ConsignmentStatus) async throws {
        try await client
            .from("consignments")
            .update(["status": newStatus.rawValue])
            .eq("internal_id", value: consignmentId)
            .execute()
    }
    
    func updateTripStatus(tripId: UUID, newStatus: String) async throws {
        try await client
            .from("trips") // Assuming your table name is "trips"
            .update(["status": newStatus])
            .eq("trip_id", value: tripId) // Use the correct ID column name
            .execute()
    }
    
    func fetchTrips() async throws -> [Trip] {
        print("Fetching trip details...")
        let trips: [Trip] = try await client
            .from("trips") // Ensure this table name is correct
            .select("*") // Select all columns
            .execute()
            .value // Decode directly into [Trip]
        
        print("Decoded \(trips.count) trips.")
        return trips
    }
    
    // You might also want a function to fetch a single trip by ID:
    func fetchTrip(byDriverID driverId: UUID) async throws -> Trip? {
        print("Fetching ongoing trip by driver ID: \(driverId)...")
        let response: [Trip] = try await client
            .from("trips")
            .select("*")
            .eq("driver_id", value: driverId)
            .eq("status", value: "ongoing") // Only fetch trips with status "ongoing"
            .limit(1) // Expect at most one ongoing trip per driver
            .execute()
            .value
        
        if let trip = response.first {
            print("Successfully fetched ongoing trip for driver ID: \(driverId)")
            return trip
        } else {
            print("No ongoing trip found for driver ID: \(driverId)")
            return nil
        }
    }
    
    func fetchVehicle(byID vehicleId: UUID) async throws -> Vehicle? {
        print("Fetching vehicle by ID: \(vehicleId)...")
        let response: [Vehicle] = try await client
            .from("vehicle_details") // Ensure this table name is correct
            .select("*")
            .eq("id", value: vehicleId)
            .limit(1)
            .execute()
            .value
        
        if let vehicle = response.first {
            print("Successfully fetched vehicle with ID: \(vehicleId)")
            return vehicle
        } else {
            print("No vehicle found with ID: \(vehicleId)")
            return nil
        }
    }
    
    func fetchConsignment(byID consignmentId: UUID) async throws -> Consignment? {
        print("Fetching consignment by ID: \(consignmentId)...")
        let response = try await client
            .from("consignments")
            .select("*")
            .eq("internal_id", value: consignmentId)
            .execute()
        
        print("Raw JSON Response:", String(data: response.data ?? Data(), encoding: .utf8) ?? "Empty Data") // Print raw JSON
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss" // Corrected format for pickup_date and delivery_date
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let dateFormatterWithMilliseconds = DateFormatter()
        dateFormatterWithMilliseconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ" // Corrected format for created_at
        dateFormatterWithMilliseconds.calendar = Calendar(identifier: .iso8601)
        dateFormatterWithMilliseconds.timeZone = TimeZone(secondsFromGMT: 0)
        
        decoder.dateDecodingStrategy = .custom({ decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            if let date = dateFormatterWithMilliseconds.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        })
        
        do {
            let consignments = try decoder.decode([Consignment].self, from: response.data ?? Data())
            print("Decoded Response:", consignments) // See if decoding worked
            return consignments.first
        } catch {
            print("Decoding Error:", error)
            return nil
        }
    }
    
    func insertTripRevenue(revenueData: TripRevenue) async throws {
            try await client
                .from("trip_revenue")
                .insert(revenueData) // Remove the 'object:' label
                .execute()
        }
    
    func fetchTripRevenues() async throws -> [TripRevenue] {
            let response = try await client
                .from("trip_revenue")
                .select("*")
                .execute()
            
            // Use the date decoding strategy from your fetchConsignment function
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            dateFormatter.calendar = Calendar(identifier: .iso8601)
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let dateFormatterWithMilliseconds = DateFormatter()
            dateFormatterWithMilliseconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            dateFormatterWithMilliseconds.calendar = Calendar(identifier: .iso8601)
            dateFormatterWithMilliseconds.timeZone = TimeZone(secondsFromGMT: 0)
            
            decoder.dateDecodingStrategy = .custom({ decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
                if let date = dateFormatterWithMilliseconds.date(from: dateString) {
                    return date
                }
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
            })
            
            return try decoder.decode([TripRevenue].self, from: response.data ?? Data())
        }
    
    func insertIssueReport(report: IssueReport) async throws -> IssueReport {
        print("SupabaseManager: Inserting issue report...")
        let response: [IssueReport] = try await client
            .from("issue_reports")
            .insert(report)
            .select("*") // Explicitly request all columns of the inserted row(s)
            .execute()
            .value

        guard let insertedReport = response.first else {
            print("SupabaseManager: Error - No report returned after insertion.")
            throw NSError(domain: "SupabaseManagerError", code: 201, userInfo: [NSLocalizedDescriptionKey: "No report data returned after insertion."])
        }

        print("SupabaseManager: Issue report inserted successfully with ID: \(insertedReport.id)")
        return insertedReport
    }
    
    
    func uploadIssuePhoto(issueId: UUID, image: UIImage, index: Int) async throws -> String {
        print("SupabaseManager: Preparing to upload photo \(index + 1) for issue \(issueId)...")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("SupabaseManager: Failed to get JPEG data for photo \(index + 1)")
            throw NSError(domain: "SupabaseManagerError", code: 101, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data."])
        }

        let bucketName = "issue-photos"
        let fileName = "photo_\(index + 1).jpg"
        let filePath = "\(issueId.uuidString.lowercased())/\(fileName)"

        print("SupabaseManager: Uploading photo \(index + 1) to path: \(bucketName)/\(filePath)")

        let uploadResult = try await client.storage
            .from(bucketName)
            .upload(path: filePath, file: imageData, options: FileOptions(contentType: "image/jpeg")) // Pass imageData and options

        print("SupabaseManager: Photo \(index + 1) uploaded successfully to path: \(uploadResult.path)")
        return uploadResult.path
    }
    
    func fetchIssueReports() async throws -> [IssueReport] {
            let response = try await client
                .from("issue_reports")
                .select()
                .execute()
            
            // Use the helper function to decode the data
            return try decodeIssueReports(data: response.data ?? Data())
        }
        
        // Helper function to decode the JSON data into IssueReport objects
        private func decodeIssueReports(data: Data) throws -> [IssueReport] {
            let decoder = JSONDecoder()
            // Use custom date decoding strategy
            decoder.dateDecodingStrategy = .custom({ decoder -> Date in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                dateFormatter.calendar = Calendar(identifier: .iso8601)
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                let dateFormatterWithMilliseconds = DateFormatter()
                dateFormatterWithMilliseconds.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
                dateFormatterWithMilliseconds.calendar = Calendar(identifier: .iso8601)
                dateFormatterWithMilliseconds.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let date = dateFormatter.date(from: dateString) {
                    return date
                } else if let date = dateFormatterWithMilliseconds.date(from: dateString) {
                    return date
                } else {
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
                }
            })
            return try decoder.decode([IssueReport].self, from: data)
        }
    
        // Function to fetch image URLs for a specific issue report ID from Storage
        func fetchImageURLs(issueReportId: String) async throws -> [URL] {
            // List files in the folder named after the issueReportId
            let data = try await client.storage.from("issue-photos").list(path: issueReportId)
            
           
            
            // Decode the response to get the file names.  The actual structure might need adjusting.
            struct FileInfo: Codable {
                let name: String
            }
            
            // Generate the full URL for each image.
            return try data.compactMap { file in
                try client.storage.from("issue-photos").getPublicURL(path: "\(issueReportId)/\(file.name)", download: false)
            }
        }
        
        
        
    func updateIssueReportStatus(issueReportId: UUID, newStatus: String) async throws {
        try await client
            .from("issue_reports") // Assuming your table name is "trips"
            .update(["status": newStatus])
            .eq("id", value: issueReportId) // Use the correct ID column name
            .execute()
    }
}

struct NewVehicle: Encodable {
    let license_plate_no: String
    let type: String?
    let model: String?
    let fastag_no: String?
    let image_url: String?
    let rc_certificate_url: String?
    let pollution_certificate_url: String?
    let permit_url: String?
}

// Define a struct for the success response from the Edge Function
struct CreateVehicleSuccessResponse: Decodable {
    let message: String
    // You might want to include the returned vehicle data here if the function returns it
    // let vehicle: Vehicle? // Assuming you have a Vehicle struct
}

// Define a struct for the error response from the Edge Function
struct CreateVehicleErrorResponse: Decodable {
    let error: String
}

struct VehicleDocumentURLs {
    let imageUrl: String?
    let rcCertificateUrl: String?
    let pollutionCertificateUrl: String?
    let permitUrl: String?
}

struct DriverDetail: Decodable, Identifiable {
    let id: UUID
    let email: String
    let name: String?
    let aadhar_number: String?
    let driver_license: String?
    let phone: String?
    let experience: Int?
    let rating: Double?
    let created_at: Date?
    let status: String // <- Add this
}


/// Intermediate struct for decoding `technician_details` table rows.
struct TechnicianDetail: Decodable, Identifiable {
    let id: UUID
    let email: String
    let name: String?
    let experience: Int?
    let specialty: String?
    let rating: Double?
    let created_at: Date?
    let phone: String?
    let status: String // <- Add this
}

