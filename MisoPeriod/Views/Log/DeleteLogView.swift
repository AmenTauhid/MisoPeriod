import SwiftUI

struct DeleteLogView: View {
    @ObservedObject var viewModel: CycleViewModel
    @Binding var isPresented: Bool

    @State private var selectedDate = Date()
    @State private var deleteRange = false
    @State private var endDate = Date()
    @State private var existingLog: DailyLog?
    @State private var showingConfirmation = false
    @State private var showingSuccess = false
    @State private var logsToDeleteCount = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.misoBgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Delete mode toggle
                        deleteModeSection

                        // Date Selection
                        dateSection

                        // Preview what will be deleted
                        if hasLogsToDelete {
                            previewSection
                        } else {
                            noLogsSection
                        }

                        Spacer(minLength: 100)
                    }
                    .padding()
                }

                if showingSuccess {
                    successOverlay
                }
            }
            .navigationTitle("Delete Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.misoTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Delete") {
                        showingConfirmation = true
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .disabled(!hasLogsToDelete)
                }
            }
            .confirmationDialog(
                "Delete \(logsToDeleteCount) log\(logsToDeleteCount == 1 ? "" : "s")?",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteLogs()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action cannot be undone.")
            }
            .onAppear {
                checkForExistingLog()
            }
            .onChange(of: selectedDate) { _, _ in
                checkForExistingLog()
            }
            .onChange(of: endDate) { _, _ in
                checkForExistingLog()
            }
            .onChange(of: deleteRange) { _, _ in
                if deleteRange {
                    endDate = selectedDate
                }
                checkForExistingLog()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "trash.fill")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.8))

            Text("Delete logged data")
                .font(.misoTitle3)
                .foregroundColor(.misoTextPrimary)

            Text("Select the date(s) you want to remove")
                .font(.misoBody)
                .foregroundColor(.misoTextSecondary)
        }
        .padding(.vertical)
    }

    // MARK: - Delete Mode Section
    private var deleteModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $deleteRange) {
                HStack {
                    Image(systemName: deleteRange ? "calendar.badge.minus" : "calendar")
                        .foregroundColor(.misoPrimary)
                    Text(deleteRange ? "Delete date range" : "Delete single date")
                        .font(.misoHeadline)
                        .foregroundColor(.misoTextPrimary)
                }
            }
            .tint(.misoPrimary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    // MARK: - Date Section
    private var dateSection: some View {
        VStack(spacing: 16) {
            // Start/Single Date
            VStack(alignment: .leading, spacing: 8) {
                Label(deleteRange ? "Start Date" : "Date", systemImage: "calendar")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)

                DatePicker(
                    "Select date",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .tint(.misoPrimary)
                .onChange(of: selectedDate) { _, newValue in
                    if deleteRange && endDate < newValue {
                        endDate = newValue
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.misoBgCard)
            )

            if deleteRange {
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
                        in: selectedDate...Date(),
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
    }

    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Will be deleted:")
                    .font(.misoHeadline)
                    .foregroundColor(.misoTextPrimary)
            }

            HStack(spacing: 16) {
                VStack {
                    Text("\(logsToDeleteCount)")
                        .font(.misoTitle)
                        .foregroundColor(.red)
                    Text(logsToDeleteCount == 1 ? "Log" : "Logs")
                        .font(.misoCaption)
                        .foregroundColor(.misoTextSecondary)
                }
                .frame(maxWidth: .infinity)

                if deleteRange {
                    VStack {
                        Text("\(dayCount)")
                            .font(.misoTitle)
                            .foregroundColor(.misoTextPrimary)
                        Text(dayCount == 1 ? "Day" : "Days")
                            .font(.misoCaption)
                            .foregroundColor(.misoTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 8)

            if !deleteRange, let log = existingLog {
                Divider()
                    .padding(.vertical, 4)

                // Show log details
                HStack {
                    if log.flow.isPeriod {
                        HStack(spacing: 4) {
                            ForEach(0..<log.flow.dropCount, id: \.self) { _ in
                                Image(systemName: "drop.fill")
                                    .font(.caption)
                                    .foregroundColor(log.flow.color)
                            }
                        }
                        Text(log.flow.displayName)
                            .font(.misoSubheadline)
                            .foregroundColor(.misoTextSecondary)
                    }

                    Spacer()

                    Text(selectedDate.shortDateString)
                        .font(.misoSubheadline)
                        .foregroundColor(.misoTextTertiary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.red.opacity(0.1))
        )
    }

    // MARK: - No Logs Section
    private var noLogsSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.misoSecondary)

            Text("No logs found")
                .font(.misoHeadline)
                .foregroundColor(.misoTextPrimary)

            Text(deleteRange ? "No data logged for this date range" : "No data logged for this date")
                .font(.misoBody)
                .foregroundColor(.misoTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.misoBgCard)
        )
    }

    // MARK: - Success Overlay
    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Deleted!")
                .font(.misoTitle2)
                .foregroundColor(.misoTextPrimary)

            Text("\(logsToDeleteCount) log\(logsToDeleteCount == 1 ? "" : "s") removed")
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
    private var dayCount: Int {
        selectedDate.daysBetween(endDate) + 1
    }

    private var hasLogsToDelete: Bool {
        logsToDeleteCount > 0
    }

    // MARK: - Actions
    private func checkForExistingLog() {
        Task {
            if deleteRange {
                let logs = await viewModel.getLogs(from: selectedDate, to: endDate)
                await MainActor.run {
                    logsToDeleteCount = logs.count
                }
            } else {
                let log = await viewModel.getLog(for: selectedDate)
                await MainActor.run {
                    existingLog = log
                    logsToDeleteCount = log != nil ? 1 : 0
                }
            }
        }
    }

    private func deleteLogs() {
        Task {
            if deleteRange {
                let logs = await viewModel.getLogs(from: selectedDate, to: endDate)
                for log in logs {
                    await viewModel.deleteLog(log)
                }
            } else if let log = existingLog {
                await viewModel.deleteLog(log)
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
}

#Preview {
    DeleteLogView(viewModel: CycleViewModel.preview, isPresented: .constant(true))
}
