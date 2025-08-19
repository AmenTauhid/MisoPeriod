//
//  PeriodTrackerView.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-08-05.
//

import SwiftUI
import CoreData

struct PeriodTrackerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var notificationManager: NotificationManager
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PeriodEntry.startDate, ascending: false)],
        animation: .default)
    private var periods: FetchedResults<PeriodEntry>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CycleEntry.date, ascending: false)],
        animation: .default)
    private var cycles: FetchedResults<CycleEntry>
    
    @State private var showingAddPeriod = false
    @State private var showingMoodLog = false
    @State private var showingSymptomLog = false
    @State private var selectedTab = 0
    @State private var editingPeriod: PeriodEntry?
    
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(red: 1.0, green: 0.98, blue: 0.94)) // KawaiiTheme.cream
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemPink
        appearance.inlineLayoutAppearance.normal.iconColor = UIColor.systemPink
        appearance.compactInlineLayoutAppearance.normal.iconColor = UIColor.systemPink
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Home Tab
                HomeView(
                    periods: periods,
                    cycles: cycles,
                    onAddPeriod: { showingAddPeriod = true },
                    onMoodLog: { showingMoodLog = true },
                    onSymptomLog: { showingSymptomLog = true },
                    onEditPeriod: { period in editingPeriod = period; showingAddPeriod = true }
                )
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
                
                // Calendar Tab
                CalendarView(periods: periods, cycles: cycles)
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Calendar")
                    }
                    .tag(1)
                
                // Settings Tab (Insights removed per request)
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(2)
            }
            .accentColor(KawaiiTheme.deepPink)
        }
        .sheet(isPresented: $showingAddPeriod, onDismiss: { editingPeriod = nil }) {
            AddPeriodView(periodToEdit: editingPeriod)
        }
        .sheet(isPresented: $showingMoodLog) {
            MoodLogView()
        }
        .sheet(isPresented: $showingSymptomLog) {
            SymptomLogView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToAddPeriod)) { _ in
            showingAddPeriod = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToDailyLog)) { _ in
            showingMoodLog = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToEditPeriod)) { _ in
            if let currentPeriod = periods.first(where: { $0.endDate == nil }) {
                editingPeriod = currentPeriod
                showingAddPeriod = true
            } else {
                showingAddPeriod = true
            }
        }
    }
}

struct HomeView: View {
    let periods: FetchedResults<PeriodEntry>
    let cycles: FetchedResults<CycleEntry>
    let onAddPeriod: () -> Void
    let onMoodLog: () -> Void
    let onSymptomLog: () -> Void
    let onEditPeriod: (PeriodEntry) -> Void
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddPeriodLocal = false
    
    private var currentCycleDay: Int {
        guard let lastPeriod = periods.first, let start = lastPeriod.startDate else { return 1 }
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        let cycleDay = max(1, daysSinceLastPeriod + 1)
        // Clamp the cycle day to the average cycle length to prevent out-of-bounds errors
        return min(cycleDay, averageCycleLength > 0 ? averageCycleLength : 1)
    }
    
    private var averageCycleLength: Int { calculateAverageCycleLength() }
    private var averagePeriodLength: Double { calculateAveragePeriodLength() }
    
    private var daysUntilNextPeriod: Int {
        guard let lastPeriod = periods.first, let start = lastPeriod.startDate else { return averageCycleLength }
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
        return max(0, averageCycleLength - daysSinceLastPeriod)
    }
    
    private func calculateAverageCycleLength() -> Int {
        guard periods.count >= 2 else { return 28 }
        let sorted = periods.compactMap{ $0.startDate }.sorted(by: >)
        var diffs: [Int] = []
        for i in 0..<(min(sorted.count - 1, 6)) { // last up to 6 intervals
            let daysBetween = Calendar.current.dateComponents([.day], from: sorted[i + 1], to: sorted[i]).day ?? 28
            diffs.append(daysBetween)
        }
        return diffs.isEmpty ? 28 : diffs.reduce(0,+)/diffs.count
    }
    
    private func calculateAveragePeriodLength() -> Double {
        let durations = periods.compactMap { period -> Int? in
            guard let start = period.startDate else { return nil }
            if let end = period.endDate { return (Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0) + 1 }
            return nil
        }
        guard !durations.isEmpty else { return 5.0 }
        return Double(durations.reduce(0,+)) / Double(durations.count)
    }
    
    private func delete(_ period: PeriodEntry) {
        viewContext.delete(period)
        try? viewContext.save()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Hello Beautiful ✨")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(KawaiiTheme.deepPink)
                        Text(greetingSubtitle)
                            .font(KawaiiTheme.bodyFont)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 4)
                
                // Hero Cycle Card (enhanced visual)
                heroCycleCard
                    .padding(.horizontal)
                
                // Removed onboardingCard per request
                
                if !periods.isEmpty { statsSection }
                
