
import SwiftUI

struct CustomerDetailView: View {

    let customer: PlumbingCustomer
    let onSave: (PlumbingCustomer) -> Void

    @AppStorage("savedPlumbingAppointments")
    private var appointmentsData: Data = Data()

    @State private var showingEditCustomer = false

    private var customerJobs: [PlumbingAppointment] {
        let all = (try? JSONDecoder().decode(
            [PlumbingAppointment].self,
            from: appointmentsData
        )) ?? []

        return all
            .filter { $0.customerID == customer.id }
            .sorted { $0.date > $1.date }
    }

    private var completedJobs: Int {
        customerJobs.filter {
            $0.status == "Completed"
        }.count
    }

    var body: some View {
        List {

            Section("Customer Information") {
                Label(customer.name, systemImage: "person.fill")

                if !customer.phone.isEmpty {
                    LabeledContent("Phone") {
                        Link(
                            customer.phone,
                            destination: URL(
                                string: "tel:\(customer.phone.filter { $0.isNumber || $0 == "+" })"
                            )!
                        )
                    }
                }

                if !customer.email.isEmpty {
                    LabeledContent("Email") {
                        Text(customer.email)
                    }
                }

                if !customer.address.isEmpty {
                    AppointmentMapView(
                        address: customer.address
                    )
                }
            }

            Section("Service Overview") {
                HStack {
                    overviewCard(
                        title: "Total Jobs",
                        count: customerJobs.count,
                        icon: "wrench.fill"
                    )

                    overviewCard(
                        title: "Completed",
                        count: completedJobs,
                        icon: "checkmark.circle.fill"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section("Service History") {
                if customerJobs.isEmpty {
                    ContentUnavailableView(
                        "No Linked Jobs",
                        systemImage: "clock.arrow.circlepath",
                        description: Text(
                            "Appointments linked to this customer will appear here."
                        )
                    )
                } else {
                    ForEach(customerJobs) { job in
                        VStack(alignment: .leading, spacing: 10) {
                            NavigationLink {
                                AppointmentDetailView(appointment: job)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(job.service)
                                        .font(.headline)

                                    Text(
                                        job.date,
                                        format: .dateTime
                                            .month()
                                            .day()
                                            .year()
                                            .hour()
                                            .minute()
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }

                            JobStatusMenu(appointmentID: job.id)
                        }
                    }

                }
            }

            if !customer.notes.isEmpty {
                Section("Customer Notes") {
                    Text(customer.notes)
                }
            }
        }
        .navigationTitle("Customer Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditCustomer = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEditCustomer) {
            CustomerFormView(customer: customer) { updated in
                onSave(updated)
            }
        }
    }

    private func overviewCard(
        title: String,
        count: Int,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)

            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
