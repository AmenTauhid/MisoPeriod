import SwiftUI

struct DailyLogView: View {
    @ObservedObject var viewModel: CycleViewModel
    @Binding var isPresented: Bool
    var initialDate: Date = Date()

    @State private var selectedDate = Date()
    @State private var hasInitialized = false
    @State private var flowIntensity: FlowIntensity = .none
    @State private var mood: Int = 3
    @State private var energy: Int = 3
    @State private var selectedSymptoms: Set<SymptomType> = []
    @State private var symptomSeverities: [SymptomType: Int] = [:]
    @State private var notes: String = ""
    @State private var showingSymptomPicker = false
    @State private var showingSaveConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Date Picker
                        dateSection

                        // Flow Intensity
                        flowSection

                        // Mood & Energy
                        moodEnergySection

                        // Symptoms
                        symptomsSection

                        // Notes
                        notesSection

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle(selectedDate.isToday ? "Log Today" : "Log \(selectedDate.shortDateString)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.misoTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLog()
                    }
                    .font(.headline)
                    .foregroundColor(.misoPrimary)
                }
            }
            .sheet(isPresented: $showingSymptomPicker) {
                SymptomPickerSheet(
                    selectedSymptoms: $selectedSymptoms,
                    symptomSeverities: $symptomSeverities
                )
            }
        }
        .onAppear {
            if !hasInitialized {
                selectedDate = initialDate
                hasInitialized = true
            }
            loadExistingLog()
        }
        .overlay {
            if showingSaveConfirmation {
                saveConfirmationOverlay
            }
        }
    }

    // MARK: - Date Section
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            DatePicker(
                "Select date",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(.misoPrimary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.misoBgCard)
            )
            .onChange(of: selectedDate) { _, _ in
                loadExistingLog()
            }
        }
    }

    // MARK: - Flow Section
    private var flowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flow")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            HStack(spacing: 8) {
                ForEach(FlowIntensity.allCases, id: \.self) { flow in
                    FlowButton(
                        flow: flow,
                        isSelected: flowIntensity == flow
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            flowIntensity = flow
                        }
                    }
                }
            }
        }
    }

    // MARK: - Mood & Energy Section
    private var moodEnergySection: some View {
        VStack(spacing: 20) {
            // Mood
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Mood")
                        .font(.misoHeadline)
                        .foregroundColor(.misoTextPrimary)
                    Spacer()
                    Text(moodEmoji(for: mood))
                        .font(.title)
                }

                MoodSlider(value: $mood, color: .moodColor(for: mood))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.misoBgCard)
            )

            // Energy
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Energy")
                        .font(.misoHeadline)
                        .foregroundColor(.misoTextPrimary)
                    Spacer()
                    Text(energyEmoji(for: energy))
                        .font(.title)
                }

                MoodSlider(value: $energy, color: .misoAccent)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.misoBgCard)
            )
        }
    }

    // MARK: - Symptoms Section
    private var symptomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Symptoms")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)

                Spacer()

                Button {
                    showingSymptomPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.misoSubheadline)
                    .foregroundColor(.misoPrimary)
                }
            }

            if selectedSymptoms.isEmpty {
                Text("No symptoms logged")
                    .font(.misoBody)
                    .foregroundColor(.misoTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(Array(selectedSymptoms), id: \.self) { symptom in
                        SymptomChip(
                            symptom: symptom,
                            severity: symptomSeverities[symptom] ?? 1
                        ) {
                            selectedSymptoms.remove(symptom)
                            symptomSeverities.removeValue(forKey: symptom)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.misoBgSecondary)
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    // MARK: - Save Confirmation Overlay
    private var saveConfirmationOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.misoSecondary)

            Text("Saved!")
                .font(.misoTitle2)
                .foregroundColor(.misoTextPrimary)

            Text(viewModel.currentPhase.randomAffirmation())
                .font(.misoBody)
                .foregroundColor(.misoTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.misoBgCard)
                .shadow(color: .black.opacity(0.2), radius: 20)
        )
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Helper Functions
    private func moodEmoji(for value: Int) -> String {
        switch value {
        case 1: return "😢"
        case 2: return "😕"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }

    private func energyEmoji(for value: Int) -> String {
        switch value {
        case 1: return "🔋"
        case 2: return "🪫"
        case 3: return "⚡️"
        case 4: return "💪"
        case 5: return "🚀"
        default: return "⚡️"
        }
    }

    private func loadExistingLog() {
        Task {
            if let log = await viewModel.getLog(for: selectedDate) {
                flowIntensity = log.flow
                mood = Int(log.mood)
                energy = Int(log.energy)
                notes = log.notes ?? ""

                // Load symptoms
                selectedSymptoms = Set(log.symptomTypes)
                if let symptoms = log.symptoms as? Set<Symptom> {
                    for symptom in symptoms {
                        if let type = SymptomType(rawValue: symptom.type ?? "") {
                            symptomSeverities[type] = Int(symptom.severity)
                        }
                    }
                }
            } else {
                // Reset to defaults
                flowIntensity = .none
                mood = 3
                energy = 3
                selectedSymptoms = []
                symptomSeverities = [:]
                notes = ""
            }
        }
    }

    private func saveLog() {
        let symptoms = selectedSymptoms.map { ($0, Int16(symptomSeverities[$0] ?? 1)) }

        Task {
            await viewModel.logForDate(
                date: selectedDate,
                flow: flowIntensity,
                mood: Int16(mood),
                energy: Int16(energy),
                symptoms: symptoms,
                notes: notes.isEmpty ? nil : notes
            )

            withAnimation(.spring(response: 0.4)) {
                showingSaveConfirmation = true
            }

            try? await Task.sleep(nanoseconds: 1_500_000_000)

            withAnimation {
                showingSaveConfirmation = false
            }

            isPresented = false
        }
    }
}

// MARK: - Flow Button
struct FlowButton: View {
    let flow: FlowIntensity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Drop indicators
                HStack(spacing: 2) {
                    ForEach(0..<flow.dropCount, id: \.self) { _ in
                        Image(systemName: "drop.fill")
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white : flow.color)
                    }
                    if flow == .none {
                        Image(systemName: "drop")
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white : .misoTextTertiary)
                    }
                }

                Text(flow.shortName)
                    .font(.misoCaption)
                    .foregroundColor(isSelected ? .white : .misoTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? flow.color : Color.misoBgCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? flow.color : Color.misoBgSecondary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mood Slider
struct MoodSlider: View {
    @Binding var value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { level in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        value = level
                    }
                } label: {
                    Circle()
                        .fill(level <= value ? color : Color.misoBgSecondary)
                        .frame(width: level <= value ? 28 : 20, height: level <= value ? 28 : 20)
                }
                .buttonStyle(.plain)

                if level < 5 {
                    Rectangle()
                        .fill(level < value ? color : Color.misoBgSecondary)
                        .frame(height: 3)
                }
            }
        }
    }
}

