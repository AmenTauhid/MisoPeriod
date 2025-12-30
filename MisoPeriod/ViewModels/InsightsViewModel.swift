import Foundation
import CoreData
import Combine

@MainActor
class InsightsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var hasEnoughData = false

    // Cycle data
    @Published var cycleLengthData: [CycleLengthItem] = []
    @Published var periodLengthData: [PeriodLengthItem] = []
    @Published var averageCycleLength: Int = 0
    @Published var averagePeriodLength: Int = 0
    @Published var totalCycles: Int = 0
    @Published var regularityScore: Double = 0
    @Published var isRegular: Bool = false

    // Symptom data
    @Published var topSymptoms: [SymptomFrequency] = []
    @Published var symptomChartData: [SymptomFrequency] = []
    @Published var symptomsByPhase: [CyclePhase: [SymptomType]] = [:]

    // Mood/Energy data
    @Published var moodData: [DailyValue] = []
    @Published var energyData: [DailyValue] = []
    @Published var averageMood: Double = 0
    @Published var averageEnergy: Double = 0
    @Published var moodByPhase: [CyclePhase: Double] = [:]
    @Published var totalDaysLogged: Int = 0

    // MARK: - Data Models
    struct CycleLengthItem: Identifiable {
        let id = UUID()
        let index: Int
        let length: Int
        let startDate: Date
    }

    struct PeriodLengthItem: Identifiable {
        let id = UUID()
        let index: Int
        let length: Int
    }

    struct SymptomFrequency: Identifiable {
        let id = UUID()
        let symptom: SymptomType
        let count: Int
        let percentage: Double
    }

    struct DailyValue: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
    }

    // MARK: - Dependencies
    private let cycleService: CycleService

    // MARK: - Initialization
    init(cycleService: CycleService = CycleService()) {
        self.cycleService = cycleService
    }

    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let cycles = try cycleService.fetchAllCycles()
            let logs = try cycleService.fetchRecentLogs(limit: 90)

            // Process cycle data
            processCycleData(cycles)

            // Process symptom data
            processSymptomData(logs, cycles: cycles)

            // Process mood/energy data
            processMoodEnergyData(logs)

            // Determine if we have enough data
            hasEnoughData = totalCycles >= 2 || totalDaysLogged >= 7

        } catch {
            print("Error loading insights: \(error)")
        }
    }

    // MARK: - Cycle Processing
    private func processCycleData(_ cycles: [Cycle]) {
        let completedCycles = cycles.filter { $0.cycleLength > 0 }

        totalCycles = completedCycles.count

        guard !completedCycles.isEmpty else {
            averageCycleLength = 28
            averagePeriodLength = 5
            regularityScore = 0
            isRegular = false
            return
        }

        // Calculate averages
        let cycleLengths = completedCycles.map { Int($0.cycleLength) }
        let periodLengths = completedCycles.compactMap { $0.periodLength > 0 ? Int($0.periodLength) : nil }

        averageCycleLength = cycleLengths.isEmpty ? 28 : cycleLengths.reduce(0, +) / cycleLengths.count
        averagePeriodLength = periodLengths.isEmpty ? 5 : periodLengths.reduce(0, +) / periodLengths.count

        // Calculate regularity
        if cycleLengths.count > 1 {
            let mean = Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count)
            let variance = cycleLengths.map { pow(Double($0) - mean, 2) }.reduce(0, +) / Double(cycleLengths.count - 1)
            let coefficientOfVariation = variance > 0 ? sqrt(variance) / mean : 0
            regularityScore = max(0, min(1, 1 - coefficientOfVariation))
        } else {
            regularityScore = 0.5
        }

        isRegular = regularityScore >= 0.7

        // Build chart data (oldest to newest)
        let sortedCycles = completedCycles.sorted { ($0.startDate ?? Date()) < ($1.startDate ?? Date()) }

        cycleLengthData = sortedCycles.enumerated().map { index, cycle in
            CycleLengthItem(
                index: index + 1,
                length: Int(cycle.cycleLength),
                startDate: cycle.startDate ?? Date()
            )
        }

        periodLengthData = sortedCycles.enumerated().compactMap { index, cycle in
            guard cycle.periodLength > 0 else { return nil }
            return PeriodLengthItem(
                index: index + 1,
                length: Int(cycle.periodLength)
            )
        }
    }

    // MARK: - Symptom Processing
    private func processSymptomData(_ logs: [DailyLog], cycles: [Cycle]) {
        // Count symptom occurrences
        var symptomCounts: [SymptomType: Int] = [:]

        for log in logs {
            for symptomType in log.symptomTypes {
                symptomCounts[symptomType, default: 0] += 1
            }
        }

        let maxCount = symptomCounts.values.max() ?? 1

        // Create sorted list
        let sortedSymptoms = symptomCounts.sorted { $0.value > $1.value }

        topSymptoms = sortedSymptoms.map { symptom, count in
            SymptomFrequency(
                symptom: symptom,
                count: count,
                percentage: Double(count) / Double(maxCount)
            )
        }

        symptomChartData = topSymptoms

        // Group symptoms by phase
        var phaseSymptoms: [CyclePhase: [SymptomType: Int]] = [:]

        for log in logs {
            guard let date = log.date else { continue }

            // Find the cycle this log belongs to
            let phase = determinePhase(for: date, in: cycles)

            if phaseSymptoms[phase] == nil {
                phaseSymptoms[phase] = [:]
            }

            for symptomType in log.symptomTypes {
                phaseSymptoms[phase]![symptomType, default: 0] += 1
            }
        }

        // Convert to top symptoms per phase
        symptomsByPhase = [:]
        for (phase, symptoms) in phaseSymptoms {
            let sorted = symptoms.sorted { $0.value > $1.value }
            symptomsByPhase[phase] = sorted.prefix(4).map { $0.key }
        }
    }

    // MARK: - Mood/Energy Processing
    private func processMoodEnergyData(_ logs: [DailyLog]) {
        totalDaysLogged = logs.count

        // Filter logs with mood/energy data
        let moodLogs = logs.filter { $0.mood > 0 }
        let energyLogs = logs.filter { $0.energy > 0 }

        // Calculate averages
        if !moodLogs.isEmpty {
            averageMood = Double(moodLogs.reduce(0) { $0 + Int($1.mood) }) / Double(moodLogs.count)
        }

        if !energyLogs.isEmpty {
            averageEnergy = Double(energyLogs.reduce(0) { $0 + Int($1.energy) }) / Double(energyLogs.count)
        }

        // Build chart data (last 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let recentMoodLogs = moodLogs
            .filter { ($0.date ?? Date()) >= thirtyDaysAgo }
            .sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }

        let recentEnergyLogs = energyLogs
            .filter { ($0.date ?? Date()) >= thirtyDaysAgo }
            .sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }

        moodData = recentMoodLogs.map { log in
            DailyValue(date: log.date ?? Date(), value: Double(log.mood))
        }

        energyData = recentEnergyLogs.map { log in
            DailyValue(date: log.date ?? Date(), value: Double(log.energy))
        }

        // Calculate mood by phase
        moodByPhase = [:]
        var phaseMoodSums: [CyclePhase: (total: Int, count: Int)] = [:]

        for log in moodLogs {
            guard log.mood > 0, let date = log.date else { continue }

            // Determine phase based on cycle day
            if let cycle = log.cycle, let startDate = cycle.startDate {
                let cycleDay = startDate.daysBetween(date) + 1
                let cycleLength = cycle.cycleLength > 0 ? Int(cycle.cycleLength) : 28
                let phase = CyclePhase.from(cycleDay: cycleDay, cycleLength: cycleLength)

                if phaseMoodSums[phase] == nil {
                    phaseMoodSums[phase] = (0, 0)
                }
                phaseMoodSums[phase]!.total += Int(log.mood)
                phaseMoodSums[phase]!.count += 1
            }
        }

        for (phase, data) in phaseMoodSums {
            if data.count > 0 {
                moodByPhase[phase] = Double(data.total) / Double(data.count)
            }
        }
    }

    // MARK: - Helpers
    private func determinePhase(for date: Date, in cycles: [Cycle]) -> CyclePhase {
        // Find the cycle this date belongs to
        for cycle in cycles {
            guard let startDate = cycle.startDate else { continue }

            let daysSinceStart = startDate.daysBetween(date)
            let cycleLength = cycle.cycleLength > 0 ? Int(cycle.cycleLength) : 28

            if daysSinceStart >= 0 && daysSinceStart < cycleLength {
                return CyclePhase.from(cycleDay: daysSinceStart + 1, cycleLength: cycleLength)
            }
        }

        return .follicular
    }

    var regularityDescription: String {
        if regularityScore >= 0.8 {
            return "Your cycles are very consistent. Great for accurate predictions!"
        } else if regularityScore >= 0.6 {
            return "Your cycles are fairly regular with some variation."
        } else if regularityScore >= 0.4 {
            return "Your cycles vary moderately. This is normal for many people."
        } else {
            return "Your cycles show significant variation. Consider tracking more data."
        }
    }
}
