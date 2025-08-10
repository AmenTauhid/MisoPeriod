//
//  InsightsView.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-08-05.
//

import SwiftUI
import CoreData

struct InsightsView: View {
    let periods: FetchedResults<PeriodEntry>
    let cycles: FetchedResults<CycleEntry>
    
    private var averageCycleLength: Int {
        guard periods.count >= 2 else { return 28 }
        
        let sortedPeriods = periods.sorted { $0.startDate! > $1.startDate! }
        var totalDays = 0
        var cycleCount = 0
        
        for i in 0..<min(sortedPeriods.count - 1, 6) {
            let daysBetween = Calendar.current.dateComponents([.day],
                from: sortedPeriods[i + 1].startDate!,
                to: sortedPeriods[i].startDate!).day ?? 28
            totalDays += daysBetween
            cycleCount += 1
        }
        
        return cycleCount > 0 ? totalDays / cycleCount : 28
    }
    
    private var averagePeriodLength: Double {
        guard !periods.isEmpty else { return 5.0 }
        
        var totalDays = 0.0
        var periodCount = 0
        
        for period in periods {
            guard let startDate = period.startDate else { continue }
            
            if let endDate = period.endDate {
                let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
                totalDays += Double(days + 1)
                periodCount += 1
            }
        }
        
        return periodCount > 0 ? totalDays / Double(periodCount) : 5.0
    }
    
    private var cycleRegularity: String {
        guard periods.count >= 3 else { return "Need more data" }
        
        let sortedPeriods = periods.sorted { $0.startDate! > $1.startDate! }
        var cycleLengths: [Int] = []
        
        for i in 0..<min(sortedPeriods.count - 1, 6) {
            let daysBetween = Calendar.current.dateComponents([.day],
                from: sortedPeriods[i + 1].startDate!,
                to: sortedPeriods[i].startDate!).day ?? 28
            cycleLengths.append(daysBetween)
        }
        
        guard !cycleLengths.isEmpty else { return "Need more data" }
        
        let maxDiff = cycleLengths.max()! - cycleLengths.min()!
        
        if maxDiff <= 3 {
            return "Very Regular \(KawaiiEmojis.sparkles)"
        } else if maxDiff <= 7 {
            return "Fairly Regular \(KawaiiEmojis.heart)"
        } else {
            return "Irregular \(KawaiiEmojis.butterfly)"
        }
    }
    
    private var commonSymptoms: [String] {
        var symptomCount: [String: Int] = [:]
        
        for period in periods {
            if let symptomsObject = period.symptoms,
               let symptoms = symptomsObject as? [String] {
                for symptom in symptoms {
                    symptomCount[symptom, default: 0] += 1
                }
            }
        }
        
        return symptomCount.sorted { $0.value > $1.value }
                           .prefix(3)
                           .map { $0.key }
    }
    
    private var moodPatterns: [(String, Int)] {
        var moodCount: [String: Int] = [:]
        
        for period in periods {
            if let mood = period.mood {
                moodCount[mood, default: 0] += 1
            }
        }
        
        return moodCount.sorted { $0.value > $1.value }
    }
    
