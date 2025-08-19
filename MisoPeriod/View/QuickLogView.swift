//  QuickLogView.swift
//  MisoPeriod
//  Lightweight logging for mood, symptoms, and notes without full period form.

import SwiftUI
import CoreData

struct QuickLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentation
    
    @State private var selectedMood: String = ""
    @State private var symptoms: [String] = []
    @State private var notes: String = ""
    @State private var isSaving = false
    
    private let moodOptions = [
        ("Happy", KawaiiEmojis.happy),
        ("Neutral", KawaiiEmojis.neutral),
        ("Tired", KawaiiEmojis.tired),
        ("Anxious", KawaiiEmojis.anxious),
        ("Sad", KawaiiEmojis.sad)
    ]
    
    private let symptomOptions = [
        ("Cramps", KawaiiEmojis.cramps),
        ("Bloating", KawaiiEmojis.bloating),
        ("Headache", KawaiiEmojis.headache),
        ("Back Pain", KawaiiEmojis.backache),
        ("Breast Tenderness", KawaiiEmojis.tender)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("\(KawaiiEmojis.heart) Quick Log")
                            .font(KawaiiTheme.titleFont)
                            .foregroundColor(KawaiiTheme.deepPink)
                        Text("Fast mood & symptom capture")
                            .font(KawaiiTheme.bodyFont)
                            .foregroundColor(.secondary)
                    }.padding(.top)
                    
                    KawaiiCard(backgroundColor: KawaiiTheme.lightMint) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mood \(KawaiiEmojis.sparkles)")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(moodOptions, id: \.0) { mood in
                                    Button { selectedMood = selectedMood == mood.0 ? "" : mood.0 } label: {
                                        VStack(spacing: 4) {
                                            Text(mood.1).font(.title2)
                                            Text(mood.0)
                                                .font(KawaiiTheme.captionFont)
                                                .foregroundColor(selectedMood == mood.0 ? .white : KawaiiTheme.deepPink)
                                        }
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(selectedMood == mood.0 ? KawaiiTheme.mintGreen : KawaiiTheme.mintGreen.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: KawaiiTheme.smallCornerRadius))
                                    }
                                }
                            }
                        }
                    }
                    
                    KawaiiCard(backgroundColor: KawaiiTheme.softGray) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Symptoms \(KawaiiEmojis.butterfly)")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(symptomOptions, id: \.0) { symptom in
                                    Button {
                                        if symptoms.contains(symptom.0) { symptoms.removeAll { $0 == symptom.0 } } else { symptoms.append(symptom.0) }
                                    } label: {
                                        HStack { Text(symptom.1); Text(symptom.0).font(KawaiiTheme.captionFont).foregroundColor(symptoms.contains(symptom.0) ? .white : KawaiiTheme.deepPink) }
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(symptoms.contains(symptom.0) ? KawaiiTheme.primaryPink : KawaiiTheme.primaryPink.opacity(0.2))
                                            .clipShape(RoundedRectangle(cornerRadius: KawaiiTheme.smallCornerRadius))
                                    }
                                }
                            }
                        }
                    }
                    
                    KawaiiCard(backgroundColor: KawaiiTheme.cream) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes \(KawaiiEmojis.cherry)")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            TextField("Optional note", text: $notes, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(KawaiiTheme.bodyFont)
                                .lineLimit(2...5)
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: KawaiiTheme.smallCornerRadius))
                        }
                    }
                    
                    Button(action: save) {
                        if isSaving { ProgressView().tint(.white) } else { Text("Save Quick Log") }
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(KawaiiButtonStyle())
                    .disabled(isSaving || (selectedMood.isEmpty && symptoms.isEmpty && notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(
                LinearGradient(colors: [KawaiiTheme.cream, KawaiiTheme.lightMint.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { presentation.wrappedValue.dismiss() }.foregroundColor(KawaiiTheme.deepPink) }
            }
        }
    }
    
    private func currentPeriod() -> PeriodEntry? {
        // Find an existing period containing today or ongoing
        let request: NSFetchRequest<PeriodEntry> = PeriodEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        request.fetchLimit = 10
        if let results = try? viewContext.fetch(request) {
            for p in results { if let start = p.startDate { if let end = p.endDate { if Calendar.current.isDateInToday(start) || (Date() >= start && Date() <= end) { return p } } else if Date() >= start { return p } } }
        }
        return nil
    }
    
    private func save() {
        isSaving = true
        let period = currentPeriod() ?? PeriodEntry(context: viewContext)
        if period.startDate == nil { period.startDate = Date(); period.flow = "Light" }
        if !selectedMood.isEmpty { period.mood = selectedMood }
        if !symptoms.isEmpty {
            var existing = (period.symptoms as? [String]) ?? []
            for s in symptoms where !existing.contains(s) { existing.append(s) }
            period.symptoms = existing.isEmpty ? nil : existing as NSObject
        }
        if !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let existingNotes = period.notes, !existingNotes.isEmpty { period.notes = existingNotes + "\n" + notes } else { period.notes = notes }
        }
        do { try viewContext.save(); presentation.wrappedValue.dismiss() } catch { print("Quick log save error: \(error)") }
        isSaving = false
    }
}

#Preview {
    QuickLogView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
