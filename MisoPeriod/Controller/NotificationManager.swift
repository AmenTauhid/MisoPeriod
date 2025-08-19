//
//  NotificationManager.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-08-05.
//

import Foundation
import UserNotifications
import CoreData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Schedule Notifications
    func schedulePeriodReminders(
        nextPeriodDate: Date,
        daysBeforeArray: [Int] = [3, 1],
        cycleLength: Int = 28
    ) {
        guard isAuthorized else { return }
        
        // Clear existing period reminders
        cancelNotifications(withIdentifier: "period_reminder")
        
        for daysBefore in daysBeforeArray {
            let reminderDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: nextPeriodDate) ?? nextPeriodDate
            
            // Don't schedule notifications for past dates
            guard reminderDate > Date() else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "\(KawaiiEmojis.heart) Period Reminder"
            
            if daysBefore == 1 {
                content.body = "Your period might start tomorrow. Time to prepare! \(KawaiiEmojis.sparkles)"
            } else {
                content.body = "Your period is expected in \(daysBefore) days. \(KawaiiEmojis.moon)"
            }
            
            content.sound = .default
            content.badge = 1
            content.userInfo = ["type": "period_reminder", "daysBefore": daysBefore]
            
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "period_reminder_\(daysBefore)_\(reminderDate.timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule period reminder: \(error)")
                }
            }
        }
    }
    
    func scheduleOvulationReminder(ovulationDate: Date) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(KawaiiEmojis.butterfly) Fertility Window"
        content.body = "You're entering your fertile window. Perfect time for tracking! \(KawaiiEmojis.sparkles)"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "ovulation_reminder"]
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: ovulationDate)
        var components = dateComponents
        components.hour = 9 // 9 AM
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "ovulation_reminder_\(ovulationDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule ovulation reminder: \(error)")
            }
        }
    }
    
    func scheduleDailyLogReminder(at hour: Int = 20) {
        guard isAuthorized else { return }
        
        cancelNotifications(withIdentifier: "daily_log")
        
        let content = UNMutableNotificationContent()
        content.title = "\(KawaiiEmojis.moon) Daily Check-in"
        content.body = "How are you feeling today? Don't forget to log your mood and symptoms! \(KawaiiEmojis.heart)"
        content.sound = .default
        content.userInfo = ["type": "daily_log"]
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_log_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule daily log reminder: \(error)")
            }
        }
    }
    
    func scheduleEndPeriodReminder(startDate: Date, averagePeriodLength: Int) {
        guard isAuthorized else { return }
        
        let endDate = Calendar.current.date(byAdding: .day, value: averagePeriodLength, to: startDate) ?? startDate
        
        let content = UNMutableNotificationContent()
        content.title = "\(KawaiiEmojis.sparkles) Period Check"
        content.body = "Has your period ended? Tap to update your tracking! \(KawaiiEmojis.heart)"
        content.sound = .default
        content.badge = 1
        content.userInfo = ["type": "period_end_check"]
        
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
        var components = dateComponents
        components.hour = 10 // 10 AM
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "period_end_\(startDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule period end reminder: \(error)")
            }
        }
    }
    
    // MARK: - Cancel Notifications
    func cancelNotifications(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToCancel = requests
                .filter { $0.identifier.contains(identifier) }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToCancel)
        }
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Helper Methods
    func updateNotificationsBasedOnData(periods: [PeriodEntry], cycleLength: Int, periodLength: Int) {
        guard let lastPeriod = periods.first?.startDate else { return }
        
        // Calculate next period date
        let nextPeriodDate = Calendar.current.date(byAdding: .day, value: cycleLength, to: lastPeriod) ?? Date()
        
        // Schedule period reminders
        schedulePeriodReminders(nextPeriodDate: nextPeriodDate, cycleLength: cycleLength)
        
        // Calculate and schedule ovulation reminder (typically 14 days before next period)
        let ovulationDate = Calendar.current.date(byAdding: .day, value: -(cycleLength - 14), to: nextPeriodDate) ?? Date()
        if ovulationDate > Date() {
            scheduleOvulationReminder(ovulationDate: ovulationDate)
        }
    }
}

// MARK: - Kawaii Emojis Extension
extension KawaiiEmojis {
    static let notification = "🔔"
    static let reminder = "⏰"
    static let bell = "🛎️"
}