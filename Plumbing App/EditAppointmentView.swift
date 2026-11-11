
import SwiftUI

struct EditAppointmentView: View {

    @Environment(\.dismiss) private var dismiss

    let appointment: PlumbingAppointment
    let onSave: (PlumbingAppointment) -> Void

    @State private var customerName: String
    @State private var service: String
    @State private var address: String
    @State private var date: Date
    @State private var notes: String
    @State private var status: String

    @State private var showingAddressSearch = false

    private let statuses = [
        "Scheduled",
        "In Progress",
        "Completed",
        "Cancelled"
    ]

    init(
        appointment: PlumbingAppointment,
        onSave: @escaping (PlumbingAppointment) -> Void
    ) {
        self.appointment = appointment
        self.onSave = onSave

        _customerName = State(initialValue: appointment.customerName)
        _service = State(initialValue: appointment.service)
        _address = State(initialValue: appointment.address)
        _date = State(initialValue: appointment.date)
        _notes = State(initialValue: appointment.notes)
        _status = State(initialValue: appointment.status)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Customer Information") {
                    TextField(
                        "Customer Name",
                        text: $customerName
                    )

                    TextField(
                        "Service",
                        text: $service
                    )

                    Button {
                        showingAddressSearch = true
                    } label: {
                        Label(
                            address.isEmpty
                                ? "Search Job Address"
                                : address,
                            systemImage: "mappin.circle"
                        )
                    }
                }

                Section("Appointment Schedule") {
                    DatePicker(
                        "Date & Time",
                        selection: $date
                    )
                }

                Section("Job Status") {
                    Picker("Status", selection: $status) {
                        ForEach(statuses, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                }

                Section("Job Notes") {
                    TextField(
                        "Notes",
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(
                        customerName.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty ||
                        service.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty
                    )
                }
            }
            .sheet(isPresented: $showingAddressSearch) {
                AddressSearchView(address: $address)
            }
        }
    }

    private func saveChanges() {
        var updated = appointment

        updated.customerName = customerName
        updated.service = service
        updated.address = address
        updated.date = date
        updated.notes = notes
        updated.status = status

        onSave(updated)
        dismiss()
    }
}
