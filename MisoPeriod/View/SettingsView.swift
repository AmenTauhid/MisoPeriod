//
//  SettingsView.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-08-05.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject var notificationManager: NotificationManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 3
    @AppStorage("ovulationReminders") private var ovulationReminders = true
    @AppStorage("dailyLogReminders") private var dailyLogReminders = false
    @AppStorage("dailyLogTime") private var dailyLogTime = 20
    @AppStorage("periodEndReminders") private var periodEndReminders = true
    @AppStorage("averageCycleLength") private var averageCycleLength = 28
    @AppStorage("averagePeriodLength") private var averagePeriodLength = 5
    @AppStorage("enableHealthTips") private var enableHealthTips = true
    
    @State private var showingExportSheet = false
    @State private var showingAbout = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PeriodEntry.startDate, ascending: false)],
        animation: .default)
    private var periods: FetchedResults<PeriodEntry>
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("\(KawaiiEmojis.sparkles) Settings")
                            .font(KawaiiTheme.titleFont)
                            .foregroundColor(KawaiiTheme.deepPink)
                        
                        Text("Customize your kawaii experience")
                            .font(KawaiiTheme.bodyFont)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Notifications Section
                    SettingsSection(title: "Notifications \(KawaiiEmojis.notification)", backgroundColor: KawaiiTheme.lightPink) {
                        VStack(spacing: 16) {
                            // Notification Permission Status
                            HStack {
                                Image(systemName: notificationManager.isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(notificationManager.isAuthorized ? .green : .orange)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Notification Permission")
                                        .font(KawaiiTheme.bodyFont)
                                        .foregroundColor(.primary)
                                    Text(notificationManager.isAuthorized ? "Enabled" : "Tap to enable notifications")
                                        .font(KawaiiTheme.captionFont)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if !notificationManager.isAuthorized {
                                    Button("Enable") {
                                        Task {
                                            await notificationManager.requestPermission()
                                        }
                                    }
                                    .font(KawaiiTheme.captionFont)
                                    .foregroundColor(KawaiiTheme.deepPink)
                                }
                            }
                            .padding(.vertical, 8)
                            
                            if notificationManager.isAuthorized {
                                Divider()
                                
                                SettingsToggleRow(
                                    title: "Period Reminders",
                                    description: "Get notified before your next period",
                                    isOn: $reminderEnabled
                                )
                                .onChange(of: reminderEnabled) { _ in
                                    updateNotifications()
                                }
                                
                                if reminderEnabled {
                                    SettingsStepperRow(
                                        title: "Remind me",
                                        value: $reminderDaysBefore,
                                        range: 1...7,
                                        suffix: "days before"
                                    )
                                    .onChange(of: reminderDaysBefore) { _ in
                                        updateNotifications()
                                    }
                                }
                                
                                Divider()
                                
                                SettingsToggleRow(
                                    title: "Ovulation Reminders",
                                    description: "Get notified during fertile window",
                                    isOn: $ovulationReminders
                                )
                                .onChange(of: ovulationReminders) { _ in
                                    updateNotifications()
                                }
                                
                                Divider()
                                
                                SettingsToggleRow(
                                    title: "Daily Log Reminders",
                                    description: "Remind me to log mood and symptoms",
                                    isOn: $dailyLogReminders
                                )
                                .onChange(of: dailyLogReminders) { enabled in
                                    if enabled {
                                        notificationManager.scheduleDailyLogReminder(at: dailyLogTime)
                                    } else {
                                        notificationManager.cancelNotifications(withIdentifier: "daily_log")
                                    }
                                }
                                
                                if dailyLogReminders {
                                    SettingsStepperRow(
                                        title: "Daily reminder time",
                                        value: $dailyLogTime,
                                        range: 6...23,
                                        suffix: ":00",
                                        formatter: { hour in
                                            let formatter = DateFormatter()
                                            formatter.dateFormat = "h a"
                                            let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
                                            return formatter.string(from: date)
                                        }
                                    )
                                    .onChange(of: dailyLogTime) { _ in
                                        if dailyLogReminders {
                                            notificationManager.scheduleDailyLogReminder(at: dailyLogTime)
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                SettingsToggleRow(
                                    title: "Period End Check",
                                    description: "Remind me to update when period ends",
                                    isOn: $periodEndReminders
                                )
                            }
                        }
                    }
                    
                    // Cycle Settings
                    SettingsSection(title: "Cycle Settings \(KawaiiEmojis.calendar)", backgroundColor: KawaiiTheme.lightLavender) {
                        VStack(spacing: 16) {
                            SettingsStepperRow(
                                title: "Average Cycle Length",
                                value: $averageCycleLength,
                                range: 21...45,
                                suffix: "days"
                            )
                            .onChange(of: averageCycleLength) { _ in
                                updateNotifications()
                            }
                            
                            SettingsStepperRow(
                                title: "Average Period Length",
                                value: $averagePeriodLength,
                                range: 1...10,
                                suffix: "days"
                            )
                            .onChange(of: averagePeriodLength) { _ in
                                updateNotifications()
                            }
                        }
                    }
                    
                    // App Preferences
                    SettingsSection(title: "App Preferences \(KawaiiEmojis.rainbow)", backgroundColor: KawaiiTheme.lightPeach) {
                        VStack(spacing: 16) {
                            SettingsToggleRow(
                                title: "Health Tips",
                                description: "Show daily health and wellness tips",
                                isOn: $enableHealthTips
                            )
                        }
                    }
                    
                    // Data Management
                    SettingsSection(title: "Data Management \(KawaiiEmojis.butterfly)", backgroundColor: KawaiiTheme.lightMint) {
                        VStack(spacing: 12) {
                            Button(action: { showingExportSheet = true }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(KawaiiTheme.deepPink)
                                    
                                    Text("Export Data")
                                        .font(KawaiiTheme.bodyFont)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                            
                            Button(action: openSystemNotificationSettings) {
                                HStack {
                                    Image(systemName: "gear")
                                        .foregroundColor(KawaiiTheme.deepPink)
                                    
                                    Text("System Notification Settings")
                                        .font(KawaiiTheme.bodyFont)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // About Section
                    SettingsSection(title: "About \(KawaiiEmojis.cherry)", backgroundColor: KawaiiTheme.softGray) {
                        VStack(spacing: 12) {
                            Button(action: { showingAbout = true }) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(KawaiiTheme.deepPink)
                                    
                                    Text("About MisoPeriod")
                                        .font(KawaiiTheme.bodyFont)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                            
                            HStack {
                                Text("Version 1.0.0")
                                    .font(KawaiiTheme.captionFont)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("Made with \(KawaiiEmojis.heart)")
                                    .font(KawaiiTheme.captionFont)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [KawaiiTheme.cream, KawaiiTheme.lightPink.opacity(0.2)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataSheet()
        }
        .sheet(isPresented: $showingAbout) {
            AboutSheet()
        }
        .onAppear {
            notificationManager.checkAuthorizationStatus()
        }
        .onChange(of: notificationManager.isAuthorized) { authorized in
            if authorized {
                updateNotifications()
            }
        }
    }
    
    private func updateNotifications() {
        guard notificationManager.isAuthorized && reminderEnabled else { return }
        
        let periodsArray = Array(periods)
        notificationManager.updateNotificationsBasedOnData(
            periods: periodsArray,
            cycleLength: averageCycleLength,
            periodLength: averagePeriodLength
        )
    }
    
    private func openSystemNotificationSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// Enhanced Settings Components
struct SettingsSection<Content: View>: View {
    let title: String
    let backgroundColor: Color
    let content: Content
    
    init(title: String, backgroundColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.content = content()
    }
    
    var body: some View {
        KawaiiCard(backgroundColor: backgroundColor) {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(KawaiiTheme.headlineFont)
                    .foregroundColor(KawaiiTheme.deepPink)
                
                content
            }
        }
        .padding(.horizontal)
    }
}

struct SettingsToggleRow: View {
    let title: String
    let description: String?
    @Binding var isOn: Bool
    
    init(title: String, description: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.description = description
        self._isOn = isOn
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(KawaiiTheme.bodyFont)
                        .foregroundColor(.primary)
                    if let description = description {
                        Text(description)
                            .font(KawaiiTheme.captionFont)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .toggleStyle(SwitchToggleStyle(tint: KawaiiTheme.primaryPink))
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsStepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String
    let formatter: ((Int) -> String)?
    
    init(title: String, value: Binding<Int>, range: ClosedRange<Int>, suffix: String, formatter: ((Int) -> String)? = nil) {
        self.title = title
        self._value = value
        self.range = range
        self.suffix = suffix
        self.formatter = formatter
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(KawaiiTheme.bodyFont)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    if value > range.lowerBound {
                        value -= 1
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(value > range.lowerBound ? KawaiiTheme.primaryPink : .gray)
                        .font(.title3)
                }
                .disabled(value <= range.lowerBound)
                
                Text(formatter?(value) ?? "\(value) \(suffix)")
                    .font(KawaiiTheme.bodyFont)
                    .foregroundColor(KawaiiTheme.deepPink)
                    .fontWeight(.semibold)
                    .frame(minWidth: 80)
                
                Button(action: {
                    if value < range.upperBound {
                        value += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(value < range.upperBound ? KawaiiTheme.primaryPink : .gray)
                        .font(.title3)
                }
                .disabled(value >= range.upperBound)
            }
        }
        .padding(.vertical, 4)
    }
}

// Placeholder sheets
struct ExportDataSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Export functionality coming soon!")
                    .font(KawaiiTheme.bodyFont)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct AboutSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("\(KawaiiEmojis.sparkles) MisoPeriod")
                        .font(KawaiiTheme.titleFont)
                        .foregroundColor(KawaiiTheme.deepPink)
                    
                    Text("Your kawaii period tracking companion")
                        .font(KawaiiTheme.bodyFont)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Features:")
                            .font(KawaiiTheme.headlineFont)
                            .foregroundColor(KawaiiTheme.deepPink)
                        
                        FeatureRow(icon: KawaiiEmojis.calendar, text: "Track your periods and cycles")
                        FeatureRow(icon: KawaiiEmojis.heart, text: "Log moods and symptoms")
                        FeatureRow(icon: KawaiiEmojis.notification, text: "Smart notifications")
                        FeatureRow(icon: KawaiiEmojis.rainbow, text: "Beautiful kawaii design")
                    }
                    .padding()
                    .background(KawaiiTheme.lightPink.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: KawaiiTheme.cardCornerRadius))
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Text(icon)
                .font(.title3)
            Text(text)
                .font(KawaiiTheme.bodyFont)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(NotificationManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}