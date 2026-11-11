
import SwiftUI

struct AppointmentDetailView: View {

    @AppStorage("savedPlumbingAppointments")
    private var appointmentsData: Data = Data()

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

                    Text(currentAppointment.status)
                        .font(.subheadline)
                        .foregroundStyle(
                            statusColor(currentAppointment.status)
                        )
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
