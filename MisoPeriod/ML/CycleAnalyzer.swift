import Foundation
import CoreData

/// Analyzes cycle data to extract patterns and statistics
class CycleAnalyzer {

    // MARK: - Cycle Statistics

    struct CycleStatistics {
        let averageCycleLength: Double
        let averagePeriodLength: Double
        let cycleLengthVariance: Double
        let shortestCycle: Int
        let longestCycle: Int
        let totalCyclesAnalyzed: Int
        let regularityScore: Double // 0-1, higher is more regular

        var isRegular: Bool {
            regularityScore >= 0.7
        }

        var cycleLengthRange: ClosedRange<Int> {
            shortestCycle...longestCycle
        }
    }

    struct PeriodPrediction {
        let predictedStartDate: Date
        let confidenceInterval: (early: Date, late: Date)
        let confidence: Double // 0-1
        let basedOnCycles: Int

        var daysUntil: Int {
            Date().startOfDay.daysBetween(predictedStartDate)
        }
    }

    struct FertilityWindow {
        let startDate: Date
        let endDate: Date
        let ovulationDate: Date
        let peakFertilityDays: [Date]

        var isActive: Bool {
            let today = Date().startOfDay
            return today >= startDate && today <= endDate
        }

        var daysUntilFertile: Int? {
            let today = Date().startOfDay
            if today < startDate {
                return today.daysBetween(startDate)
            }
            return nil
        }
    }

    // MARK: - Analysis Methods

    /// Calculate comprehensive statistics from cycle history
    func analyzeHistory(cycles: [Cycle]) -> CycleStatistics? {
        // Filter to completed cycles with valid lengths
        let completedCycles = cycles.filter { $0.cycleLength > 0 }

        guard !completedCycles.isEmpty else {
            return nil
        }

        let lengths = completedCycles.map { Int($0.cycleLength) }
        let periodLengths = completedCycles.compactMap { $0.periodLength > 0 ? Int($0.periodLength) : nil }

        let avgCycle = Double(lengths.reduce(0, +)) / Double(lengths.count)
        let avgPeriod = periodLengths.isEmpty ? 5.0 : Double(periodLengths.reduce(0, +)) / Double(periodLengths.count)

        // Calculate variance
        let variance = calculateVariance(values: lengths.map { Double($0) }, mean: avgCycle)

        // Calculate regularity score (inverse of coefficient of variation)
        let coefficientOfVariation = variance > 0 ? sqrt(variance) / avgCycle : 0
        let regularityScore = max(0, min(1, 1 - coefficientOfVariation))

        return CycleStatistics(
            averageCycleLength: avgCycle,
            averagePeriodLength: avgPeriod,
            cycleLengthVariance: variance,
            shortestCycle: lengths.min() ?? 21,
            longestCycle: lengths.max() ?? 35,
            totalCyclesAnalyzed: completedCycles.count,
            regularityScore: regularityScore
        )
    }

    /// Predict next period using weighted moving average
    func predictNextPeriod(currentCycle: Cycle, history: [Cycle]) -> PeriodPrediction? {
        guard let cycleStart = currentCycle.startDate else { return nil }

        // Get completed cycles for analysis
        let completedCycles = history.filter { $0.cycleLength > 0 }

        // Default prediction if no history
        if completedCycles.isEmpty {
            let defaultLength = 28
            return PeriodPrediction(
                predictedStartDate: cycleStart.adding(days: defaultLength),
                confidenceInterval: (
                    early: cycleStart.adding(days: defaultLength - 3),
                    late: cycleStart.adding(days: defaultLength + 3)
                ),
                confidence: 0.5,
                basedOnCycles: 0
            )
        }

        // Calculate weighted average (more recent cycles weighted higher)
        let predictedLength = calculateWeightedAverage(cycles: completedCycles)
        let predictedDate = cycleStart.adding(days: predictedLength)

        // Calculate confidence based on regularity
        let stats = analyzeHistory(cycles: completedCycles)
        let confidence = stats?.regularityScore ?? 0.5

        // Calculate confidence interval based on variance
        let variance = stats?.cycleLengthVariance ?? 9.0
        let stdDev = sqrt(variance)
        let margin = Int(ceil(stdDev * 1.5)) // ~87% confidence interval

        return PeriodPrediction(
            predictedStartDate: predictedDate,
            confidenceInterval: (
                early: cycleStart.adding(days: predictedLength - margin),
                late: cycleStart.adding(days: predictedLength + margin)
            ),
            confidence: confidence,
            basedOnCycles: completedCycles.count
        )
    }

    /// Calculate fertile window based on cycle data
    func calculateFertileWindow(currentCycle: Cycle, averageCycleLength: Int) -> FertilityWindow? {
        guard let cycleStart = currentCycle.startDate else { return nil }

        // Ovulation typically occurs 14 days before the next period
        // This is more consistent than counting from cycle start
        let ovulationDay = averageCycleLength - 14
        let ovulationDate = cycleStart.adding(days: ovulationDay - 1)

        // Fertile window: 5 days before ovulation to 1 day after
        // Sperm can survive 5 days, egg survives 12-24 hours
        let fertileStart = ovulationDate.adding(days: -5)
        let fertileEnd = ovulationDate.adding(days: 1)

        // Peak fertility: 2 days before and day of ovulation
        let peakDays = [
            ovulationDate.adding(days: -2),
            ovulationDate.adding(days: -1),
            ovulationDate
        ]

        return FertilityWindow(
            startDate: fertileStart,
            endDate: fertileEnd,
            ovulationDate: ovulationDate,
            peakFertilityDays: peakDays
        )
    }

    /// Calculate which cycle day we're currently on
    func currentCycleDay(for cycle: Cycle) -> Int? {
        guard let startDate = cycle.startDate else { return nil }
        return startDate.daysBetween(Date()) + 1
    }

    /// Determine current cycle phase
    func currentPhase(for cycle: Cycle, cycleLength: Int = 28) -> CyclePhase {
        guard let cycleDay = currentCycleDay(for: cycle) else { return .follicular }
        return CyclePhase.from(cycleDay: cycleDay, cycleLength: cycleLength)
    }

    // MARK: - Private Helpers

    private func calculateWeightedAverage(cycles: [Cycle], maxCycles: Int = 6) -> Int {
        // Take most recent cycles
        let recentCycles = Array(cycles.prefix(maxCycles))

        guard !recentCycles.isEmpty else { return 28 }

        // Assign weights: most recent gets highest weight
        // Weights: 6, 5, 4, 3, 2, 1 for last 6 cycles
        var totalWeight = 0.0
        var weightedSum = 0.0

        for (index, cycle) in recentCycles.enumerated() {
            let weight = Double(recentCycles.count - index)
            weightedSum += Double(cycle.cycleLength) * weight
            totalWeight += weight
        }

        return Int(round(weightedSum / totalWeight))
    }

    private func calculateVariance(values: [Double], mean: Double) -> Double {
        guard values.count > 1 else { return 0 }

        let squaredDifferences = values.map { pow($0 - mean, 2) }
        return squaredDifferences.reduce(0, +) / Double(values.count - 1)
    }
}

// MARK: - Cycle Extension for Analysis
extension Cycle {
    var analyzedPhase: CyclePhase {
        let analyzer = CycleAnalyzer()
        return analyzer.currentPhase(for: self, cycleLength: cycleLength > 0 ? Int(cycleLength) : 28)
    }
}
