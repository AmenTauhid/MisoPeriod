import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationService = NotificationService.shared
    @ObservedObject var cycleViewModel: CycleViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var settings: [NotificationService.NotificationType: NotificationSettingState] = [:]
    @State private var isLoading = true
    @State private var showingPermissionAlert = false

    struct NotificationSettingState {
        var isEnabled: Bool
        var daysBefore: Int
        var time: Date
        var coreDataSetting: NotificationSetting?
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                if isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Authorization status
                            authorizationSection

                            // Notification types
                            if notificationService.isAuthorized {
                                notificationTypesSection
                            }

                            Spacer(minLength: 50)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                    .foregroundColor(.misoPrimary)
                }
            }
            .onAppear {
                loadSettings()
            }
            .alert("Enable Notifications", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("To receive reminders, please enable notifications in Settings.")
            }
        }
    }

    // MARK: - Authorization Section
    private var authorizationSection: some View {
        VStack(spacing: 16) {
            if notificationService.isAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.misoSecondary)
                        .font(.title2)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications Enabled")
                            .font(.misoHeadline)
                            .foregroundColor(.misoTextPrimary)
                        Text("You'll receive reminders based on your preferences below")
                            .font(.misoCaption)
                            .foregroundColor(.misoTextSecondary)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.misoSecondary.opacity(0.1))
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.misoTextTertiary)

                    Text("Notifications Disabled")
                        .font(.misoHeadline)
                        .foregroundColor(.misoTextPrimary)

                    Text("Enable notifications to receive period reminders, fertile window alerts, and daily log prompts.")
                        .font(.misoBody)
                        .foregroundColor(.misoTextSecondary)
                        .multilineTextAlignment(.center)

                    Button {
                        requestPermission()
                    } label: {
                        Text("Enable Notifications")
                            .font(.misoHeadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.misoPrimary)
                            )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.misoBgCard)
                )
            }
        }
    }

    // MARK: - Notification Types Section
    private var notificationTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reminder Types")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            ForEach(NotificationService.NotificationType.allCases) { type in
                notificationTypeCard(type)
            }
        }
    }

    private func notificationTypeCard(_ type: NotificationService.NotificationType) -> some View {
        VStack(spacing: 12) {
            // Header with toggle
            HStack {
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(.misoPrimary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.misoHeadline)
                        .foregroundColor(.misoTextPrimary)

                    Text(type.description)
                        .font(.misoCaption)
                        .foregroundColor(.misoTextSecondary)
                }

                Spacer()

                Toggle("", isOn: binding(for: type, keyPath: \.isEnabled))
                    .tint(.misoPrimary)
            }

            // Settings when enabled
            if settings[type]?.isEnabled == true {
                Divider()

                // Days before (not for daily log)
                if type != .dailyLog && type != .ovulation {
                    HStack {
                        Text("Days before")
                            .font(.misoSubheadline)
                            .foregroundColor(.misoTextSecondary)

                        Spacer()

                        Picker("Days", selection: binding(for: type, keyPath: \.daysBefore)) {
                            ForEach(0..<8) { day in
                                Text(day == 0 ? "Same day" : "\(day) day\(day == 1 ? "" : "s")").tag(day)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.misoPrimary)
                    }
                }

                // Time picker
                HStack {
                    Text("Notification time")
                        .font(.misoSubheadline)
                        .foregroundColor(.misoTextSecondary)

                    Spacer()

                    DatePicker("", selection: binding(for: type, keyPath: \.time), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(.misoPrimary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    // MARK: - Bindings
    private func binding<T>(for type: NotificationService.NotificationType, keyPath: WritableKeyPath<NotificationSettingState, T>) -> Binding<T> {
        Binding(
            get: { settings[type]?[keyPath: keyPath] ?? defaultValue(for: keyPath, type: type) },
            set: { settings[type]?[keyPath: keyPath] = $0 }
        )
    }

    private func defaultValue<T>(for keyPath: WritableKeyPath<NotificationSettingState, T>, type: NotificationService.NotificationType) -> T {
        if keyPath == \NotificationSettingState.isEnabled {
            return false as! T
        } else if keyPath == \NotificationSettingState.daysBefore {
            return Int(type.defaultDaysBefore) as! T
        } else {
            return Date() as! T
        }
    }

    // MARK: - Actions
    private func loadSettings() {
        isLoading = true

        Task {
            var loadedSettings: [NotificationService.NotificationType: NotificationSettingState] = [:]

            for type in NotificationService.NotificationType.allCases {
                do {
                    let setting = try notificationService.fetchOrCreateSetting(for: type)
                    loadedSettings[type] = NotificationSettingState(
                        isEnabled: setting.isEnabled,
                        daysBefore: Int(setting.daysBefore),
                        time: setting.time ?? Date(),
                        coreDataSetting: setting
                    )
                } catch {
                    loadedSettings[type] = NotificationSettingState(
                        isEnabled: false,
                        daysBefore: Int(type.defaultDaysBefore),
                        time: Date(),
                        coreDataSetting: nil
                    )
                }
            }

            await MainActor.run {
                settings = loadedSettings
                isLoading = false
            }
        }
    }

    private func requestPermission() {
        Task {
            let granted = await notificationService.requestAuthorization()
            if !granted {
                await MainActor.run {
                    showingPermissionAlert = true
                }
            }
        }
    }

    private func saveAndDismiss() {
        Task {
            // Save all settings to CoreData
            for (type, state) in settings {
                if let setting = state.coreDataSetting {
                    do {
                        try notificationService.updateSetting(
                            setting,
                            isEnabled: state.isEnabled,
                            daysBefore: Int16(state.daysBefore),
                            time: state.time
                        )
                    } catch {
                        print("Error saving notification setting: \(error)")
                    }
                }
            }

            // Reschedule notifications
            await notificationService.scheduleAllNotifications(
                nextPeriodDate: cycleViewModel.nextPeriodDate,
                fertileWindowStart: cycleViewModel.fertileWindowDates?.start,
                ovulationDate: cycleViewModel.currentCycle?.ovulationDate
            )

            await MainActor.run {
                dismiss()
            }
        }
    }
}

#Preview {
    NotificationSettingsView(cycleViewModel: CycleViewModel.preview)
}
