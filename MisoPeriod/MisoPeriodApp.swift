//
//  MisoPeriodApp.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-08-05.
//

import SwiftUI
import UserNotifications

@main
struct MisoPeriodApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var notificationManager = NotificationManager.shared

    init() {
        // Register the secure value transformer for symptoms
        SymptomsTransformer.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(notificationManager)
                .onAppear {
                    setupNotifications()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    notificationManager.checkAuthorizationStatus()
                }
        }
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        Task {
            await notificationManager.requestPermission()
        }
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    static let shared = NotificationDelegate()
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        if let notificationType = userInfo["type"] as? String {
            handleNotificationTap(type: notificationType)
        }
        
        completionHandler()
    }
    
    private func handleNotificationTap(type: String) {
        // Handle different notification types
        switch type {
        case "period_reminder":
            // Navigate to add period view
            NotificationCenter.default.post(name: .navigateToAddPeriod, object: nil)
        case "daily_log":
            // Navigate to mood/symptom logging
            NotificationCenter.default.post(name: .navigateToDailyLog, object: nil)
        case "period_end_check":
            // Navigate to edit current period
            NotificationCenter.default.post(name: .navigateToEditPeriod, object: nil)
        default:
            break
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToAddPeriod = Notification.Name("navigateToAddPeriod")
    static let navigateToDailyLog = Notification.Name("navigateToDailyLog")
    static let navigateToEditPeriod = Notification.Name("navigateToEditPeriod")
}
