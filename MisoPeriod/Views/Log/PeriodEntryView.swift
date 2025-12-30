import SwiftUI

struct PeriodEntryView: View {
    @ObservedObject var viewModel: CycleViewModel
    @Binding var isPresented: Bool

    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var flowIntensity: FlowIntensity = .medium
    @State private var isSaving = false
    @State private var showingSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header illustration
                        headerSection

                        // Date Range Selection
                        dateRangeSection

                        // Flow Intensity
                        flowSection

                        // Summary
                        summarySection

                        Spacer(minLength: 100)
                    }
                    .padding()
                }

                if showingSuccess {
                    successOverlay
                }
            }
            .navigationTitle("Log Period")
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
                        savePeriod()
                    }
                    .font(.headline)
                    .foregroundColor(.misoPrimary)
                    .disabled(isSaving || !isValidRange)
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "drop.fill")
                .font(.system(size: 48))
                .foregroundColor(.misoPrimary)

            Text("When was your period?")
                .font(.misoTitle3)
                .foregroundColor(.misoTextPrimary)

            Text("Select the start and end dates")
                .font(.misoBody)
                .foregroundColor(.misoTextSecondary)
        }
        .padding(.vertical)
    }

    // MARK: - Date Range Section
    private var dateRangeSection: some View {
        VStack(spacing: 16) {
            // Start Date
            VStack(alignment: .leading, spacing: 8) {
                Label("Start Date", systemImage: "calendar")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)

                DatePicker(
                    "Start Date",
                    selection: $startDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .tint(.misoPrimary)
                .onChange(of: startDate) { _, newValue in
                    // Ensure end date is not before start date
                    if endDate < newValue {
                        endDate = newValue
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.misoBgCard)
            )

            // Arrow indicator
            Image(systemName: "arrow.down")
                .font(.title3)
                .foregroundColor(.misoTextTertiary)

            // End Date
            VStack(alignment: .leading, spacing: 8) {
                Label("End Date", systemImage: "calendar.badge.checkmark")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)

                DatePicker(
                    "End Date",
                    selection: $endDate,
                    in: startDate...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .tint(.misoPrimary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.misoBgCard)
            )
        }
    }

    // MARK: - Flow Section
    private var flowSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Average Flow")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            HStack(spacing: 8) {
                ForEach([FlowIntensity.light, .medium, .heavy], id: \.self) { flow in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            flowIntensity = flow
                        }
                    } label: {
                        VStack(spacing: 6) {
                            HStack(spacing: 2) {
                                ForEach(0..<flow.dropCount, id: \.self) { _ in
                                    Image(systemName: "drop.fill")
                                        .font(.caption)
                                        .foregroundColor(flowIntensity == flow ? .white : flow.color)
                                }
                            }

                            Text(flow.displayName)
                                .font(.misoCaption)
                                .foregroundColor(flowIntensity == flow ? .white : .misoTextPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(flowIntensity == flow ? flow.color : Color.misoBgCard)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(flowIntensity == flow ? flow.color : Color.misoBgSecondary, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            HStack(spacing: 20) {
                SummaryItem(
                    icon: "calendar.badge.clock",
                    title: "Duration",
                    value: "\(periodDays) days"
                )

                SummaryItem(
                    icon: "drop.fill",
                    title: "Flow",
                    value: flowIntensity.displayName
                )
            }

            if !isValidRange {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Period duration seems unusual. Please check the dates.")
                        .font(.misoCaption)
                        .foregroundColor(.orange)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoPrimary.opacity(0.1))
        )
    }

    // MARK: - Success Overlay
    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.misoSecondary)

            Text("Period Logged!")
                .font(.misoTitle2)
                .foregroundColor(.misoTextPrimary)

            Text("\(periodDays) days recorded")
                .font(.misoBody)
                .foregroundColor(.misoTextSecondary)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.misoBgCard)
                .shadow(color: .black.opacity(0.2), radius: 20)
        )
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Computed Properties
    private var periodDays: Int {
        startDate.daysBetween(endDate) + 1
    }

    private var isValidRange: Bool {
        periodDays >= 1 && periodDays <= 14
    }

    // MARK: - Actions
    private func savePeriod() {
        isSaving = true

        Task {
            // Log each day of the period
            var currentDate = startDate
            while currentDate <= endDate {
                // Vary flow intensity naturally (heavier in middle)
                let dayIndex = startDate.daysBetween(currentDate)
                let flow = calculateFlowForDay(dayIndex: dayIndex, totalDays: periodDays)

                await viewModel.logForDate(
                    date: currentDate,
                    flow: flow,
                    mood: nil,
                    energy: nil,
                    symptoms: [],
                    notes: nil
                )

                currentDate = currentDate.adding(days: 1)
            }

            await MainActor.run {
                withAnimation(.spring(response: 0.4)) {
                    showingSuccess = true
                }
            }

            try? await Task.sleep(nanoseconds: 1_500_000_000)

            await MainActor.run {
                isPresented = false
            }
        }
    }

    private func calculateFlowForDay(dayIndex: Int, totalDays: Int) -> FlowIntensity {
        // Create a natural flow pattern: light -> medium/heavy -> light
        if totalDays <= 2 {
            return flowIntensity
        }

        let midpoint = totalDays / 2

        if dayIndex == 0 || dayIndex == totalDays - 1 {
            // First and last days are lighter
            return flowIntensity == .heavy ? .medium : .light
        } else if dayIndex >= midpoint - 1 && dayIndex <= midpoint + 1 {
            // Middle days are at selected intensity
            return flowIntensity
        } else {
            // Other days slightly lighter
            return flowIntensity == .light ? .light : .medium
        }
    }
}

// MARK: - Summary Item
struct SummaryItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.misoPrimary)

            Text(value)
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            Text(title)
                .font(.misoCaption)
                .foregroundColor(.misoTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PeriodEntryView(viewModel: CycleViewModel.preview, isPresented: .constant(true))
}
