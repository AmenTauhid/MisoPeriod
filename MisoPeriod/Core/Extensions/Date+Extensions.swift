import Foundation

extension Date {
    // MARK: - Calendar Helpers

    static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday
        return calendar
    }

    var startOfDay: Date {
        Date.calendar.startOfDay(for: self)
    }

    var endOfDay: Date {
        Date.calendar.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }

    var startOfMonth: Date {
        let components = Date.calendar.dateComponents([.year, .month], from: self)
        return Date.calendar.date(from: components) ?? self
    }

    var endOfMonth: Date {
        guard let nextMonth = Date.calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return self }
        return Date.calendar.date(byAdding: .day, value: -1, to: nextMonth) ?? self
    }

    var startOfWeek: Date {
        let components = Date.calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return Date.calendar.date(from: components) ?? self
    }

    // MARK: - Day Operations

    func adding(days: Int) -> Date {
        Date.calendar.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(months: Int) -> Date {
        Date.calendar.date(byAdding: .month, value: months, to: self) ?? self
    }

    func daysBetween(_ other: Date) -> Int {
        let components = Date.calendar.dateComponents([.day], from: self.startOfDay, to: other.startOfDay)
        return components.day ?? 0
    }

    var dayOfMonth: Int {
        Date.calendar.component(.day, from: self)
    }

    var month: Int {
        Date.calendar.component(.month, from: self)
    }

    var year: Int {
        Date.calendar.component(.year, from: self)
    }

    var weekday: Int {
        Date.calendar.component(.weekday, from: self)
    }

    var isToday: Bool {
        Date.calendar.isDateInToday(self)
    }

    var isYesterday: Bool {
        Date.calendar.isDateInYesterday(self)
    }

    var isTomorrow: Bool {
        Date.calendar.isDateInTomorrow(self)
    }

    var isInFuture: Bool {
        self > Date()
    }

    var isInPast: Bool {
        self < Date()
    }

    func isSameDay(as other: Date) -> Bool {
        Date.calendar.isDate(self, inSameDayAs: other)
    }

    func isSameMonth(as other: Date) -> Bool {
        let selfComponents = Date.calendar.dateComponents([.year, .month], from: self)
        let otherComponents = Date.calendar.dateComponents([.year, .month], from: other)
        return selfComponents.year == otherComponents.year && selfComponents.month == otherComponents.month
    }

    // MARK: - Month Grid Helpers

    var daysInMonth: Int {
        Date.calendar.range(of: .day, in: .month, for: self)?.count ?? 30
    }

    var firstWeekdayOfMonth: Int {
        Date.calendar.component(.weekday, from: startOfMonth)
    }

    func allDatesInMonth() -> [Date] {
        var dates: [Date] = []
        let range = Date.calendar.range(of: .day, in: .month, for: self)!
        for day in range {
            if let date = Date.calendar.date(bySetting: .day, value: day, of: startOfMonth) {
                dates.append(date)
            }
        }
        return dates
    }

    // MARK: - Cycle Helpers

    func cycleDay(from startDate: Date) -> Int {
        startDate.daysBetween(self) + 1
    }

    // MARK: - Formatting

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }

    var mediumDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    var longDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: self)
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    var dayOfWeekShort: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    var dayOfWeekFull: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    // MARK: - Relative Formatting

    var relativeString: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else if isTomorrow {
            return "Tomorrow"
        } else {
            let days = Date().startOfDay.daysBetween(self.startOfDay)
            if days > 0 && days <= 7 {
                return "In \(days) days"
            } else if days < 0 && days >= -7 {
                return "\(abs(days)) days ago"
            } else {
                return mediumDateString
            }
        }
    }
}

// MARK: - Date Range
extension ClosedRange where Bound == Date {
    func contains(date: Date) -> Bool {
        date >= lowerBound.startOfDay && date <= upperBound.endOfDay
    }
}
