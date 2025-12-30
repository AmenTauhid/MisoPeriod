import Foundation
import SwiftUI
import Combine
import CoreData

@MainActor
class CalendarViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentMonth: Date = Date()
    @Published var selectedDate: Date? = nil
    @Published var monthLogs: [Date: DailyLog] = [:]
    @Published var isLoading = false

    // MARK: - Dependencies
    private let cycleService: CycleService
    private var currentCycle: Cycle?

    // MARK: - Computed Properties
    var monthTitle: String {
        currentMonth.monthYearString
    }

    var daysInMonth: [CalendarDay] {
        generateCalendarDays()
    }

    var weekdayHeaders: [String] {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }

    // MARK: - Initialization
    init(cycleService: CycleService = CycleService()) {
        self.cycleService = cycleService
        Task {
            await loadData()
        }
    }

    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            currentCycle = try cycleService.fetchActiveCycle()
            await loadMonthLogs()
        } catch {
            print("Error loading calendar data: \(error)")
        }
    }

    func loadMonthLogs() async {
        let startOfMonth = currentMonth.startOfMonth
        let endOfMonth = currentMonth.endOfMonth

        do {
            let logs = try cycleService.fetchDailyLogs(from: startOfMonth, to: endOfMonth)
            var logsByDate: [Date: DailyLog] = [:]
            for log in logs {
                if let date = log.date {
                    logsByDate[date.startOfDay] = log
                }
            }
            monthLogs = logsByDate
        } catch {
            print("Error loading month logs: \(error)")
        }
    }

    // MARK: - Navigation
    func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = currentMonth.adding(months: -1)
        }
        Task {
            await loadMonthLogs()
        }
    }

    func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = currentMonth.adding(months: 1)
        }
        Task {
            await loadMonthLogs()
        }
    }

    func goToToday() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = Date()
            selectedDate = Date().startOfDay
        }
        Task {
            await loadMonthLogs()
        }
    }

    func selectDate(_ date: Date) {
        selectedDate = date.startOfDay
    }

    // MARK: - Calendar Generation
    private func generateCalendarDays() -> [CalendarDay] {
        var days: [CalendarDay] = []
        let startOfMonth = currentMonth.startOfMonth
        let firstWeekday = startOfMonth.firstWeekdayOfMonth

        // Add empty days for padding before first day of month
        for _ in 1..<firstWeekday {
            days.append(CalendarDay(date: nil, type: .empty))
        }

        // Add days of the month
        for date in currentMonth.allDatesInMonth() {
            let dayType = determineDayType(for: date)
            let log = monthLogs[date.startOfDay]
            days.append(CalendarDay(date: date, type: dayType, log: log))
        }

        return days
    }

    private func determineDayType(for date: Date) -> CalendarDayType {
        let today = Date().startOfDay
        let targetDate = date.startOfDay

        // Check if we have a log for this date
        if let log = monthLogs[targetDate] {
            let flow = FlowIntensity.from(log.flowIntensity)
            if flow.isPeriod {
                return .period(intensity: flow)
            }
        }

        // Check cycle predictions
        if let cycle = currentCycle {
            // Check if date is in predicted period (future)
            if targetDate > today, let nextPeriodStart = predictedPeriodStart(for: cycle) {
                let predictedEnd = nextPeriodStart.adding(days: 4)
                if targetDate >= nextPeriodStart && targetDate <= predictedEnd {
                    return .predictedPeriod
                }
            }

            // Check fertile window
            if let fertileStart = cycle.fertileWindowStart,
               let fertileEnd = cycle.fertileWindowEnd {
                if targetDate >= fertileStart && targetDate <= fertileEnd {
                    // Check if it's ovulation day (middle of fertile window)
                    if let ovulationDate = cycle.ovulationDate,
                       targetDate.isSameDay(as: ovulationDate) {
                        return .ovulation
                    }
                    return .fertile
                }
            }
        }

        // Check if logged (non-period)
        if monthLogs[targetDate] != nil {
            return .logged
        }

        return .normal
    }

    private func predictedPeriodStart(for cycle: Cycle) -> Date? {
        guard let startDate = cycle.startDate else { return nil }
        let cycleLength = cycle.cycleLength > 0 ? Int(cycle.cycleLength) : 28
        return startDate.adding(days: cycleLength)
    }

    // MARK: - Helper Methods
    func getLog(for date: Date) -> DailyLog? {
        monthLogs[date.startOfDay]
    }

    func hasLog(for date: Date) -> Bool {
        monthLogs[date.startOfDay] != nil
    }

    func refresh() async {
        await loadData()
    }
}

// MARK: - Calendar Day Model
struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date?
    let type: CalendarDayType
    var log: DailyLog?

    var isToday: Bool {
        guard let date = date else { return false }
        return date.isToday
    }

    var isInFuture: Bool {
        guard let date = date else { return false }
        return date.startOfDay > Date().startOfDay
    }

    var dayNumber: Int {
        date?.dayOfMonth ?? 0
    }
}

// MARK: - Calendar Day Type
enum CalendarDayType: Equatable {
    case empty
    case normal
    case logged
    case period(intensity: FlowIntensity)
    case predictedPeriod
    case fertile
    case ovulation

    var backgroundColor: Color {
        switch self {
        case .empty, .normal:
            return .clear
        case .logged:
            return .misoBgSecondary
        case .period(let intensity):
            return intensity.color
        case .predictedPeriod:
            return .misoPrimary.opacity(0.3)
        case .fertile:
            return .misoFertile.opacity(0.4)
        case .ovulation:
            return .misoOvulation
        }
    }

    var textColor: Color {
        switch self {
        case .period(let intensity) where intensity.rawValue >= 2:
            return .white
        case .ovulation:
            return .white
        default:
            return .misoTextPrimary
        }
    }

    var isPeriod: Bool {
        if case .period = self { return true }
        if case .predictedPeriod = self { return true }
        return false
    }
}

// MARK: - Preview Helper
extension CalendarViewModel {
    static var preview: CalendarViewModel {
        CalendarViewModel(cycleService: CycleService(context: PersistenceController.preview.container.viewContext))
    }
}
