
import SwiftUI

struct AppointmentDetailView: View {

    @AppStorage("savedPlumbingAppointments")
    private var appointmentsData: Data = Data()
    @AppStorage("savedPlumbingCustomers")
    private var customersData: Data = Data()

    private var linkedCustomer: PlumbingCustomer? {
        guard let id = currentAppointment.customerID,
              let customers = try? JSONDecoder().decode(
                  [PlumbingCustomer].self,
                  from: customersData
              )
        else {
            return nil
        }

        return customers.first { $0.id == id }
    }


    @State private var currentAppointment: PlumbingAppointment
    @State private var showingEdit = false

    init(appointment: PlumbingAppointment) {
        _currentAppointment = State(initialValue: appointment)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                VStack(alignment: .leading, spacing: 8) {
                    Text(currentAppointment.service)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    JobStatusMenu(appointmentID: currentAppointment.id)
                }

                Divider()

                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Customer")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(currentAppointment.customerName)
                            .font(.headline)
                    }
                } icon: {
                    Image(systemName: "person.fill")
                }

                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Appointment Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(
                            currentAppointment.date,
                            format: .dateTime
                                .weekday(.wide)
                                .month(.wide)
                                .day()
                                .year()
                        )

                        Text(
                            currentAppointment.date,
                            format: .dateTime.hour().minute()
                        )
                    }
                } icon: {
                    Image(systemName: "calendar")
                }

                Divider()
                
                if let customer = linkedCustomer {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact Customer")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 12) {
                            let phone = PhoneNumberFormatter.dialable(
                                customer.phone
                            )

                            if !phone.isEmpty,
                               let callURL = URL(string: "tel:\(phone)"),
                               let textURL = URL(string: "sms:\(phone)") {

                                Link(destination: callURL) {
                                    contactButton(
                                        "Call",
                                        icon: "phone.fill",
                                        color: .green
                                    )
                                }

                                Link(destination: textURL) {
                                    contactButton(
                                        "Text",
                                        icon: "message.fill",
                                        color: .blue
                                    )
                                }
                            }

                            if !customer.email.isEmpty,
                               let encoded = customer.email.addingPercentEncoding(
                                   withAllowedCharacters: .urlPathAllowed
                               ),
                               let emailURL = URL(string: "mailto:\(encoded)") {

                                Link(destination: emailURL) {
                                    contactButton(
                                        "Email",
                                        icon: "envelope.fill",
                                        color: .orange
                                    )
                                }
                            }
                        }
                    }
                }


                if !currentAppointment.address.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Job Location")
                            .font(.title2)
                            .fontWeight(.bold)

                        AppointmentMapView(
                            address: currentAppointment.address
                        )
                    }

                    Divider()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Job Notes")
                        .font(.title2)
                        .fontWeight(.bold)

                    if currentAppointment.notes.isEmpty {
                        Text("No notes added.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text(currentAppointment.notes)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEdit = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            EditAppointmentView(
                appointment: currentAppointment
            ) { updated in
                saveUpdatedAppointment(updated)
            }
        }
        .onChange(of: appointmentsData) { _, newData in
            guard let appointments = try? JSONDecoder().decode(
                [PlumbingAppointment].self,
                from: newData
            ),
            let updated = appointments.first(where: {
                $0.id == currentAppointment.id
            }) else {
                return
            }

            currentAppointment = updated
        }

    }
    
    private func contactButton(
        _ title: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func saveUpdatedAppointment(
        _ updated: PlumbingAppointment
    ) {
        var savedAppointments =
            (try? JSONDecoder().decode(
                [PlumbingAppointment].self,
                from: appointmentsData
            )) ?? []

        guard let index = savedAppointments.firstIndex(
            where: { $0.id == updated.id }
        ) else {
            return
        }

        savedAppointments[index] = updated

        if let data = try? JSONEncoder().encode(
            savedAppointments
        ) {
            appointmentsData = data
            currentAppointment = updated
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "Completed":
            return .green
        case "In Progress":
            return .blue
        case "Cancelled":
            return .red
        default:
            return .secondary
        }
    }
}