                // Quick Actions Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Track Today")
                        .font(KawaiiTheme.headlineFont)
                        .foregroundColor(KawaiiTheme.deepPink)
                        .padding(.horizontal)
                    VStack(spacing: 14) {
                        QuickActionCard(style: .filled(color: KawaiiTheme.primaryPink), title: "Log Period", subtitle: "Start or update a cycle", emoji: KawaiiEmojis.period, action: onAddPeriod)
                        QuickActionCard(style: .filled(color: KawaiiTheme.lavender), title: "Add Mood", subtitle: "Capture how you feel", emoji: KawaiiEmojis.heart, action: onMoodLog)
                        QuickActionCard(style: .filled(color: KawaiiTheme.peach), title: "Symptoms", subtitle: "Log body changes", emoji: KawaiiEmojis.butterfly, action: onSymptomLog)
                    }
                    .padding(.horizontal)
                }
                
                // Recent Periods Section
                if !periods.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Periods")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            Spacer()
                        }
                        .padding(.horizontal)
                        LazyVStack(spacing: 10) {
                            ForEach(Array(periods.prefix(5)), id: \.objectID) { period in
                                Button { onEditPeriod(period) } label: { PeriodRowView(period: period) }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button(role: .destructive) { delete(period) } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                Spacer(minLength: 80)
            }
        }
        .background(
            LinearGradient(
                colors: [KawaiiTheme.cream, KawaiiTheme.lightPink.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarHidden(true)
    }
    
    // MARK: - Subviews / Computed Sections
    private var greetingSubtitle: String {
        if daysUntilNextPeriod == 0 { return "You might start today – take it easy 💕" }
        if daysUntilNextPeriod <= 3 { return "Next period in \(daysUntilNextPeriod) day(s)" }
        return "Cycle day \(currentCycleDay)"
    }
    
    private var heroCycleCard: some View {
        KawaiiCard(backgroundColor: .clear) {
            ZStack {
                LinearGradient(colors: [KawaiiTheme.lightPink, KawaiiTheme.softPink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: KawaiiTheme.cardCornerRadius))
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Cycle Day")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(KawaiiTheme.deepPink)
                        Spacer()
                        Text("\(currentCycleDay)")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(KawaiiTheme.deepPink)
                    }
                    ProgressView(value: Double(currentCycleDay), total: Double(averageCycleLength))
                        .progressViewStyle(LinearProgressViewStyle(tint: KawaiiTheme.primaryPink))
                        .scaleEffect(y: 2)
                        .accessibilityLabel("Cycle progress")
                        .accessibilityValue("Day \(currentCycleDay) of \(averageCycleLength)")
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Avg Cycle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(averageCycleLength) days")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(KawaiiTheme.deepPink)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Next Period")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(daysUntilNextPeriod == 0 ? "Due" : "In \(daysUntilNextPeriod)d")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(KawaiiTheme.deepPink)
                        }
                    }
                }
                .padding(20)
            }
            .shadow(color: KawaiiTheme.primaryPink.opacity(0.25), radius: 10, x: 0, y: 4)
        }
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Cycle Stats")
                    .font(KawaiiTheme.headlineFont)
                    .foregroundColor(KawaiiTheme.deepPink)
                Spacer()
            }
            .padding(.horizontal)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                StatsCard(title: "Average Cycle", value: "\(averageCycleLength) days", emoji: KawaiiEmojis.calendar, color: KawaiiTheme.primaryPink)
                StatsCard(title: "Period Length", value: String(format: "%.1f days", averagePeriodLength), emoji: KawaiiEmojis.heart, color: KawaiiTheme.lavender)
                StatsCard(title: "Total Tracked", value: "\(periods.count) periods", emoji: KawaiiEmojis.rainbow, color: KawaiiTheme.peach)
                let regularity: String = {
                    let diffs = periods.compactMap{ $0.startDate }.sorted(by: >).enumerated().compactMap { idx, date -> Int? in
                        guard idx < periods.count - 1, let next = periods.compactMap({ $0.startDate }).sorted(by: >).dropFirst(idx+1).first else { return nil }
                        return Calendar.current.dateComponents([.day], from: next, to: date).day
                    }
                    guard diffs.count >= 2 else { return "Need more data" }
                    let maxDiff = (diffs.max() ?? 0) - (diffs.min() ?? 0)
                    if maxDiff <= 3 { return "Very Regular \(KawaiiEmojis.sparkles)" }
                    if maxDiff <= 7 { return "Fairly Regular \(KawaiiEmojis.heart)" }
                    return "Irregular \(KawaiiEmojis.butterfly)" }()
                StatsCard(title: "Regularity", value: regularity, emoji: KawaiiEmojis.sparkles, color: KawaiiTheme.mintGreen)
            }
            .padding(.horizontal)
        }
    }
}

struct QuickActionCard: View {
    enum Style { case filled(color: Color) }
    let style: Style
    let title: String
    let subtitle: String?
    let emoji: String
    let action: () -> Void
    
    init(style: Style = .filled(color: KawaiiTheme.primaryPink), title: String, subtitle: String? = nil, emoji: String, action: @escaping () -> Void) {
        self.style = style
        self.title = title
        self.subtitle = subtitle
        self.emoji = emoji
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.system(size: 34))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.9))
                            .lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: shadowColor.opacity(0.25), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
    }
    
    private var background: some View {
        switch style {
        case .filled(let color):
            return LinearGradient(colors: [color, color.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .blur(radius: 0)
        }
    }
    private var shadowColor: Color {
        switch style { case .filled(let color): return color }
    }
    private var accessibilityLabel: String { subtitle == nil ? title : "\(title), \(subtitle!)" }
}

struct PeriodRowView: View {
    let period: PeriodEntry
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var durationText: String {
        guard let startDate = period.startDate else { return "" }
        
        if let endDate = period.endDate {
            let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            return "\(days + 1) days"
        } else {
            return "Ongoing"
        }
    }
    
    var body: some View {
        KawaiiCard(backgroundColor: KawaiiTheme.softGray) {
            HStack {
                Circle()
                    .fill(KawaiiTheme.primaryPink)
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(period.startDate!, formatter: dateFormatter)
                        .font(KawaiiTheme.bodyFont)
                        .foregroundColor(.primary)
                    
                    Text(durationText)
                        .font(KawaiiTheme.captionFont)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let flow = period.flow {
                    Text(flow)
                        .font(KawaiiTheme.captionFont)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(KawaiiTheme.primaryPink.opacity(0.2))
                        .clipShape(Capsule())
                        .foregroundColor(KawaiiTheme.deepPink)
                }
            }
        }
    }
}

#Preview {
    PeriodTrackerView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