// MARK: - Symptom Chip
struct SymptomChip: View {
    let symptom: SymptomType
    let severity: Int
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symptom.icon)
                .font(.caption)

            Text(symptom.displayName)
                .font(.misoCaption)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.misoTextTertiary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(symptom.color.opacity(0.15))
        )
        .foregroundColor(symptom.color)
    }
}

// MARK: - Symptom Picker Sheet
struct SymptomPickerSheet: View {
    @Binding var selectedSymptoms: Set<SymptomType>
    @Binding var symptomSeverities: [SymptomType: Int]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(SymptomCategory.allCases) { category in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: category.icon)
                                        .foregroundColor(.misoPrimary)
                                    Text(category.displayName)
                                        .font(.misoHeadline)
                                }
                                .foregroundColor(.misoTextPrimary)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
                                    ForEach(SymptomType.byCategory[category] ?? []) { symptom in
                                        SymptomToggleButton(
                                            symptom: symptom,
                                            isSelected: selectedSymptoms.contains(symptom),
                                            severity: symptomSeverities[symptom] ?? 1
                                        ) {
                                            if selectedSymptoms.contains(symptom) {
                                                selectedSymptoms.remove(symptom)
                                                symptomSeverities.removeValue(forKey: symptom)
                                            } else {
                                                selectedSymptoms.insert(symptom)
                                                symptomSeverities[symptom] = 2
                                            }
                                        } onSeverityChange: { newSeverity in
                                            symptomSeverities[symptom] = newSeverity
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Symptoms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.misoPrimary)
                }
            }
        }
    }
}

// MARK: - Symptom Toggle Button
struct SymptomToggleButton: View {
    let symptom: SymptomType
    let isSelected: Bool
    let severity: Int
    let onToggle: () -> Void
    let onSeverityChange: (Int) -> Void

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onToggle) {
                HStack(spacing: 6) {
                    Image(systemName: symptom.icon)
                        .font(.subheadline)

                    Text(symptom.displayName)
                        .font(.misoSubheadline)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? symptom.color.opacity(0.2) : Color.misoBgCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? symptom.color : Color.clear, lineWidth: 2)
                )
                .foregroundColor(isSelected ? symptom.color : .misoTextSecondary)
            }
            .buttonStyle(.plain)

            if isSelected {
                // Severity selector
                HStack(spacing: 4) {
                    ForEach(1...3, id: \.self) { level in
                        Button {
                            onSeverityChange(level)
                        } label: {
                            Text(severityLabel(for: level))
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(level == severity ? symptom.color : Color.misoBgSecondary)
                                )
                                .foregroundColor(level == severity ? .white : .misoTextSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func severityLabel(for level: Int) -> String {
        switch level {
        case 1: return "Mild"
        case 2: return "Moderate"
        case 3: return "Severe"
        default: return ""
        }
    }
}

#Preview {
    DailyLogView(viewModel: CycleViewModel.preview, isPresented: .constant(true))
}
