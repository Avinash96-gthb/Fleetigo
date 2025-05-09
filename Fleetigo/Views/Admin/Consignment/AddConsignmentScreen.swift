import SwiftUI

struct AddConsignmentScreen: View {
    @EnvironmentObject var store: ConsignmentStore
    @ObservedObject var vehicleViewModel: VehicleViewModel
    @ObservedObject var dataService: DataService

    @Environment(\.dismiss) var dismiss
    @State private var consignmentID = ""
    @State private var description = ""
    @State private var weight = ""
    @State private var dimensions = ""
    @State private var selectedType: ConsignmentType? = nil
    @State private var selectedVehicleType: VehicleType? = nil
    @State private var pickupLocation = ""
    @State private var dropLocation = ""
    @State private var pickupDate = Date()
    @State private var pickupTime = Date()
    @State private var deliveryDate = Date()
    @State private var senderPhone = ""
    @State private var recipientName = ""
    @State private var recipientPhone = ""
    @State private var instructions = ""
    @State private var selectedVehicle: Vehicle? = nil
    @State private var selectedDriver: Employee? = nil

    @State private var weightError: String?
    @State private var dimensionsError: String?
    @State private var senderPhoneError: String?
    @State private var recipientPhoneError: String?
    @State private var descriptionError: String? = nil
    @State private var pickupLocationError: String? = nil
    @State private var dropLocationError: String? = nil
    @State private var pickupDateError: String? = nil
    @State private var deliveryDateError: String? = nil
    @State private var recipientNameError: String? = nil
    @State private var instructionsError: String? = nil

