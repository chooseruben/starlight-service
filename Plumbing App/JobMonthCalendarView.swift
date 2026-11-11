
import SwiftUI

struct JobMonthCalendarView: View {

    @Binding var selectedDate: Date
    let appointments: [PlumbingAppointment]

    @State private var displayedMonth = Date()
    @State private var showingMonthPicker = false
    @State private var jumpMonth = 1
    @State private var jumpYear = 2026

    private let calendar = Calendar.current

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 4),
        count: 7
    )

    private var monthStart: Date {
        calendar.dateInterval(
            of: .month,
            for: displayedMonth
        )?.start ?? displayedMonth
    }

    private var firstGridDate: Date {
        let weekday = calendar.component(
            .weekday,
            from: monthStart
        )

        let offset = (
            weekday - calendar.firstWeekday + 7
        ) % 7

        return calendar.date(
            byAdding: .day,
            value: -offset,
            to: monthStart
        ) ?? monthStart
    }

    private var weekdayNames: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let offset = calendar.firstWeekday - 1

        return (0..<7).map {
            symbols[($0 + offset) % 7]
        }
    }

    var body: some View {
        VStack(spacing: 16) {

            HStack {
                
                Button {
                    jumpMonth = calendar.component(
                        .month,
                        from: displayedMonth
                    )

                    jumpYear = calendar.component(
                        .year,
                        from: displayedMonth
                    )

                    showingMonthPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Text(
                            displayedMonth,
                            format: .dateTime.month(.wide).year()
                        )
                        .font(.title2)
                        .fontWeight(.bold)

                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choose month and year")


                Spacer()

                Button {
                    changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                }

                Button {
                    changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {

                ForEach(0..<7, id: \.self) { index in
                    Text(weekdayNames[index])
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }

                ForEach(0..<42, id: \.self) { index in

                    if let date = calendar.date(
                        byAdding: .day,
                        value: index,
                        to: firstGridDate
                    ) {
                        if calendar.isDate(
                            date,
                            equalTo: displayedMonth,
                            toGranularity: .month
                        ) {
                            dayCell(for: date)
                        } else {
                            Color.clear
                                .frame(height: 56)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            displayedMonth = selectedDate
        }
        .onChange(of: selectedDate) { _, newDate in
            displayedMonth = newDate
        }
        
        .sheet(isPresented: $showingMonthPicker) {
            NavigationStack {
                Form {
                    Picker("Month", selection: $jumpMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(
                                calendar.monthSymbols[month - 1]
                            )
                            .tag(month)
                        }
                    }

                    Picker("Year", selection: $jumpYear) {
                        ForEach(2000...2100, id: \.self) { year in
                            Text(String(year))
                                .tag(year)
                        }
                    }
                }
                .navigationTitle("Jump to Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showingMonthPicker = false
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            jumpToSelectedMonth()
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }

    }

    private func dayCell(for date: Date) -> some View {

        let count = appointments.filter {
            calendar.isDate(
                $0.date,
                inSameDayAs: date
            )
        }.count

        let isSelected = calendar.isDate(
            date,
            inSameDayAs: selectedDate
        )

        let isToday = calendar.isDateInToday(date)

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 4) {

                Text(
                    "\(calendar.component(.day, from: date))"
                )
                .font(.subheadline)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundStyle(
                    isSelected ? .blue : .primary
                )

                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(
                            count >= 4
                                ? Color.orange
                                : Color.blue
                        )
                        .clipShape(Circle())
                } else {
                    Color.clear
                        .frame(width: 22, height: 22)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isSelected
                    ? Color.blue.opacity(0.12)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(date.formatted(date: .complete, time: .omitted)), \(count) jobs"
        )
    }

    private func changeMonth(by amount: Int) {
        if let newMonth = calendar.date(
            byAdding: .month,
            value: amount,
            to: monthStart
        ) {
            displayedMonth = newMonth
        }
    }
    
    private func jumpToSelectedMonth() {
        let components = DateComponents(
            year: jumpYear,
            month: jumpMonth,
            day: 1
        )

        if let newDate = calendar.date(from: components) {
            displayedMonth = newDate
            selectedDate = newDate
        }

        showingMonthPicker = false
    }

}

#Preview {
    JobMonthCalendarView(
        selectedDate: .constant(Date()),
        appointments: []
    )
}
