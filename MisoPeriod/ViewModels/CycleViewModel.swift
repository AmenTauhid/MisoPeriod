import CoreData
import Foundation
import SwiftUI
import Combine

@MainActor
class CycleViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentCycle: Cycle?
    @Published var recentCycles: [Cycle] = []
    @Published var todayLog: DailyLog?
    @Published var userSettings: UserSettings?
    @Published var isLoading = false
    @Published var error: String?
    @Published var showingAffirmation = false
    @Published var currentAffirmation: String = ""

    // MARK: - Dependencies
    private let cycleService: CycleService

    // MARK: - Computed Properties
    var currentPhase: CyclePhase {
        currentCycle?.currentPhase ?? .follicular
    }

    var cycleDay: Int {
        currentCycle?.currentCycleDay ?? 1
    }

    var daysUntilPeriod: Int? {
        currentCycle?.daysUntilNextPeriod
    }

    var isOnPeriod: Bool {
        currentCycle?.isInPeriod ?? false
    }

    var isInFertileWindow: Bool {
        currentCycle?.isInFertileWindow ?? false
    }

    var hasLoggedToday: Bool {
        todayLog != nil
    }

    var averageCycleLength: Int {
        Int(userSettings?.averageCycleLength ?? 28)
    }

    var loggingStreak: Int {
        Int(userSettings?.loggingStreak ?? 0)
    }

    var hasCompletedOnboarding: Bool {
        userSettings?.onboardingCompleted ?? false
    }

    var nextPeriodDate: Date? {
        guard let startDate = currentCycle?.startDate else { return nil }
        let cycleLength = currentCycle?.cycleLength ?? 28
        return startDate.adding(days: Int(cycleLength > 0 ? cycleLength : 28))
    }

    var fertileWindowDates: (start: Date, end: Date)? {
        guard let start = currentCycle?.fertileWindowStart,
              let end = currentCycle?.fertileWindowEnd else { return nil }
        return (start, end)
    }

    // MARK: - Initialization
    init(cycleService: CycleService = CycleService()) {
        self.cycleService = cycleService
        Task {
            await loadData()
        }
    }

    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            currentCycle = try cycleService.fetchActiveCycle()
            recentCycles = try cycleService.fetchCycles(limit: 6)
            todayLog = try cycleService.fetchDailyLog(for: Date())
            userSettings = try cycleService.fetchOrCreateUserSettings()
            updateAffirmation()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func refresh() async {
        await loadData()
    }

    // MARK: - Period Actions
    func startPeriod(date: Date = Date()) async {
        do {
            currentCycle = try cycleService.createCycle(startDate: date)
            // Also create a daily log for the start date
            _ = try cycleService.createOrUpdateDailyLog(
                date: date,
                flowIntensity: .medium,
                cycle: currentCycle
            )
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func endPeriod(date: Date = Date()) async {
        guard let cycle = currentCycle else { return }
        do {
            try cycleService.endPeriod(for: cycle, endDate: date)
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Logging Actions
    func logToday(
        flow: FlowIntensity,
        mood: Int16? = nil,
        energy: Int16? = nil,
        symptoms: [(SymptomType, Int16)] = [],
        notes: String? = nil
    ) async {
        do {
            todayLog = try cycleService.createOrUpdateDailyLog(
                date: Date(),
                flowIntensity: flow,
                mood: mood,
                energy: energy,
                symptoms: symptoms,
                notes: notes,
                cycle: currentCycle
            )

            // Update streak
            try cycleService.incrementLoggingStreak()
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func logForDate(
        date: Date,
        flow: FlowIntensity,
        mood: Int16? = nil,
        energy: Int16? = nil,
        symptoms: [(SymptomType, Int16)] = [],
        notes: String? = nil
    ) async {
        do {
            _ = try cycleService.createOrUpdateDailyLog(
                date: date,
                flowIntensity: flow,
                mood: mood,
                energy: energy,
                symptoms: symptoms,
                notes: notes,
                cycle: currentCycle
            )
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Settings Actions
    func completeOnboarding(cycleLength: Int, periodLength: Int, lastPeriodStart: Date) async {
        do {
            try cycleService.updateUserSettings(
                cycleLength: Int16(cycleLength),
                periodLength: Int16(periodLength),
                onboardingCompleted: true
            )

            // Create initial cycle from last period
            currentCycle = try cycleService.createCycle(startDate: lastPeriodStart)

            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateSettings(cycleLength: Int? = nil, periodLength: Int? = nil) async {
        do {
            try cycleService.updateUserSettings(
                cycleLength: cycleLength.map { Int16($0) },
                periodLength: periodLength.map { Int16($0) }
            )
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Affirmation
    func updateAffirmation() {
        currentAffirmation = currentPhase.randomAffirmation()
    }

    func showNewAffirmation() {
        withAnimation(.spring(response: 0.3)) {
            showingAffirmation = true
            updateAffirmation()
        }

        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut) {
                self.showingAffirmation = false
            }
        }
    }

    // MARK: - Helper Methods
    func getLog(for date: Date) async -> DailyLog? {
        do {
            return try cycleService.fetchDailyLog(for: date)
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }

    func getLogs(from startDate: Date, to endDate: Date) async -> [DailyLog] {
        do {
            return try cycleService.fetchDailyLogs(from: startDate, to: endDate)
        } catch {
            self.error = error.localizedDescription
            return []
        }
    }

    func deleteLog(_ log: DailyLog) async {
        do {
            try cycleService.deleteDailyLog(log)
            await loadData()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Preview Helper
extension CycleViewModel {
    static var preview: CycleViewModel {
        let vm = CycleViewModel(cycleService: CycleService(context: PersistenceController.preview.container.viewContext))
        return vm
    }
}