    @EnvironmentObject var tabRouter: TabRouter

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    inputFieldsSection
                    vehicleAndDriverSection
                    tripSection
                    routeButton
                    datePickersSection
                    contactInformationSection
                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
            }
            .onChange(of: description) { newValue in
                descriptionError = newValue.isEmpty ? "Description is required" : nil
            }
            .onChange(of: weight) { newValue in
                if newValue.isEmpty {
                    weightError = "Weight is required"
                } else if let weightValue = Double(newValue), weightValue > 0 {
                    weightError = nil
                } else {
                    weightError = "Weight must be a positive number"
                }
            }
            .onChange(of: dimensions) { newValue in
                let cleaned = newValue.replacingOccurrences(of: "x", with: "×")
                if dimensions != cleaned {
                    dimensions = cleaned
                }
                if cleaned.isEmpty {
                    dimensionsError = "Dimensions are required"
                } else {
                    let components = cleaned.components(separatedBy: "×")
                    if components.count != 3 || components.contains(where: { Double($0) == nil || Double($0)! <= 0 }) {
                        dimensionsError = "Format as L×B×H with positive numbers"
                    } else {
                        dimensionsError = nil
                    }
                }
            }
            .onChange(of: pickupLocation) { newValue in
                pickupLocationError = newValue.isEmpty ? "Pickup location is required" : nil
            }
            .onChange(of: dropLocation) { newValue in
                dropLocationError = newValue.isEmpty ? "Drop location is required" : nil
            }
            .onChange(of: pickupDate) { _ in validateDates() }
            .onChange(of: pickupTime) { _ in validateDates() }
            .onChange(of: deliveryDate) { _ in validateDates() }
            .onChange(of: senderPhone) { newValue in
                if newValue.isEmpty {
                    senderPhoneError = "Sender phone is required"
                } else if !isValidPhoneNumber(newValue) {
                    senderPhoneError = "Must be exactly 10 digits"
                } else {
                    senderPhoneError = nil
                }
            }
            .onChange(of: recipientName) { newValue in
                if newValue.isEmpty {
                    recipientNameError = "Recipient name is required"
                } else if !isValidName(newValue) {
                    recipientNameError = "Name must contain only letters and spaces"
                } else {
                    recipientNameError = nil
                }
            }
            .onChange(of: recipientPhone) { newValue in
                if newValue.isEmpty {
                    recipientPhoneError = "Recipient phone is required"
                } else if !isValidPhoneNumber(newValue) {
                    recipientPhoneError = "Must be exactly 10 digits"
                } else {
                    recipientPhoneError = nil
                }
            }
            .onChange(of: instructions) { newValue in
                if !newValue.isEmpty && !isAlphanumeric(newValue) {
                    instructionsError = "Instructions must be alphanumeric"
                } else {
                    instructionsError = nil
                }
            }

            saveButton
        }
        .navigationTitle("Add Consignment")
        .tint(.red)
        .onAppear {
            consignmentID = generateUniqueID()
            print("Available Drivers count on appear: \(dataService.employees.filter { $0.role == "Driver" }.count)")
            print("Available Vehicles count on appear: \(vehicleViewModel.vehicles.filter { $0.status == .available }.count)")
            print("drivers are: \(dataService.employees.filter { $0.role == "Driver" && $0.status == "Available" })")
            print("drivers are: \(dataService.availableDrivers)")
        }
    }

    private var inputFieldsSection: some View {
        VStack(spacing: 16) {
            CustomTextField(placeholder: "Consignment ID", text: .constant(consignmentID), icon: "doc.text")
                .disabled(true)

            CustomTextField(placeholder: "Description", text: $description, icon: "note.text", errorMessage: descriptionError)

            CustomTextField(placeholder: "Weight (kg)", text: $weight, icon: "scalemass", keyboardType: .decimalPad, errorMessage: weightError)

            CustomTextField(placeholder: "Dimensions (L×B×H)", text: $dimensions, icon: "ruler", errorMessage: dimensionsError)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shippingbox")
                        .foregroundColor(.gray)
                    Text(selectedType?.rawValue.capitalized ?? "Consignment Type")
                        .foregroundColor(selectedType == nil ? .gray.opacity(0.6) : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    Menu {
                        ForEach(ConsignmentType.allCases, id: \.self) { type in
                            Button(type.rawValue.capitalized) {
                                selectedType = type
                            }
                        }
                    } label: {
                        Color.clear
                    }
                )
                if selectedType == nil {
                    Text("Please select a type")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "car")
                        .foregroundColor(.gray)
                    Text(selectedVehicleType?.rawValue ?? "Vehicle Type")
                        .foregroundColor(selectedVehicleType == nil ? .gray.opacity(0.6) : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    Menu {
                        ForEach(VehicleType.allCases, id: \.self) { type in
                            Button(type.rawValue) {
                                selectedVehicleType = type
                            }
                        }
                    } label: {
                        Color.clear
                    }
                )
                if selectedVehicleType == nil {
                    Text("Please select a vehicle type")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var vehicleAndDriverSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vehicle and Driver")
                .font(.headline)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "truck.box.fill")
                        .foregroundColor(.gray)
                    Text(selectedVehicle?.model ?? "Select Vehicle")
                        .foregroundColor(selectedVehicle == nil ? .gray.opacity(0.6) : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    Menu {
                        ForEach(vehicleViewModel.vehicles.filter {
                            $0.status == .available && (selectedVehicleType == nil || $0.type == selectedVehicleType?.rawValue)
                        }, id: \.id) { vehicle in
                            Button(vehicle.model) {
                                selectedVehicle = vehicle
                            }
                        }
                    } label: {
                        Color.clear
                    }
                )
                if selectedVehicle == nil {
                    Text("Please select a vehicle")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "figure.seated.seatbelt")
                        .foregroundColor(.gray)
                    Text(selectedDriver?.name ?? "Select Driver")
                        .foregroundColor(selectedDriver == nil ? .gray.opacity(0.6) : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.systemGray6))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    Menu {
                        ForEach(dataService.employees.filter { $0.role == "Driver" && $0.status == "Available" }, id: \.id) { driver in
                            Button(driver.name) {
                                selectedDriver = driver
                            }
                        }
                    } label: {
                        Color.clear
                    }
                )
                if selectedDriver == nil {
                    Text("Please select a driver")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.top, 16)
    }

    private var tripSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(Color.green).frame(width: 15, height: 15)
                    Circle().fill(Color.white).frame(width: 7, height: 7)
                }
                .frame(width: 20)
                TextField("Pickup location", text: $pickupLocation)
                    .font(.subheadline)
                    .padding(.vertical, 6)
                    .disabled(true)
                    .overlay(
                        NavigationLink(destination: MapLocationPicker(selectedLocation: $pickupLocation)) {
                            Color.clear
                        }
                    )
            }
            if let error = pickupLocationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 28)
            }

            HStack(spacing: 0) {
                Spacer().frame(width: 28)
                ZStack {
                    Rectangle()
                        .fill(Color(hex: "#DADADA"))
                        .frame(height: 0.5)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 4)
            }

            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(Color.red).frame(width: 15, height: 15)
                    Circle().fill(Color.white).frame(width: 7, height: 7)
                }
                .frame(width: 20)
                TextField("Drop location", text: $dropLocation)
                    .font(.subheadline)
                    .padding(.vertical, 6)
                    .disabled(true)
                    .overlay(
                        NavigationLink(destination: MapLocationPicker(selectedLocation: $dropLocation)) {
                            Color.clear
                        }
                    )
            }
            if let error = dropLocationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 28)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemGray6))
        )
    }

    var routeButton: some View {
        HStack {
            NavigationLink(destination: RouteMapView(pickupAddress: $pickupLocation, dropAddress: $dropLocation)) {
                HStack(spacing: 6) {
                    Image(systemName: "map")
                        .font(.system(size: 13))
                    Text("Show Route")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#DADADA"), lineWidth: 0.5)
                )
            }
            .disabled(pickupLocation.isEmpty || dropLocation.isEmpty)
            Spacer()
        }
        .padding(.leading, 8)
    }

    private var datePickersSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.green)
                    Text("Pickup Details")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                DatePicker("Date", selection: $pickupDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                DatePicker("Time", selection: $pickupTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                if let error = pickupDateError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )

            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "calendar.badge.checkmark")
                        .foregroundColor(.red)
                    Text("Delivery Date")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                DatePicker("Delivery Date", selection: $deliveryDate, in: pickupDate..., displayedComponents: .date)
                    .datePickerStyle(.compact)
                if let error = deliveryDateError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .padding(.vertical, 8)
    }

    private var contactInformationSection: some View {
        VStack(spacing: 16) {
            Text("Contact Information")
                .font(.headline)
                .padding(.bottom, 4)

            CustomTextField(placeholder: "Sender Phone", text: $senderPhone, icon: "phone", keyboardType: .phonePad, errorMessage: senderPhoneError)

            CustomTextField(placeholder: "Recipient Name", text: $recipientName, icon: "person", errorMessage: recipientNameError)

            CustomTextField(placeholder: "Recipient Phone", text: $recipientPhone, icon: "phone.and.waveform.fill", keyboardType: .phonePad, errorMessage: recipientPhoneError)

            CustomTextEditor(placeholder: "Special Instructions", text: $instructions, icon: "text.bubble", height: 100, errorMessage: instructionsError)
        }
        .padding(.vertical, 8)
    }

    private var saveButton: some View {
        Button("Save Consignment") {
            Task {
                if validateFields() {
                    await saveConsignment()
                    dismiss()
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal)
        .padding(.bottom)
        .disabled(consignmentID.isEmpty || selectedType == nil || selectedVehicleType == nil || selectedVehicle == nil || selectedDriver == nil)
    }

    private func validateFields() -> Bool {
        var isValid = true

        if description.isEmpty {
            descriptionError = "Description is required"
            isValid = false
        }
        if weight.isEmpty || (Double(weight) ?? 0) <= 0 {
            weightError = weight.isEmpty ? "Weight is required" : "Weight must be a positive number"
            isValid = false
        }
        if dimensions.isEmpty || dimensions.components(separatedBy: "×").count != 3 || dimensions.components(separatedBy: "×").contains(where: { Double($0) == nil || Double($0)! <= 0 }) {
            dimensionsError = dimensions.isEmpty ? "Dimensions are required" : "Format as L×B×H with positive numbers"
            isValid = false
        }
        if pickupLocation.isEmpty {
            pickupLocationError = "Pickup location is required"
            isValid = false
        }
        if dropLocation.isEmpty {
            dropLocationError = "Drop location is required"
            isValid = false
        }
        let pickupDateTime = combineDateWithTime(date: pickupDate, time: pickupTime)
        if pickupDateTime < Date() {
            pickupDateError = "Pickup date and time must be in the future"
            isValid = false
        }
        if deliveryDate < pickupDate {
            deliveryDateError = "Delivery date must be on or after pickup date"
            isValid = false
        }
        if senderPhone.isEmpty || !isValidPhoneNumber(senderPhone) {
            senderPhoneError = senderPhone.isEmpty ? "Sender phone is required" : "Must be exactly 10 digits"
            isValid = false
        }
        if recipientName.isEmpty || !isValidName(recipientName) {
            recipientNameError = recipientName.isEmpty ? "Recipient name is required" : "Name must contain only letters and spaces"
            isValid = false
        }
        if recipientPhone.isEmpty || !isValidPhoneNumber(recipientPhone) {
            recipientPhoneError = recipientPhone.isEmpty ? "Recipient phone is required" : "Must be exactly 10 digits"
            isValid = false
        }
        if !instructions.isEmpty && !isAlphanumeric(instructions) {
            instructionsError = "Instructions must be alphanumeric"
            isValid = false
        }
        if selectedType == nil || selectedVehicleType == nil || selectedVehicle == nil || selectedDriver == nil {
            isValid = false
        }

        return isValid
    }

    private func isValidPhoneNumber(_ number: String) -> Bool {
        let regex = "^\\d{10}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: number)
    }

    private func isValidName(_ name: String) -> Bool {
        let regex = "^[a-zA-Z ]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: name)
    }

    private func isAlphanumeric(_ string: String) -> Bool {
        let regex = "^[a-zA-Z0-9 ]+$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: string)
    }

    private func combineDateWithTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        var combinedComponents = dateComponents
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        return calendar.date(from: combinedComponents) ?? Date()
    }

    private func validateDates() {
        let pickupDateTime = combineDateWithTime(date: pickupDate, time: pickupTime)
        if pickupDateTime < Date() {
            pickupDateError = "Pickup date and time must be in the future"
        } else {
            pickupDateError = nil
        }
        if deliveryDate < pickupDate {
            deliveryDateError = "Delivery date must be on or after pickup date"
        } else {
            deliveryDateError = nil
        }
    }

    private func saveConsignment() async {
        let newConsignment = Consignment(
            internal_id: nil,
            id: consignmentID,
            type: selectedType ?? .standard,
            vehichle_type: selectedVehicleType ?? .mcv,
            status: .ongoing,
            description: description,
            weight: weight,
            dimensions: dimensions,
            pickup_location: pickupLocation,
            drop_location: dropLocation,
            pickup_date: pickupDate,
            delivery_date: deliveryDate,
            sender_phone: senderPhone,
            recipient_name: recipientName,
            recipient_phone: recipientPhone,
            instructions: instructions,
            created_at: nil
        )
        await store.createConsignmentWithTrip(consignment: newConsignment, driver: selectedDriver!, vehicle: selectedVehicle!)
    }

    private func generateUniqueID() -> String {
        var newID: String
        repeat {
            let randomNumber = Int.random(in: 100000...999999)
            newID = "FLT\(randomNumber)"
        } while store.consignments.contains { $0.id == newID }
        return newID
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                        .frame(width: 20)
                }
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .foregroundColor(.primary)
                    .font(.system(size: 16, weight: .regular))
                    .keyboardType(keyboardType)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

struct CustomTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var height: CGFloat = 100
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.gray)
                        .frame(width: 20)
                        .padding(.top, 8)
                }
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .frame(minHeight: height)
                        .foregroundColor(.primary)
                        .font(.system(size: 16, weight: .regular))
                        .scrollContentBackground(.hidden)
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(.gray.opacity(0.6))
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemGray6))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

