import Foundation
import UserNotifications
import CoreData
import Combine

/// Manages local notifications for period reminders, fertile window alerts, and daily logging
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let viewContext: NSManagedObjectContext

    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Notification Types
    enum NotificationType: String, CaseIterable, Identifiable {
        case periodReminder = "period_reminder"
        case fertileWindow = "fertile_window"
        case dailyLog = "daily_log"
        case ovulation = "ovulation"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .periodReminder: return "Period Reminder"
            case .fertileWindow: return "Fertile Window"
            case .dailyLog: return "Daily Log Reminder"
            case .ovulation: return "Ovulation Day"
            }
        }

        var description: String {
            switch self {
            case .periodReminder: return "Get notified before your period starts"
            case .fertileWindow: return "Alert when fertile window begins"
            case .dailyLog: return "Daily reminder to log your symptoms"
            case .ovulation: return "Notification on predicted ovulation day"
            }
        }

        var icon: String {
            switch self {
            case .periodReminder: return "drop.fill"
            case .fertileWindow: return "leaf.fill"
            case .dailyLog: return "square.and.pencil"
            case .ovulation: return "sparkles"
            }
        }

        var defaultDaysBefore: Int16 {
            switch self {
            case .periodReminder: return 2
            case .fertileWindow: return 1
            case .dailyLog: return 0
            case .ovulation: return 0
            }
        }
    }

    // MARK: - Initialization
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        checkAuthorizationStatus()
    }

    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Notification Settings Management
    func fetchOrCreateSetting(for type: NotificationType) throws -> NotificationSetting {
        let request: NSFetchRequest<NotificationSetting> = NotificationSetting.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", type.rawValue)
        request.fetchLimit = 1

        if let existing = try viewContext.fetch(request).first {
            return existing
        }

        // Create default setting
        let setting = NotificationSetting(context: viewContext)
        setting.id = UUID()
        setting.type = type.rawValue
        setting.isEnabled = false
        setting.daysBefore = type.defaultDaysBefore
        setting.time = defaultNotificationTime()

        try viewContext.save()
        return setting
    }

    func fetchAllSettings() throws -> [NotificationSetting] {
        let request: NSFetchRequest<NotificationSetting> = NotificationSetting.fetchRequest()
        return try viewContext.fetch(request)
    }

    func updateSetting(_ setting: NotificationSetting, isEnabled: Bool? = nil, daysBefore: Int16? = nil, time: Date? = nil) throws {
        if let isEnabled = isEnabled {
            setting.isEnabled = isEnabled
        }
        if let daysBefore = daysBefore {
            setting.daysBefore = daysBefore
        }
        if let time = time {
            setting.time = time
        }

        if viewContext.hasChanges {
            try viewContext.save()
        }
    }

    private func defaultNotificationTime() -> Date {
        // Default to 9:00 AM
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    // MARK: - Schedule Notifications
    func scheduleAllNotifications(nextPeriodDate: Date?, fertileWindowStart: Date?, ovulationDate: Date?) async {
        guard isAuthorized else { return }

        // Clear existing notifications first
        await cancelAllNotifications()

        do {
            let settings = try fetchAllSettings()

            for setting in settings where setting.isEnabled {
                guard let type = NotificationType(rawValue: setting.type ?? "") else { continue }

                switch type {
                case .periodReminder:
                    if let periodDate = nextPeriodDate {
                        await schedulePeriodReminder(periodDate: periodDate, daysBefore: Int(setting.daysBefore), time: setting.time)
                    }

                case .fertileWindow:
                    if let fertileStart = fertileWindowStart {
                        await scheduleFertileWindowAlert(fertileStart: fertileStart, daysBefore: Int(setting.daysBefore), time: setting.time)
                    }

                case .ovulation:
                    if let ovDate = ovulationDate {
                        await scheduleOvulationReminder(ovulationDate: ovDate, time: setting.time)
                    }

                case .dailyLog:
                    await scheduleDailyLogReminder(time: setting.time)
                }
            }
        } catch {
            print("Error scheduling notifications: \(error)")
        }
    }

    // MARK: - Individual Notification Schedulers
    private func schedulePeriodReminder(periodDate: Date, daysBefore: Int, time: Date?) async {
        let notificationDate = periodDate.adding(days: -daysBefore)
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Period Coming Soon"
        content.body = daysBefore == 1
            ? "Your period is expected tomorrow. Take care of yourself!"
            : "Your period is expected in \(daysBefore) days. Be prepared!"
        content.sound = .default
        content.categoryIdentifier = NotificationType.periodReminder.rawValue

        let trigger = createTrigger(for: notificationDate, time: time)
        let request = UNNotificationRequest(
            identifier: "\(NotificationType.periodReminder.rawValue)_\(periodDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    private func scheduleFertileWindowAlert(fertileStart: Date, daysBefore: Int, time: Date?) async {
        let notificationDate = fertileStart.adding(days: -daysBefore)
        guard notificationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Fertile Window Starting"
        content.body = daysBefore == 0
            ? "Your fertile window begins today."
            : "Your fertile window starts in \(daysBefore) day\(daysBefore == 1 ? "" : "s")."
        content.sound = .default
        content.categoryIdentifier = NotificationType.fertileWindow.rawValue

        let trigger = createTrigger(for: notificationDate, time: time)
        let request = UNNotificationRequest(
            identifier: "\(NotificationType.fertileWindow.rawValue)_\(fertileStart.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    private func scheduleOvulationReminder(ovulationDate: Date, time: Date?) async {
        guard ovulationDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Ovulation Day"
        content.body = "Today is your predicted ovulation day."
        content.sound = .default
        content.categoryIdentifier = NotificationType.ovulation.rawValue

        let trigger = createTrigger(for: ovulationDate, time: time)
        let request = UNNotificationRequest(
            identifier: "\(NotificationType.ovulation.rawValue)_\(ovulationDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    private func scheduleDailyLogReminder(time: Date?) async {
        let content = UNMutableNotificationContent()
        content.title = "Daily Check-in"
        content.body = "How are you feeling today? Take a moment to log your symptoms."
        content.sound = .default
        content.categoryIdentifier = NotificationType.dailyLog.rawValue

        // Schedule recurring daily notification
        var dateComponents = DateComponents()
        if let time = time {
            let components = Calendar.current.dateComponents([.hour, .minute], from: time)
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
        } else {
            dateComponents.hour = 9
            dateComponents.minute = 0
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationType.dailyLog.rawValue,
            content: content,
            trigger: trigger
        )

        try? await notificationCenter.add(request)
    }

    // MARK: - Cancel Notifications
    func cancelAllNotifications() async {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func cancelNotifications(ofType type: NotificationType) async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let idsToRemove = pending
            .filter { $0.identifier.hasPrefix(type.rawValue) }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: idsToRemove)
    }

    // MARK: - Helpers
    private func createTrigger(for date: Date, time: Date?) -> UNCalendarNotificationTrigger {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: date)

        if let time = time {
            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
        } else {
            components.hour = 9
            components.minute = 0
        }

        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }

    // MARK: - Debug
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
}

// MARK: - NotificationSetting Extension
extension NotificationSetting {
    var notificationType: NotificationService.NotificationType? {
        guard let type = type else { return nil }
        return NotificationService.NotificationType(rawValue: type)
    }
}
