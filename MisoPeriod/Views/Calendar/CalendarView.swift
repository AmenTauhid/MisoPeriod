import SwiftUI

struct MisoCalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @ObservedObject var cycleViewModel: CycleViewModel
    @State private var showingDayDetail = false
    @State private var showingLogOptions = false
    @State private var showingPeriodEntry = false
    @State private var showingDeleteLog = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Month navigation header
                    monthHeader
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Weekday headers
                    weekdayHeader
                        .padding(.horizontal)
                        .padding(.top, 16)

                    // Calendar grid
                    calendarGrid
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Legend
                    legendView
                        .padding()

                    Spacer()
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showingPeriodEntry = true
                        } label: {
                            Label("Log Period", systemImage: "calendar.badge.plus")
                        }

                        Button(role: .destructive) {
                            showingDeleteLog = true
                        } label: {
                            Label("Delete Log", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.misoPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") {
                        viewModel.goToToday()
                    }
                    .font(.misoSubheadline)
                    .foregroundColor(.misoPrimary)
                }
            }
            .sheet(isPresented: $showingDayDetail) {
                if let selectedDate = viewModel.selectedDate {
                    DayDetailSheet(
                        date: selectedDate,
                        log: viewModel.getLog(for: selectedDate),
                        cycleViewModel: cycleViewModel,
                        onDismiss: {
                            showingDayDetail = false
                            Task {
                                await viewModel.refresh()
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showingPeriodEntry) {
                PeriodEntryView(viewModel: cycleViewModel, isPresented: $showingPeriodEntry)
            }
            .sheet(isPresented: $showingDeleteLog) {
                DeleteLogView(viewModel: cycleViewModel, isPresented: $showingDeleteLog)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }

    // MARK: - Month Header
    private var monthHeader: some View {
        HStack {
            Button {
                viewModel.previousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.misoPrimary)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(.misoTitle2)
                .foregroundColor(.misoTextPrimary)

            Spacer()

            Button {
                viewModel.nextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.misoPrimary)
                    .frame(width: 44, height: 44)
            }
        }
    }

    // MARK: - Weekday Header
    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(viewModel.weekdayHeaders, id: \.self) { day in
                Text(day)
                    .font(.misoCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.misoTextSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(viewModel.daysInMonth) { day in
                CalendarDayCell(day: day) {
                    if let date = day.date, !day.isInFuture {
                        viewModel.selectDate(date)
                        showingDayDetail = true
                    }
                }
            }
        }
    }

    // MARK: - Legend
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Legend")
                .font(.misoSubheadline)
                .fontWeight(.medium)
                .foregroundColor(.misoTextSecondary)

            HStack(spacing: 16) {
                LegendItem(color: .misoPeriod, label: "Period")
                LegendItem(color: .misoPrimary.opacity(0.3), label: "Predicted")
                LegendItem(color: .misoFertile.opacity(0.4), label: "Fertile")
                LegendItem(color: .misoOvulation, label: "Ovulation")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let day: CalendarDay
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(day.type.backgroundColor)
                    .frame(height: 44)

                // Today indicator ring
                if day.isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.misoPrimary, lineWidth: 2)
                        .frame(height: 44)
                }

                // Day number
                if let _ = day.date {
                    VStack(spacing: 2) {
                        Text("\(day.dayNumber)")
                            .font(.misoBody)
                            .fontWeight(day.isToday ? .bold : .regular)
                            .foregroundColor(dayTextColor)

                        // Indicator dots
                        if day.log != nil && day.type == .logged {
                            Circle()
                                .fill(Color.misoAccent)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(day.date == nil || day.isInFuture)
        .opacity(day.isInFuture ? 0.4 : 1.0)
    }

    private var dayTextColor: Color {
        if day.isInFuture {
            return .misoTextTertiary
        }
        return day.type.textColor
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 16, height: 16)

            Text(label)
                .font(.misoCaption)
                .foregroundColor(.misoTextSecondary)
        }
    }
}

// MARK: - Day Detail Sheet
struct DayDetailSheet: View {
    let date: Date
    let log: DailyLog?
    @ObservedObject var cycleViewModel: CycleViewModel
    let onDismiss: () -> Void

    @State private var showingEditLog = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Date header
                        dateHeader

                        if let log = log {
                            // Existing log details
                            logDetailsView(log)
                        } else {
                            // No log for this day
                            emptyStateView
                        }

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle(date.dayOfWeekFull)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onDismiss()
                    }
                    .foregroundColor(.misoTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    if log != nil {
                        Menu {
                            Button {
                                showingEditLog = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.misoPrimary)
                        }
                    } else {
                        Button("Log") {
                            showingEditLog = true
                        }
                        .foregroundColor(.misoPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingEditLog) {
                DailyLogView(
                    viewModel: cycleViewModel,
                    isPresented: $showingEditLog,
                    initialDate: date
                )
            }
            .confirmationDialog("Delete this log?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let log = log {
                        Task {
                            await cycleViewModel.deleteLog(log)
                            onDismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private var dateHeader: some View {
        VStack(spacing: 8) {
            Text(date.longDateString)
                .font(.misoTitle3)
                .foregroundColor(.misoTextPrimary)

            if let cycleDay = calculateCycleDay() {
                Text("Cycle Day \(cycleDay)")
                    .font(.misoSubheadline)
                    .foregroundColor(.misoTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    private func logDetailsView(_ log: DailyLog) -> some View {
        VStack(spacing: 16) {
            // Flow
            if log.flow.isPeriod {
                detailCard(title: "Flow", icon: "drop.fill", color: .misoPeriod) {
                    HStack {
                        ForEach(0..<log.flow.dropCount, id: \.self) { _ in
                            Image(systemName: "drop.fill")
                                .foregroundColor(.misoPeriod)
                        }
                        Spacer()
                        Text(log.flow.displayName)
                            .foregroundColor(.misoTextSecondary)
                    }
                }
            }

            // Mood & Energy
            HStack(spacing: 12) {
                if log.mood > 0 {
                    miniCard(title: "Mood", value: "\(log.mood)/5", icon: moodEmoji(for: Int(log.mood)))
                }
                if log.energy > 0 {
                    miniCard(title: "Energy", value: "\(log.energy)/5", icon: energyEmoji(for: Int(log.energy)))
                }
            }

            // Symptoms
            if !log.symptomTypes.isEmpty {
                detailCard(title: "Symptoms", icon: "list.bullet", color: .misoAccent) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                        ForEach(log.symptomTypes, id: \.self) { symptom in
                            HStack(spacing: 4) {
                                Image(systemName: symptom.icon)
                                    .font(.caption)
                                Text(symptom.displayName)
                                    .font(.misoCaption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(symptom.color.opacity(0.15))
                            )
                            .foregroundColor(symptom.color)
                        }
                    }
                }
            }

            // Notes
            if let notes = log.notes, !notes.isEmpty {
                detailCard(title: "Notes", icon: "note.text", color: .misoTextSecondary) {
                    Text(notes)
                        .font(.misoBody)
                        .foregroundColor(.misoTextPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func detailCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    private func miniCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.title)

            Text(title)
                .font(.misoCaption)
                .foregroundColor(.misoTextSecondary)

            Text(value)
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.misoTextTertiary)

            Text("No log for this day")
                .font(.misoHeadline)
                .foregroundColor(.misoTextSecondary)

            Text("Tap 'Log' to add an entry")
                .font(.misoBody)
                .foregroundColor(.misoTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    private func calculateCycleDay() -> Int? {
        guard let cycle = cycleViewModel.currentCycle,
              let startDate = cycle.startDate else { return nil }
        let days = startDate.daysBetween(date)
        return days >= 0 ? days + 1 : nil
    }

    private func moodEmoji(for value: Int) -> String {
        switch value {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }

    private func energyEmoji(for value: Int) -> String {
        switch value {
        case 1: return "🔋"
        case 2: return "🪫"
        case 3: return "⚡️"
        case 4: return "💪"
        case 5: return "🚀"
        default: return "⚡️"
        }
    }
}

#Preview {
    MisoCalendarView(cycleViewModel: CycleViewModel.preview)
}
