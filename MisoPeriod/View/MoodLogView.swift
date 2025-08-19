//  MoodLogView.swift
//  MisoPeriod
//  Separate mood logging screen.

import SwiftUI
import CoreData

struct MoodLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentation
    
    @State private var selectedMood: String = ""
    @State private var saving = false
    
    private let moodOptions = [
        ("Happy", KawaiiEmojis.happy),
        ("Neutral", KawaiiEmojis.neutral),
        ("Tired", KawaiiEmojis.tired),
        ("Anxious", KawaiiEmojis.anxious),
        ("Sad", KawaiiEmojis.sad)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("\(KawaiiEmojis.heart) Mood Log")
                        .font(KawaiiTheme.titleFont)
                        .foregroundColor(KawaiiTheme.deepPink)
                    Text("Tap how you feel today")
                        .font(KawaiiTheme.bodyFont)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(moodOptions, id: \.0) { mood in
                        Button {
                            selectedMood = selectedMood == mood.0 ? "" : mood.0
                        } label: {
                            VStack(spacing: 6) {
                                Text(mood.1).font(.largeTitle)
                                Text(mood.0)
                                    .font(KawaiiTheme.captionFont)
                                    .foregroundColor(selectedMood == mood.0 ? .white : KawaiiTheme.deepPink)
                            }
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(selectedMood == mood.0 ? KawaiiTheme.primaryPink : KawaiiTheme.primaryPink.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: KawaiiTheme.smallCornerRadius))
                        }
                    }
                }
                .padding(.horizontal)
                
                Button(action: saveMood) {
                    if saving { ProgressView().tint(.white) } else { Text("Save Mood") }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(KawaiiButtonStyle())
                .disabled(selectedMood.isEmpty || saving)
                .padding(.horizontal)
                
                Spacer()
            }
            .background(
                LinearGradient(colors: [KawaiiTheme.cream, KawaiiTheme.lightPink.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Close") { presentation.wrappedValue.dismiss() }.foregroundColor(KawaiiTheme.deepPink) } }
        }
    }
    
    private func findOrCreateTodayPeriod() -> PeriodEntry {
        let request: NSFetchRequest<PeriodEntry> = PeriodEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        request.fetchLimit = 15
        if let results = try? viewContext.fetch(request) {
            for p in results { if let start = p.startDate { if Calendar.current.isDateInToday(start) || (Date() >= start && (p.endDate == nil || Date() <= p.endDate!)) { return p } } }
        }
        let new = PeriodEntry(context: viewContext)
        new.startDate = Date()
        new.flow = "Light"
        return new
    }
    
    private func saveMood() {
        guard !selectedMood.isEmpty else { return }
        saving = true
        let period = findOrCreateTodayPeriod()
        period.mood = selectedMood
        do { try viewContext.save(); presentation.wrappedValue.dismiss() } catch { print("Mood save error: \(error)") }
        saving = false
    }
}

#Preview { MoodLogView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext) }
