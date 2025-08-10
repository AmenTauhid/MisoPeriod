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
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PeriodEntry.startDate, ascending: false)],
        animation: .default)
    private var periods: FetchedResults<PeriodEntry>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CycleEntry.date, ascending: false)],
        animation: .default)
    private var cycles: FetchedResults<CycleEntry>
    
    @State private var showingAddPeriod = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Home Tab
                HomeView(periods: periods, cycles: cycles)
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
                
                // Insights Tab
                InsightsView(periods: periods, cycles: cycles)
                    .tabItem {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Insights")
                    }
                    .tag(2)
                
                // Settings Tab
                SettingsView()
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(3)
            }
            .accentColor(KawaiiTheme.deepPink)
        }
        .sheet(isPresented: $showingAddPeriod) {
            AddPeriodView()
        }
    }
}

struct HomeView: View {
    let periods: FetchedResults<PeriodEntry>
    let cycles: FetchedResults<CycleEntry>
    @State private var showingAddPeriod = false
    
    private var currentCycleDay: Int {
        guard let lastPeriod = periods.first else { return 1 }
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod.startDate!, to: Date()).day ?? 1
        return daysSinceLastPeriod + 1
    }
    
    private var daysUntilNextPeriod: Int {
        guard let lastPeriod = periods.first else { return 28 }
        let daysSinceLastPeriod = Calendar.current.dateComponents([.day], from: lastPeriod.startDate!, to: Date()).day ?? 0
        let averageCycleLength = calculateAverageCycleLength()
        return max(0, averageCycleLength - daysSinceLastPeriod)
    }
    
    private func calculateAverageCycleLength() -> Int {
        guard periods.count >= 2 else { return 28 }
        
        let sortedPeriods = periods.sorted { $0.startDate! > $1.startDate! }
        var totalDays = 0
        var cycleCount = 0
        
        for i in 0..<min(sortedPeriods.count - 1, 6) { // Use last 6 cycles max
            let daysBetween = Calendar.current.dateComponents([.day], 
                from: sortedPeriods[i + 1].startDate!, 
                to: sortedPeriods[i].startDate!).day ?? 28
            totalDays += daysBetween
            cycleCount += 1
        }
        
        return cycleCount > 0 ? totalDays / cycleCount : 28
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Hello Beautiful! \(KawaiiEmojis.sparkles)")
                            .font(KawaiiTheme.titleFont)
                            .foregroundColor(KawaiiTheme.deepPink)
                        
                        Text("How are you feeling today?")
                            .font(KawaiiTheme.bodyFont)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { showingAddPeriod = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(KawaiiTheme.primaryPink)
                    }
                }
                .padding(.horizontal)
                
                // Cycle Status Card
                KawaiiCard(backgroundColor: KawaiiTheme.lightPink) {
                    VStack(spacing: 12) {
                        HStack {
                            Text("\(KawaiiEmojis.flower) Cycle Day")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            
                            Spacer()
                            
                            Text("\(currentCycleDay)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(KawaiiTheme.deepPink)
                        }
                        
                        ProgressView(value: Double(currentCycleDay), total: Double(calculateAverageCycleLength()))
                            .progressViewStyle(LinearProgressViewStyle(tint: KawaiiTheme.primaryPink))
                            .scaleEffect(y: 2)
                        
                        HStack {
                            Text("Next period in")
                                .font(KawaiiTheme.bodyFont)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(daysUntilNextPeriod) days")
                                .font(KawaiiTheme.bodyFont)
                                .fontWeight(.semibold)
                                .foregroundColor(KawaiiTheme.deepPink)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Quick Actions
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    QuickActionCard(
                        title: "Log Period",
                        emoji: KawaiiEmojis.period,
                        color: KawaiiTheme.primaryPink
                    ) {
                        showingAddPeriod = true
                    }
                    
                    QuickActionCard(
                        title: "Add Mood",
                        emoji: KawaiiEmojis.heart,
                        color: KawaiiTheme.lavender
                    ) {
                        // TODO: Add mood tracking
                    }
                    
                    QuickActionCard(
                        title: "Symptoms",
                        emoji: KawaiiEmojis.butterfly,
                        color: KawaiiTheme.peach
                    ) {
                        // TODO: Add symptom tracking
                    }
                    
                    QuickActionCard(
                        title: "Notes",
                        emoji: KawaiiEmojis.cherry,
                        color: KawaiiTheme.mintGreen
                    ) {
                        // TODO: Add notes
                    }
                }
                .padding(.horizontal)
                
                // Recent Periods
                if !periods.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("\(KawaiiEmojis.calendar) Recent Periods")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(Array(periods.prefix(3)), id: \.objectID) { period in
                                PeriodRowView(period: period)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .background(
            LinearGradient(
                colors: [KawaiiTheme.cream, KawaiiTheme.lightPink.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddPeriod) {
            AddPeriodView()
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let emoji: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            KawaiiCard(backgroundColor: color.opacity(0.2)) {
                VStack(spacing: 8) {
                    Text(emoji)
                        .font(.system(size: 32))
                    
                    Text(title)
                        .font(KawaiiTheme.bodyFont)
                        .foregroundColor(color)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
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