
import SwiftUI

struct HomeView: View {

    @AppStorage("pendingTaskCount")
    private var pendingTaskCount = 3

    @AppStorage("savedPlumbingAppointments")
    private var appointmentsData: Data = Data()

    private var allAppointments: [PlumbingAppointment] {
        (try? JSONDecoder().decode(
            [PlumbingAppointment].self,
            from: appointmentsData
        )) ?? []
    }

    private var todaysAppointments: [PlumbingAppointment] {
        allAppointments
            .filter {
                Calendar.current.isDateInToday($0.date)
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Welcome Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome Back!")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text(
                            Date.now,
                            format: .dateTime
                                .weekday(.wide)
                                .month(.wide)
                                .day()
                        )
                        .foregroundStyle(.secondary)
                    }

                    // Today's Jobs
                    VStack(alignment: .leading, spacing: 12) {
                        Label(
                            "Today's Jobs",
                            systemImage: "calendar"
                        )
                        .font(.headline)

                        Text("\(todaysAppointments.count) Scheduled Jobs")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Your appointments scheduled for today.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16)
                    )

                    // Quick Overview
                    Text("Quick Overview")
                        .font(.title2)
                        .fontWeight(.bold)

                    HStack(spacing: 12) {
                        overviewCard(
                            title: "Total Appointments",
                            value: "\(allAppointments.count)",
                            icon: "calendar.badge.clock",
                            color: .blue
                        )

                        overviewCard(
                            title: "Pending Tasks",
                            value: "\(pendingTaskCount)",
                            icon: "checklist",
                            color: .orange
                        )
                    }

                    // Today's Appointments
                    Text("Today's Appointments")
                        .font(.title2)
                        .fontWeight(.bold)

                    if todaysAppointments.isEmpty {
                        VStack(spacing: 12) {
                            Image(
                                systemName: "calendar.badge.checkmark"
                            )
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)

                            Text("No Appointments Today")
                                .font(.headline)

                            Text(
                                "Your scheduled jobs will appear here."
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(30)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                    
                    } else {
                        ForEach(todaysAppointments) { appointment in
                            NavigationLink {
                                AppointmentDetailView(
                                    appointment: appointment
                                )
                            } label: {
                                appointmentRow(appointment)
                            }
                            .buttonStyle(.plain)
                        }
                    }


                    // To-Do List
                    TodoListView()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }

    private func overviewCard(
        title: String,
        value: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func appointmentRow(
        _ appointment: PlumbingAppointment
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(appointment.customerName)
                        .fontWeight(.semibold)

                    Text(appointment.service)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(
                    appointment.date,
                    format: .dateTime.hour().minute()
                )
                .font(.subheadline)
                .foregroundStyle(.blue)
            }

            if !appointment.address.isEmpty {
                Label(
                    appointment.address,
                    systemImage: "mappin.circle"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Text(appointment.status)
                .font(.caption)
                .foregroundStyle(.green)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HomeView()
}
