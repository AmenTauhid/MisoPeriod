//
//  CalendarView.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-08-05.
//

import SwiftUI
import CoreData

struct CalendarView: View {
    let periods: FetchedResults<PeriodEntry>
    let cycles: FetchedResults<CycleEntry>
    
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private func daysInMonth() -> [Date] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstOfMonth = calendar.dateInterval(of: .month, for: currentMonth)?.start else {
            return []
        }
        
        return monthRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }
    }
    
    private func dayOfWeek(for date: Date) -> Int {
        let day = calendar.component(.weekday, from: date)
        return day == 1 ? 7 : day - 1  // Convert Sunday=1 to Sunday=7, Monday=1
    }
    
    private func isPeriodDay(_ date: Date) -> Bool {
        return periods.contains { period in
            guard let startDate = period.startDate else { return false }
            
            if let endDate = period.endDate {
                return date >= startDate && date <= endDate
            } else {
                return calendar.isDate(date, inSameDayAs: startDate)
            }
        }
    }
    
    private func isOvulationDay(_ date: Date) -> Bool {
        // Simple ovulation prediction: ~14 days before next predicted period
        guard let lastPeriod = periods.first?.startDate else { return false }
        
        let daysSinceLastPeriod = calendar.dateComponents([.day], from: lastPeriod, to: date).day ?? 0
        let averageCycleLength = calculateAverageCycleLength()
        let ovulationDay = averageCycleLength - 14
        
        return daysSinceLastPeriod == ovulationDay
    }
    
    private func calculateAverageCycleLength() -> Int {
        guard periods.count >= 2 else { return 28 }
        
        let sortedPeriods = periods.sorted { $0.startDate! > $1.startDate! }
        var totalDays = 0
        var cycleCount = 0
        
        for i in 0..<min(sortedPeriods.count - 1, 6) {
            let daysBetween = calendar.dateComponents([.day], 
                from: sortedPeriods[i + 1].startDate!, 
                to: sortedPeriods[i].startDate!).day ?? 28
            totalDays += daysBetween
            cycleCount += 1
        }
        
        return cycleCount > 0 ? totalDays / cycleCount : 28
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(KawaiiEmojis.calendar) Calendar")
                    .font(KawaiiTheme.titleFont)
                    .foregroundColor(KawaiiTheme.deepPink)
                
                Spacer()
            }
            .padding()
            .background(KawaiiTheme.cream)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Month Navigation
                    KawaiiCard(backgroundColor: KawaiiTheme.lightPink) {
                        HStack {
                            Button(action: { changeMonth(-1) }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(KawaiiTheme.deepPink)
                                    .font(.title2)
                            }
                            
                            Spacer()
                            
                            Text(dateFormatter.string(from: currentMonth))
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            
                            Spacer()
                            
                            Button(action: { changeMonth(1) }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(KawaiiTheme.deepPink)
                                    .font(.title2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar Grid
                    KawaiiCard(backgroundColor: .white) {
                        VStack(spacing: 12) {
                            // Weekday Headers (use enumerated IDs to avoid duplicate warnings for T, S)
                            HStack {
                                let weekdayHeaders = ["M", "T", "W", "T", "F", "S", "S"]
                                ForEach(Array(weekdayHeaders.enumerated()), id: \.0) { index, day in
                                    Text(day)
                                        .font(KawaiiTheme.captionFont)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            
                            // Calendar Days
                            let days = daysInMonth()
                            let firstWeekday = dayOfWeek(for: days.first ?? Date())
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                                // Empty cells for days before month starts
                                ForEach(1..<firstWeekday, id: \.self) { _ in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 40)
                                }
                                
                                // Month days
                                ForEach(days, id: \.self) { date in
                                    CalendarDayView(
                                        date: date,
                                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                                        isPeriodDay: isPeriodDay(date),
                                        isOvulationDay: isOvulationDay(date),
                                        isToday: calendar.isDateInToday(date)
                                    ) {
                                        selectedDate = date
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Legend
                    KawaiiCard(backgroundColor: KawaiiTheme.softGray) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Legend \(KawaiiEmojis.rainbow)")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            
                            HStack(spacing: 20) {
                                LegendItem(color: KawaiiTheme.primaryPink, text: "Period")
                                LegendItem(color: KawaiiTheme.lavender, text: "Ovulation")
                                LegendItem(color: KawaiiTheme.mintGreen, text: "Today")
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Selected Date Info
                    if !calendar.isDate(selectedDate, inSameDayAs: Date()) {
                        SelectedDateInfoView(
                            date: selectedDate,
                            periods: periods,
                            isPeriodDay: isPeriodDay(selectedDate),
                            isOvulationDay: isOvulationDay(selectedDate)
                        )
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
        }
        .background(
            LinearGradient(
                colors: [KawaiiTheme.cream, KawaiiTheme.lightLavender.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
    
    private func changeMonth(_ value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isPeriodDay: Bool
    let isOvulationDay: Bool
    let isToday: Bool
    let action: () -> Void
    
    private var dayNumber: String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return KawaiiTheme.deepPink
        } else if isPeriodDay {
            return KawaiiTheme.primaryPink
        } else if isOvulationDay {
            return KawaiiTheme.lavender
        } else if isToday {
            return KawaiiTheme.mintGreen
        } else {
            return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        if isSelected || isPeriodDay || isOvulationDay || isToday {
            return .white
        } else {
            return .primary
        }
    }
    
    var body: some View {
        Button(action: action) {
            Text(dayNumber)
                .font(KawaiiTheme.bodyFont)
                .foregroundColor(foregroundColor)
                .frame(width: 40, height: 40)
                .background(backgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(text)
                .font(KawaiiTheme.captionFont)
                .foregroundColor(.secondary)
        }
    }
}

struct SelectedDateInfoView: View {
    let date: Date
    let periods: FetchedResults<PeriodEntry>
    let isPeriodDay: Bool
    let isOvulationDay: Bool
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
    
    private func getPeriodForDate() -> PeriodEntry? {
        return periods.first { period in
            guard let startDate = period.startDate else { return false }
            
            if let endDate = period.endDate {
                return date >= startDate && date <= endDate
            } else {
                return Calendar.current.isDate(date, inSameDayAs: startDate)
            }
        }
    }
    
    var body: some View {
        KawaiiCard(backgroundColor: KawaiiTheme.lightPeach) {
            VStack(alignment: .leading, spacing: 12) {
                Text(dateFormatter.string(from: date))
                    .font(KawaiiTheme.headlineFont)
                    .foregroundColor(KawaiiTheme.deepPink)
                
                if isPeriodDay {
                    HStack {
                        Text(KawaiiEmojis.period)
                        Text("Period Day")
                            .font(KawaiiTheme.bodyFont)
                            .foregroundColor(.primary)
                    }
                    
                    if let period = getPeriodForDate() {
                        if let flow = period.flow {
                            Text("Flow: \(flow)")
                                .font(KawaiiTheme.captionFont)
                                .foregroundColor(.secondary)
                        }
                        
                        if let mood = period.mood {
                            Text("Mood: \(mood)")
                                .font(KawaiiTheme.captionFont)
                                .foregroundColor(.secondary)
                        }
                    }
                } else if isOvulationDay {
                    HStack {
                        Text(KawaiiEmojis.flower)
                        Text("Predicted Ovulation")
                            .font(KawaiiTheme.bodyFont)
                            .foregroundColor(.primary)
                    }
                } else {
                    Text("No events recorded")
                        .font(KawaiiTheme.captionFont)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