struct ConsignmentRow: View {
    let consignment: Consignment
    
    private var iconColor: Color {
        switch consignment.type {
        case .priority: return .red
        case .medium: return .yellow
        case .standard: return .green
        }
    }
    
    private var iconSymbol: String {
        switch consignment.type {
        case .priority: return "chevron.up.2"
        case .medium: return "equal"
        case .standard: return "chevron.down.2"
        }
    }
    
    var body: some View {
        NavigationLink(destination: ConsignmentDetailView(consignment: consignment)) {
            HStack {
                Image(systemName: iconSymbol)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(iconColor)
                VStack(alignment: .leading) {
                    Text(consignment.id).font(.headline)
                    Text("Type: \(consignment.type.rawValue.capitalized)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct NeumorphicButtonStyle: ButtonStyle {
    var backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(backgroundColor == .red ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(backgroundColor)
                    .shadow(
                        color: configuration.isPressed ? Color.clear : Color.black.opacity(0.05),
                        radius: 2, x: 0, y: 1
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "#FE6767"))
            .foregroundColor(.white)
            .cornerRadius(12)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 80, height: 50)
            .background(Color(hex: "#FF6767").opacity(0.3))
            .foregroundColor(Color(hex: "#FF6767"))
            .cornerRadius(12)
            .contentShape(Rectangle())
    }
}
