//  SymptomLogView.swift
//  MisoPeriod
//  Separate symptom logging screen.

import SwiftUI
import CoreData

struct SymptomLogView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentation
    
    @State private var selected: Set<String> = []
    @State private var saving = false
    
    private let symptomOptions = [
        ("Cramps", KawaiiEmojis.cramps),
        ("Bloating", KawaiiEmojis.bloating),
        ("Headache", KawaiiEmojis.headache),
        ("Back Pain", KawaiiEmojis.backache),
        ("Breast Tenderness", KawaiiEmojis.tender)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 28) {
                VStack(spacing: 8) {
                    Text("\(KawaiiEmojis.butterfly) Symptoms")
                        .font(KawaiiTheme.titleFont)
                        .foregroundColor(KawaiiTheme.deepPink)
                    Text("Select what you're experiencing")
                        .font(KawaiiTheme.bodyFont)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(symptomOptions, id: \.0) { symptom in
                            Button { toggle(symptom.0) } label: {
                                HStack(spacing: 6) {
                                    Text(symptom.1)
                                    Text(symptom.0)
                                        .font(KawaiiTheme.captionFont)
                                        .foregroundColor(selected.contains(symptom.0) ? .white : KawaiiTheme.deepPink)
                                }
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(selected.contains(symptom.0) ? KawaiiTheme.primaryPink : KawaiiTheme.primaryPink.opacity(0.25))
                                .clipShape(RoundedRectangle(cornerRadius: KawaiiTheme.smallCornerRadius))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Button(action: saveSymptoms) {
                    if saving { ProgressView().tint(.white) } else { Text("Save Symptoms") }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(KawaiiButtonStyle())
                .disabled(selected.isEmpty || saving)
                .padding(.horizontal)
                
                Spacer()
            }
            .background(
                LinearGradient(colors: [KawaiiTheme.cream, KawaiiTheme.lightLavender.opacity(0.25)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )
            .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Close") { presentation.wrappedValue.dismiss() }.foregroundColor(KawaiiTheme.deepPink) } }
        }
    }
    
    private func toggle(_ s: String) { if selected.contains(s) { selected.remove(s) } else { selected.insert(s) } }
    
    private func findOrCreateTodayPeriod() -> PeriodEntry {
        let req: NSFetchRequest<PeriodEntry> = PeriodEntry.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        req.fetchLimit = 15
        if let results = try? viewContext.fetch(req) {
            for p in results { if let start = p.startDate { if Calendar.current.isDateInToday(start) || (Date() >= start && (p.endDate == nil || Date() <= p.endDate!)) { return p } } }
        }
        let new = PeriodEntry(context: viewContext)
        new.startDate = Date()
        new.flow = "Light"
        return new
    }
    
    private func saveSymptoms() {
        guard !selected.isEmpty else { return }
        saving = true
        let period = findOrCreateTodayPeriod()
        var existing = (period.symptoms as? [String]) ?? []
        for s in selected where !existing.contains(s) { existing.append(s) }
        period.symptoms = existing.isEmpty ? nil : existing as NSObject
        do { try viewContext.save(); presentation.wrappedValue.dismiss() } catch { print("Symptom save error: \(error)") }
        saving = false
    }
}

#Preview { SymptomLogView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext) }
