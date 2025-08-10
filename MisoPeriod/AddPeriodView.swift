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
    
    @State private var startDate = Date()
    @State private var endDate: Date?
    @State private var hasEndDate = false
    @State private var selectedFlow = "Light"
    @State private var selectedMood = ""
    @State private var symptoms: [String] = []
    @State private var notes = ""
    
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("\(KawaiiEmojis.flower) Log Your Period")
                            .font(KawaiiTheme.titleFont)
                            .foregroundColor(KawaiiTheme.deepPink)
                        
                        Text("Help me track your beautiful cycle")
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
                    
                    // Notes
                    KawaiiCard(backgroundColor: KawaiiTheme.cream) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes \(KawaiiEmojis.cherry)")
                                .font(KawaiiTheme.headlineFont)
                                .foregroundColor(KawaiiTheme.deepPink)
                            
                            TextField("How are you feeling today? Any special notes?", text: $notes, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(KawaiiTheme.bodyFont)
                                .lineLimit(3...6)
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: KawaiiTheme.smallCornerRadius))
                        }
                    }
                    
                    // Save Button
                    Button(action: savePeriod) {
                        HStack {
                            Text("\(KawaiiEmojis.sparkles) Save Period \(KawaiiEmojis.sparkles)")
                                .font(KawaiiTheme.bodyFont)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(KawaiiButtonStyle())
                    .padding(.horizontal)
                    
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
            let newPeriod = PeriodEntry(context: viewContext)
            newPeriod.startDate = startDate
            newPeriod.endDate = hasEndDate ? endDate : nil
            newPeriod.flow = selectedFlow
            newPeriod.mood = selectedMood.isEmpty ? nil : selectedMood
            newPeriod.symptoms = symptoms.isEmpty ? nil : symptoms as NSObject
            newPeriod.notes = notes.isEmpty ? nil : notes
            
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

#Preview {
    AddPeriodView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}