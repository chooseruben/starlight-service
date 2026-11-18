
import SwiftUI

struct PlumbingCustomer: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var phone: String
    var email: String
    var address: String
    var notes: String
}

struct CustomersView: View {

    @State private var customers: [PlumbingCustomer] =
        Self.loadCustomers()

    @State private var searchText = ""
    @State private var activeSheet: CustomerSheet?
    @State private var customerPendingDeletion: PlumbingCustomer?
    @State private var linkedJobCount = 0
    @State private var showingDeleteAlert = false


    private static let storageKey = "savedPlumbingCustomers"

    private enum CustomerSheet: Identifiable {
        case add
        case edit(PlumbingCustomer)

        var id: String {
            switch self {
            case .add:
                return "add"
            case .edit(let customer):
                return customer.id.uuidString
            }
        }
    }

    private var filteredCustomers: [PlumbingCustomer] {
        let sorted = customers.sorted {
            $0.name.localizedCaseInsensitiveCompare(
                $1.name
            ) == .orderedAscending
        }

        guard !searchText.isEmpty else {
            return sorted
        }

        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || $0.phone.localizedCaseInsensitiveContains(searchText)
            || $0.address.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label(
                            "Total Customers",
                            systemImage: "person.2.fill"
                        )

                        Spacer()

                        Text("\(customers.count)")
                            .fontWeight(.bold)
                    }
                }

                Section("Customer Directory") {
                    if filteredCustomers.isEmpty {
                        ContentUnavailableView(
                            "No Customers Found",
                            systemImage: "person.crop.circle.badge.questionmark"
                        )
                    } else {
                        ForEach(filteredCustomers) { customer in
                            NavigationLink {
                                CustomerDetailView(customer: customer) { updated in
                                    if let index = customers.firstIndex(
                                        where: { $0.id == updated.id }
                                    ) {
                                        customers[index] = updated
                                    }
                                }
                            } label: {
                                customerRow(customer)
                            }
                        }
                        .onDelete(perform: deleteCustomers)

                    }
                }
            }
            .navigationTitle("Customers")
            .searchable(
                text: $searchText,
                prompt: "Search customers"
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .add
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .add:
                    CustomerFormView(customer: nil) { customer in
                        customers.append(customer)
                    }

                case .edit(let customer):
                    CustomerFormView(customer: customer) { updated in
                        if let index = customers.firstIndex(
                            where: { $0.id == updated.id }
                        ) {
                            customers[index] = updated
                        }
                    }
                }
            }
            .alert(
                linkedJobCount > 0
                    ? "Cannot Delete Customer"
                    : "Delete Customer?",
                isPresented: $showingDeleteAlert
            ) {
                if linkedJobCount > 0 {
                    Button("OK", role: .cancel) {
                        customerPendingDeletion = nil
                    }
                } else {
                    Button("Cancel", role: .cancel) {
                        customerPendingDeletion = nil
                    }

                    Button("Delete", role: .destructive) {
                        confirmCustomerDeletion()
                    }
                }
            } message: {
                if let customer = customerPendingDeletion {
                    if linkedJobCount > 0 {
                        Text(
                            "\(customer.name) has \(linkedJobCount) linked plumbing job(s). Reassign or unlink these jobs before deleting this customer."
                        )
                    } else {
                        Text(
                            "Are you sure you want to delete \(customer.name)? This action cannot be undone."
                        )
                    }
                }
            }

            .onChange(of: customers) { _, updated in
                saveCustomers(updated)
            }
        }
    }

    private func customerRow(
        _ customer: PlumbingCustomer
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "person.crop.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 5) {
                Text(customer.name)
                    .font(.headline)

                if !customer.phone.isEmpty {
                    Text(customer.phone)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !customer.address.isEmpty {
                    Text(customer.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 5)
    }

    private func deleteCustomers(at offsets: IndexSet) {
        guard let index = offsets.first else { return }

        let customer = filteredCustomers[index]

        // Retrieve the latest saved appointments
        let data = UserDefaults.standard.data(
            forKey: "savedPlumbingAppointments"
        ) ?? Data()

        let appointments = (try? JSONDecoder().decode(
            [PlumbingAppointment].self,
            from: data
        )) ?? []

        // Count appointments linked to this customer
        linkedJobCount = appointments.filter {
            $0.customerID == customer.id
        }.count

        customerPendingDeletion = customer
        showingDeleteAlert = true
    }

    private func confirmCustomerDeletion() {
        guard let customer = customerPendingDeletion else {
            return
        }

        // Check the latest saved data again before deleting
        let appointments: [PlumbingAppointment]

        if let data = UserDefaults.standard.data(
            forKey: "savedPlumbingAppointments"
        ) {
            guard let decoded = try? JSONDecoder().decode(
                [PlumbingAppointment].self,
                from: data
            ) else {
                return
            }

            appointments = decoded
        } else {
            appointments = []
        }

        guard !appointments.contains(where: {
            $0.customerID == customer.id
        }) else {
            return
        }

        customers.removeAll {
            $0.id == customer.id
        }

        customerPendingDeletion = nil
    }


    private func saveCustomers(
        _ customers: [PlumbingCustomer]
    ) {
        guard let data = try? JSONEncoder().encode(customers) else {
            return
        }

        UserDefaults.standard.set(
            data,
            forKey: Self.storageKey
        )
    }

    private static func loadCustomers() -> [PlumbingCustomer] {
        guard let data = UserDefaults.standard.data(
            forKey: storageKey
        ) else {
            return []
        }

        return (try? JSONDecoder().decode(
            [PlumbingCustomer].self,
            from: data
        )) ?? []
    }
}

// MARK: - Add and Edit Customer Form

struct CustomerFormView: View {

    @Environment(\.dismiss) private var dismiss

    let customer: PlumbingCustomer?
    let onSave: (PlumbingCustomer) -> Void

    @State private var name: String
    @State private var phone: String
    @State private var email: String
    @State private var address: String
    @State private var notes: String

    @State private var showingAddressSearch = false

    init(
        customer: PlumbingCustomer?,
        onSave: @escaping (PlumbingCustomer) -> Void
    ) {
        self.customer = customer
        self.onSave = onSave

        _name = State(initialValue: customer?.name ?? "")
        _phone = State(initialValue: customer?.phone ?? "")
        _email = State(initialValue: customer?.email ?? "")
        _address = State(initialValue: customer?.address ?? "")
        _notes = State(initialValue: customer?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Full Name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()


                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                        .onChange(of: phone) { _, newValue in
                            let formatted = PhoneNumberFormatter.format(newValue)

                            if phone != formatted {
                                phone = formatted
                            }
                        }


                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("Service Address") {
                    Button {
                        showingAddressSearch = true
                    } label: {
                        Label(
                            address.isEmpty
                                ? "Search Customer Address"
                                : address,
                            systemImage: "mappin.circle"
                        )
                    }
                }

                Section("Customer Notes") {
                    TextField(
                        "Additional information",
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
            .navigationTitle(
                customer == nil ? "New Customer" : "Edit Customer"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCustomer()
                    }
                    .disabled(
                        name.trimmingCharacters(
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

    private func saveCustomer() {
        let updated = PlumbingCustomer(
            id: customer?.id ?? UUID(),
            name: name.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).localizedCapitalized,
            phone: PhoneNumberFormatter.format(phone),
            email: email,
            address: address,
            notes: notes
        )

        onSave(updated)
        dismiss()
    }
}

#Preview {
    CustomersView()
}
