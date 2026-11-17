
import SwiftUI

struct CustomerPickerView: View {

    @Environment(\.dismiss) private var dismiss

    @AppStorage("savedPlumbingCustomers")
    private var customersData: Data = Data()

    let onSelect: (PlumbingCustomer) -> Void

    @State private var searchText = ""

    private var customers: [PlumbingCustomer] {
        (try? JSONDecoder().decode(
            [PlumbingCustomer].self,
            from: customersData
        )) ?? []
    }

    private var filteredCustomers: [PlumbingCustomer] {
        customers
            .filter { customer in
                searchText.isEmpty ||
                customer.name.localizedCaseInsensitiveContains(
                    searchText
                ) ||
                customer.phone.localizedCaseInsensitiveContains(
                    searchText
                ) ||
                customer.address.localizedCaseInsensitiveContains(
                    searchText
                )
            }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare(
                    $1.name
                ) == .orderedAscending
            }
    }

    var body: some View {
        NavigationStack {
            List {
                if filteredCustomers.isEmpty {
                    ContentUnavailableView(
                        "No Customers Found",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text(
                            "Add customers in the Customers tab first."
                        )
                    )
                } else {
                    ForEach(filteredCustomers) { customer in
                        Button {
                            onSelect(customer)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(
                                    systemName: "person.crop.circle.fill"
                                )
                                .font(.largeTitle)
                                .foregroundStyle(.blue)

                                VStack(
                                    alignment: .leading,
                                    spacing: 5
                                ) {
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
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("Select Customer")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                prompt: "Search name or phone"
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
