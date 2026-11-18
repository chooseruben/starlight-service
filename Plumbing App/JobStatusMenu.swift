
import SwiftUI

struct JobStatusMenu: View {

    let appointmentID: UUID

    @AppStorage("savedPlumbingAppointments")
    private var appointmentsData: Data = Data()

    private let statuses = [
        "Scheduled",
        "In Progress",
        "Completed",
        "Cancelled"
    ]

    private var currentStatus: String {
        guard let appointments = try? JSONDecoder().decode(
            [PlumbingAppointment].self,
            from: appointmentsData
        ) else {
            return "Scheduled"
        }

        return appointments.first {
            $0.id == appointmentID
        }?.status ?? "Scheduled"
    }

    var body: some View {
        Menu {
            ForEach(statuses, id: \.self) { status in
                Button {
                    updateStatus(status)
                } label: {
                    if status == currentStatus {
                        Label(status, systemImage: "checkmark")
                    } else {
                        Text(status)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(statusColor(currentStatus))
                    .frame(width: 9, height: 9)

                Text(currentStatus)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(statusColor(currentStatus))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                statusColor(currentStatus).opacity(0.1)
            )
            .clipShape(Capsule())
        }
        .accessibilityLabel(
            "Job status: \(currentStatus). Tap to change."
        )
    }

    private func updateStatus(_ newStatus: String) {
        guard var appointments = try? JSONDecoder().decode(
            [PlumbingAppointment].self,
            from: appointmentsData
        ) else {
            return
        }

        guard let index = appointments.firstIndex(
            where: { $0.id == appointmentID }
        ) else {
            return
        }

        appointments[index].status = newStatus

        guard let updatedData = try? JSONEncoder().encode(
            appointments
        ) else {
            return
        }

        appointmentsData = updatedData
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "In Progress":
            return .blue
        case "Completed":
            return .green
        case "Cancelled":
            return .red
        default:
            return .orange
        }
    }
}