    // Extract header into separate computed property
    private var headerView: some View {
        HStack {
            Text("\(KawaiiEmojis.sparkles) Your Insights")
                .font(KawaiiTheme.titleFont)
                .foregroundColor(KawaiiTheme.deepPink)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // Extract empty state into separate computed property
    private var emptyStateView: some View {
        KawaiiCard(backgroundColor: KawaiiTheme.lightPink) {
            VStack(spacing: 16) {
                Text(KawaiiEmojis.flower)
                    .font(.system(size: 64))
                
                Text("Start tracking to see insights!")
                    .font(KawaiiTheme.headlineFont)
                    .foregroundColor(KawaiiTheme.deepPink)
                    .multilineTextAlignment(.center)
                
                Text("Log a few periods to unlock beautiful insights about your cycle")
                    .font(KawaiiTheme.bodyFont)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .padding(.horizontal)
    }
    
    // Extract stats grid into separate computed property
    private var statsGridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 15) {
            StatsCard(
                title: "Average Cycle",
                value: "\(averageCycleLength) days",
                emoji: KawaiiEmojis.calendar,
                color: KawaiiTheme.primaryPink
            )
            
            StatsCard(
                title: "Period Length",
                value: String(format: "%.1f days", averagePeriodLength),
                emoji: KawaiiEmojis.heart,
                color: KawaiiTheme.lavender
            )
            
            StatsCard(
                title: "Total Tracked",
                value: "\(periods.count) periods",
                emoji: KawaiiEmojis.rainbow,
                color: KawaiiTheme.peach
            )
            
            StatsCard(
                title: "Regularity",
                value: cycleRegularity,
                emoji: KawaiiEmojis.sparkles,
                color: KawaiiTheme.mintGreen
            )
        }
        .padding(.horizontal)
    }
    
    // Extract symptoms view into separate computed property
    private var symptomsView: some View {
        Group {
            if !commonSymptoms.isEmpty {
                KawaiiCard(backgroundColor: KawaiiTheme.lightPeach) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(KawaiiEmojis.butterfly) Common Symptoms")
                            .font(KawaiiTheme.headlineFont)
                            .foregroundColor(KawaiiTheme.deepPink)
                        
                        ForEach(commonSymptoms, id: \.self) { symptom in
                            HStack {
                                Circle()
                                    .fill(KawaiiTheme.peach)
                                    .frame(width: 8, height: 8)
                                
                                Text(symptom)
                                    .font(KawaiiTheme.bodyFont)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Extract mood patterns view into separate computed property
    private var moodPatternsView: some View {
        Group {
            if !moodPatterns.isEmpty {
                KawaiiCard(backgroundColor: KawaiiTheme.lightMint) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(KawaiiEmojis.heart) Mood Patterns")
                            .font(KawaiiTheme.headlineFont)
                            .foregroundColor(KawaiiTheme.deepPink)
                        
                        ForEach(moodPatterns, id: \.0) { mood, count in
                            HStack {
                                Text(mood)
                                    .font(KawaiiTheme.bodyFont)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text("\(count)x")
                                    .font(KawaiiTheme.captionFont)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Extract prediction and tips view into separate computed property
    private var predictionAndTipsView: some View {
        Group {
            if periods.count >= 2 {
                PredictionCard(
                    periods: periods,
                    averageCycleLength: averageCycleLength
                )
                .padding(.horizontal)
            }
            
            HealthTipsCard()
                .padding(.horizontal)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerView
                
                if periods.isEmpty {
                    emptyStateView
                } else {
                    statsGridView
                    symptomsView
                    moodPatternsView
                    predictionAndTipsView
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top)
        }
        .background(
            LinearGradient(
                colors: [KawaiiTheme.cream, KawaiiTheme.lightMint.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
    
    private func getMoodEmoji(for mood: String) -> String {
        switch mood {
        case "Happy": return KawaiiEmojis.happy
        case "Sad": return KawaiiEmojis.sad
        case "Neutral": return KawaiiEmojis.neutral
        case "Tired": return KawaiiEmojis.tired
        case "Anxious": return KawaiiEmojis.anxious
        default: return KawaiiEmojis.heart
        }
    }
}

struct StatsCard: View {
    let title: String
    let value: String
    let emoji: String
    let color: Color
    
    var body: some View {
        KawaiiCard(backgroundColor: color.opacity(0.2)) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.title)
                
                Text(title)
                    .font(KawaiiTheme.captionFont)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(value)
                    .font(KawaiiTheme.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct PredictionCard: View {
    let periods: FetchedResults<PeriodEntry>
    let averageCycleLength: Int
    
    private var nextPeriodDate: Date? {
        guard let lastPeriod = periods.first?.startDate else { return nil }
        return Calendar.current.date(byAdding: .day, value: averageCycleLength, to: lastPeriod)
    }
    
    private var daysUntilNextPeriod: Int {
        guard let nextDate = nextPeriodDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        KawaiiCard(backgroundColor: KawaiiTheme.lightLavender) {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(KawaiiEmojis.moon) Next Period Prediction")
                    .font(KawaiiTheme.headlineFont)
                    .foregroundColor(KawaiiTheme.deepPink)
                
                if let nextDate = nextPeriodDate {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Expected Date:")
                                .font(KawaiiTheme.captionFont)
                                .foregroundColor(.secondary)
                            
                            Text(dateFormatter.string(from: nextDate))
                                .font(KawaiiTheme.bodyFont)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("In \(max(0, daysUntilNextPeriod)) days")
                                .font(KawaiiTheme.bodyFont)
                                .fontWeight(.semibold)
                                .foregroundColor(KawaiiTheme.deepPink)
                            
                            Text("Reminder set \(KawaiiEmojis.sparkles)")
                                .font(KawaiiTheme.captionFont)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Need more data for predictions")
                        .font(KawaiiTheme.bodyFont)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct HealthTipsCard: View {
    private let tips = [
        "Stay hydrated! Drink plenty of water to help reduce bloating \(KawaiiEmojis.sparkles)",
        "Light exercise can help ease cramps and improve mood \(KawaiiEmojis.heart)",
        "Iron-rich foods can help replenish what's lost during your period \(KawaiiEmojis.cherry)",
        "Quality sleep is extra important during your cycle \(KawaiiEmojis.moon)",
        "Track your symptoms to identify patterns and triggers \(KawaiiEmojis.butterfly)"
    ]
    
    @State private var currentTipIndex = 0
    
    var body: some View {
        KawaiiCard(backgroundColor: KawaiiTheme.softGray) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("\(KawaiiEmojis.sun) Daily Tip")
                        .font(KawaiiTheme.headlineFont)
                        .foregroundColor(KawaiiTheme.deepPink)
                    
                    Spacer()
                    
                    Button(action: {
                        currentTipIndex = (currentTipIndex + 1) % tips.count
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(KawaiiTheme.primaryPink)
                    }
                }
                
                Text(tips[currentTipIndex])
                    .font(KawaiiTheme.bodyFont)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
            currentTipIndex = Int.random(in: 0..<tips.count)
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
