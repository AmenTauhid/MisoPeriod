//
//  SettingsView.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-08-05.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("reminderEnabled") private var reminderEnabled = true
    @AppStorage("reminderDaysBefore") private var reminderDaysBefore = 3
    @AppStorage("averageCycleLength") private var averageCycleLength = 28
    @AppStorage("averagePeriodLength") private var averagePeriodLength = 5
    @AppStorage("enableHealthTips") private var enableHealthTips = true
    
    @State private var showingExportSheet = false
    @State private var showingAbout = false
    
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
                    SettingsSection(title: "Notifications \(KawaiiEmojis.heart)", backgroundColor: KawaiiTheme.lightPink) {
                        VStack(spacing: 16) {
                            SettingsToggleRow(
                                title: "Period Reminders",
                                description: "Get notified before your next period",
                                isOn: $reminderEnabled
                            )
                            
                            if reminderEnabled {
                                SettingsStepperRow(
                                    title: "Remind me",
                                    value: $reminderDaysBefore,
                                    range: 1...7,
                                    suffix: "days before"
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
                            
                            SettingsStepperRow(
                                title: "Average Period Length",
                                value: $averagePeriodLength,
                                range: 1...10,
                                suffix: "days"
                            )
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
                            
                            Button(action: { }) {
                                HStack {
                                    Image(systemName: "icloud")
                                        .foregroundColor(KawaiiTheme.deepPink)
                                    
                                    Text("iCloud Sync")
                                        .font(KawaiiTheme.bodyFont)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("Coming Soon")
                                        .font(KawaiiTheme.captionFont)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .disabled(true)
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
                            
                            Button(action: openPrivacyPolicy) {
                                HStack {
                                    Image(systemName: "hand.raised")
                                        .foregroundColor(KawaiiTheme.deepPink)
                                    
                                    Text("Privacy Policy")
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
    }
    
    private func openPrivacyPolicy() {
        // TODO: Open privacy policy URL
    }
}

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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
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
}

struct SettingsStepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String
    
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
                }
                .disabled(value <= range.lowerBound)
                
                Text("\(value) \(suffix)")
                    .font(KawaiiTheme.bodyFont)
                    .foregroundColor(.primary)
                    .frame(minWidth: 80)
                
                Button(action: { 
                    if value < range.upperBound {
                        value += 1
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(value < range.upperBound ? KawaiiTheme.primaryPink : .gray)
                }
                .disabled(value >= range.upperBound)
            }
        }
    }
}

struct ExportDataSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("\(KawaiiEmojis.sparkles) Export Your Data")
                    .font(KawaiiTheme.titleFont)
                    .foregroundColor(KawaiiTheme.deepPink)
                
                Text("Export your period tracking data as a CSV file to use with other apps or for backup purposes.")
                    .font(KawaiiTheme.bodyFont)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button(action: exportData) {
                    Text("Export as CSV")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(KawaiiButtonStyle())
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(KawaiiTheme.deepPink)
                }
            }
        }
    }
    
    private func exportData() {
        // TODO: Implement CSV export
        presentationMode.wrappedValue.dismiss()
    }
}

struct AboutSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("\(KawaiiEmojis.cherry) MisoPeriod")
                        .font(KawaiiTheme.titleFont)
                        .foregroundColor(KawaiiTheme.deepPink)
                    
                    Text("A kawaii period tracker designed to make cycle tracking delightful and empowering.")
                        .font(KawaiiTheme.bodyFont)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    KawaiiCard(backgroundColor: KawaiiTheme.lightPink) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Features \(KawaiiEmojis.sparkles)")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            
                            FeatureRow(emoji: KawaiiEmojis.period, text: "Easy period logging")
                            FeatureRow(emoji: KawaiiEmojis.calendar, text: "Beautiful calendar view")
                            FeatureRow(emoji: KawaiiEmojis.heart, text: "Mood & symptom tracking")
                            FeatureRow(emoji: KawaiiEmojis.rainbow, text: "Cycle insights & predictions")
                            FeatureRow(emoji: KawaiiEmojis.butterfly, text: "Privacy-focused design")
                        }
                    }
                    
                    Text("Your data stays on your device. We believe your health information should be private and secure.")
                        .font(KawaiiTheme.captionFont)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(KawaiiTheme.deepPink)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let emoji: String
    let text: String
    
    var body: some View {
        HStack {
            Text(emoji)
            Text(text)
                .font(KawaiiTheme.bodyFont)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}

#Preview {
    SettingsView()
}