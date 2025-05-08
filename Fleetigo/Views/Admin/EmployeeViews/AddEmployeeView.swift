//
//
//import SwiftUI
//
//struct AddEmployeeView: View {
//    @Environment(\.dismiss) var dismiss
//    @State private var name = ""
//    @State private var status = "Available"
//    @State private var role = "Driver"
//    
//    var onAdd: (Employee) -> Void
//    
//    let statuses = ["Available", "On-Duty", "Not Available"]
//    let roles = ["Driver", "Technician"]
//    
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section(header: Text("Name")) {
//                    TextField("Enter name", text: $name)
//                }
//                
//                Section(header: Text("Status")) {
//                    Picker("Status", selection: $status) {
//                        ForEach(statuses, id: \.self) { status in
//                            Text(status)
//                        }
//                    }
//                    .pickerStyle(.segmented)
//                }
//                
//                Section(header: Text("Role")) {
//                    Picker("Role", selection: $role) {
//                        ForEach(roles, id: \.self) { role in
//                            Text(role)
//                        }
//                    }
//                    .pickerStyle(.segmented)
//                }
//            }
//            .navigationTitle("Add Employee")
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Add") {
//                        let newEmployee = Employee(name: name, status: status, role: role)
//                        onAdd(newEmployee)
//                        dismiss()
//                    }
//                    .disabled(name.isEmpty)
//                }
//                
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel") {
//                        dismiss()
//                    }
//                }
//            }
//        }
//    }
//}
