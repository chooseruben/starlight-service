
import SwiftUI

struct PlumbingAppointment: Identifiable, Codable, Equatable {
    var id = UUID()
    var customerName: String
    var service: String
    var address: String
    var date: Date
    var notes: String
    var status: String = "Scheduled"
    var customerID: UUID? = nil
}

struct CalendarView: View {

    @State private var appointments: [PlumbingAppointment] =
        Self.loadAppointments()

    @State private var selectedDate = Date()
    @State private var activeSheet: AppointmentSheet?

    private enum AppointmentSheet: Identifiable {
        case add
        case edit(PlumbingAppointment)

        var id: String {
            switch self {
            case .add:
                return "add"
            case .edit(let appointment):
                return appointment.id.uuidString
            }
        }
    }


    @State private var customerName = ""
    @State private var selectedCustomerID: UUID?
    @State private var service = ""
    @State private var address = ""
    @State private var showingAddressSearch = false
    @State private var showingCustomerPicker = false
    @State private var appointmentDate = Date()
    @State private var notes = ""

    private static let storageKey = "savedPlumbingAppointments"

    private var selectedAppointments: [PlumbingAppointment] {
        appointments
            .filter {
                Calendar.current.isDate(
                    $0.date,
                    inSameDayAs: selectedDate
                )
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    
                    JobMonthCalendarView(
                        selectedDate: $selectedDate,
                        appointments: appointments
                    )


                    HStack {
                        Text("Appointments")
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        Text("\(selectedAppointments.count) Jobs")
                            .foregroundStyle(.secondary)
                    }

                    if selectedAppointments.isEmpty {
                        ContentUnavailableView(
                            "No Appointments",
                            systemImage: "calendar.badge.clock",
                            description: Text(
                                "No jobs scheduled for this date."
                            )
                        )
                    } else {
                        ForEach(selectedAppointments) { appointment in
                            appointmentCard(appointment)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appointmentDate = selectedDate
                        activeSheet = .add
                    } label: {
                        Image(systemName: "plus")
                    }

                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .add:
                    addAppointmentSheet

                case .edit(let appointment):
                    EditAppointmentView(appointment: appointment) { updated in
                        if let index = appointments.firstIndex(
                            where: { $0.id == updated.id }
                        ) {
                            appointments[index] = updated
                            selectedDate = updated.date
                        }
                    }
                }
            }

            .onChange(of: appointments) { _, updated in
                saveAppointments(updated)
            }
            
            .onAppear {
                appointments = Self.loadAppointments()
            }

        }
    }

    private func appointmentCard(
        _ appointment: PlumbingAppointment
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(appointment.customerName)
                    .font(.headline)

                Spacer()

                Text(appointment.date, format: .dateTime.hour().minute())
                    .foregroundStyle(.blue)
            }

            Label(appointment.service, systemImage: "wrench")

            
            if !appointment.address.isEmpty {
                AppointmentMapView(address: appointment.address)
            }


            if !appointment.notes.isEmpty {
                Text(appointment.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            
            HStack {
                Text(appointment.status)
                    .font(.caption)
                    .foregroundStyle(.green)

                Spacer()

                Button {
                    activeSheet = .edit(appointment)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.borderless)


                Button(role: .destructive) {

                    appointments.removeAll {
                        $0.id == appointment.id
                    }
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var addAppointmentSheet: some View {
        NavigationStack {
            Form {
                Section("Customer Information") {
                    
                    Button {
                        showingCustomerPicker = true
                    } label: {
                        Label(
                            "Select Existing Customer",
                            systemImage: "person.crop.circle.badge.checkmark"
                        )
                    }
                    
                    TextField("Customer Name", text: $customerName)
                        .onChange(of: customerName) { _, newName in
                            if let selectedCustomerID {
                                let saved = UserDefaults.standard.data(
                                    forKey: "savedPlumbingCustomers"
                                ) ?? Data()

                                let customers = (try? JSONDecoder().decode(
                                    [PlumbingCustomer].self,
                                    from: saved
                                )) ?? []

                                if let selected = customers.first(
                                    where: { $0.id == selectedCustomerID }
                                ), selected.name != newName {
                                    self.selectedCustomerID = nil
                                }
                            }
                        }

                    TextField("Service Type", text: $service)
                    Button {
                        showingAddressSearch = true
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle.fill")

                            Text(address.isEmpty
                                 ? "Search Job Address"
                                 : address)
                                .multilineTextAlignment(.leading)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }

                }

                Section("Schedule") {
                    DatePicker(
                        "Date & Time",
                        selection: $appointmentDate
                    )
                }

                Section("Additional Notes") {
                    TextField(
                        "Notes about the job",
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        activeSheet = nil
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addAppointment()
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
            
            .sheet(isPresented: $showingCustomerPicker) {
                CustomerPickerView { customer in
                    selectedCustomerID = customer.id
                    customerName = customer.name
                    address = customer.address
                }
            }

        }
    }
    

    private func addAppointment() {
        let appointment = PlumbingAppointment(
            customerName: customerName,
            service: service,
            address: address,
            date: appointmentDate,
            notes: notes,
            customerID: selectedCustomerID
        )


        appointments.append(appointment)
        selectedDate = appointmentDate

        customerName = ""
        service = ""
        address = ""
        notes = ""
        selectedCustomerID = nil

        activeSheet = nil
    }

    private func saveAppointments(
        _ appointments: [PlumbingAppointment]
    ) {
        guard let data = try? JSONEncoder().encode(
            appointments
        ) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: Self.storageKey
        )
    }

    private static func loadAppointments()
        -> [PlumbingAppointment] {

        guard let data = UserDefaults.standard.data(
            forKey: storageKey
        ) else {
            return []
        }

        return (try? JSONDecoder().decode(
            [PlumbingAppointment].self,
            from: data
        )) ?? []
    }
}

#Preview {
    CalendarView()
}
