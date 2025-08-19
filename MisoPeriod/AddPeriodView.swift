//
//  AddPeriodView.swift
//  MisoPeriod
//
//  Created by Ayman Tauhid on 2025-08-05.
//

import SwiftUI
import CoreData

struct AddPeriodView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // Editing support
    let periodToEdit: PeriodEntry?
    
    @State private var startDate = Date()
    @State private var endDate: Date?
    @State private var hasEndDate = false
    @State private var selectedFlow = "Light"
    @State private var selectedMood = ""
    @State private var symptoms: [String] = []
    
    private let flowOptions = ["Light", "Medium", "Heavy"]
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
    
    init(periodToEdit: PeriodEntry? = nil) {
        self.periodToEdit = periodToEdit
        if let p = periodToEdit {
            _startDate = State(initialValue: p.startDate ?? Date())
            _endDate = State(initialValue: p.endDate)
            _hasEndDate = State(initialValue: p.endDate != nil)
            _selectedFlow = State(initialValue: p.flow ?? "Light")
            _selectedMood = State(initialValue: p.mood ?? "")
            if let s = p.symptoms as? [String] { _symptoms = State(initialValue: s) }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("\(KawaiiEmojis.flower) \(periodToEdit == nil ? "Log Your Period" : "Edit Period")")
                            .font(KawaiiTheme.titleFont)
                            .foregroundColor(KawaiiTheme.deepPink)
                        
                        Text(periodToEdit == nil ? "Help me track your beautiful cycle" : "Update your period entry")
                            .font(KawaiiTheme.bodyFont)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Start Date
                    KawaiiCard(backgroundColor: KawaiiTheme.lightPink) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Start Date \(KawaiiEmojis.calendar)")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            
                            DatePicker("", selection: $startDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .accentColor(KawaiiTheme.primaryPink)
                        }
                    }
                    
                    // End Date
                    KawaiiCard(backgroundColor: KawaiiTheme.lightLavender) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("End Date \(KawaiiEmojis.moon)")
                                    .font(KawaiiTheme.headlineFont)
                                    .foregroundColor(KawaiiTheme.deepPink)
                                
                                Spacer()
                                
                                Toggle("", isOn: $hasEndDate)
                                    .toggleStyle(SwitchToggleStyle(tint: KawaiiTheme.lavender))
                            }
                            
                            if hasEndDate {
                                DatePicker("", selection: Binding(
                                    get: { endDate ?? Date() },
                                    set: { endDate = $0 }
                                ), displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .accentColor(KawaiiTheme.lavender)
                            } else {
                                Text("Currently ongoing")
                                    .font(KawaiiTheme.captionFont)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Flow Intensity
                    KawaiiCard(backgroundColor: KawaiiTheme.lightPeach) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Flow Intensity \(KawaiiEmojis.heart)")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            
                            HStack(spacing: 12) {
                                ForEach(flowOptions, id: \.self) { flow in
                                    Button(action: { selectedFlow = flow }) {
                                        Text(flow)
                                            .font(KawaiiTheme.bodyFont)
                                            .foregroundColor(selectedFlow == flow ? .white : KawaiiTheme.deepPink)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedFlow == flow ?
                                                KawaiiTheme.peach :
                                                KawaiiTheme.peach.opacity(0.2)
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    
                    // Mood
                    KawaiiCard(backgroundColor: KawaiiTheme.lightMint) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How are you feeling? \(KawaiiEmojis.sparkles)")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(moodOptions, id: \.0) { mood in
                                    Button(action: {
                                        selectedMood = selectedMood == mood.0 ? "" : mood.0
                                    }) {
                                        VStack(spacing: 4) {
                                            Text(mood.1)
                                                .font(.title2)
                                            Text(mood.0)
                                                .font(KawaiiTheme.captionFont)
                                                .foregroundColor(selectedMood == mood.0 ? .white : KawaiiTheme.deepPink)
                                        }
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            selectedMood == mood.0 ?
                                            KawaiiTheme.mintGreen :
                                            KawaiiTheme.mintGreen.opacity(0.2)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: KawaiiTheme.smallCornerRadius))
                                    }
                                }
                            }
                        }
                    }
                    
                    // Symptoms
                    KawaiiCard(backgroundColor: KawaiiTheme.softGray) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Symptoms \(KawaiiEmojis.butterfly)")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(symptomOptions, id: \.0) { symptom in
                                    Button(action: {
                                        if symptoms.contains(symptom.0) {
                                            symptoms.removeAll { $0 == symptom.0 }
                                        } else {
                                            symptoms.append(symptom.0)
                                        }
                                    }) {
                                        HStack {
                                            Text(symptom.1)
                                            Text(symptom.0)
                                                .font(KawaiiTheme.captionFont)
                                                .foregroundColor(symptoms.contains(symptom.0) ? .white : KawaiiTheme.deepPink)
                                        }
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            symptoms.contains(symptom.0) ?
                                            KawaiiTheme.primaryPink :
                                            KawaiiTheme.primaryPink.opacity(0.2)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: KawaiiTheme.smallCornerRadius))
                                    }
                                }
                            }
                        }
                    }
                    
                    // Save Button
                    Button(action: savePeriod) {
                        HStack {
                            Text("\(KawaiiEmojis.sparkles) \(periodToEdit == nil ? "Save Period" : "Update Period") \(KawaiiEmojis.sparkles)")
                                .font(KawaiiTheme.bodyFont)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(KawaiiButtonStyle())
                    .padding(.horizontal)
                    
                    if periodToEdit != nil {
                        Button(role: .destructive, action: deletePeriod) {
                            Text("Delete Entry").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(KawaiiButtonStyle(backgroundColor: .red.opacity(0.9)))
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 50)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(KawaiiTheme.deepPink)
                }
            }
        }
    }
    
    private func savePeriod() {
        withAnimation {
            let period = periodToEdit ?? PeriodEntry(context: viewContext)
            period.startDate = startDate
            period.endDate = hasEndDate ? endDate : nil
            period.flow = selectedFlow
            period.mood = selectedMood.isEmpty ? nil : selectedMood
            period.symptoms = symptoms.isEmpty ? nil : symptoms as NSObject
            
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deletePeriod() {
        guard let p = periodToEdit else { return }
        viewContext.delete(p)
        try? viewContext.save()
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    AddPeriodView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
