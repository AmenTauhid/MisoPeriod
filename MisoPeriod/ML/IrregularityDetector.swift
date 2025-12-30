import Foundation
import SwiftUI

/// Detects cycle irregularities and generates health alerts
class IrregularityDetector {

    // MARK: - Alert Types

    enum AlertSeverity: Comparable {
        case info
        case mild
        case moderate
        case concern

        var color: Color {
            switch self {
            case .info: return .misoAccent
            case .mild: return .misoSecondary
            case .moderate: return .orange
            case .concern: return .red
            }
        }

        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .mild: return "exclamationmark.circle.fill"
            case .moderate: return "exclamationmark.triangle.fill"
            case .concern: return "exclamationmark.octagon.fill"
            }
        }
    }

    struct IrregularityAlert: Identifiable {
        let id = UUID()
        let type: AlertType
        let severity: AlertSeverity
        let title: String
        let message: String
        let recommendation: String
        let detectedDate: Date

        enum AlertType: String {
            case longCycle
            case shortCycle
            case missedPeriod
            case highVariance
            case heavyFlow
            case prolongedPeriod
            case irregularPattern
            case newSymptom
        }
    }

    // MARK: - Detection Constants

    private let normalCycleRange = 21...35
    private let normalPeriodLength = 2...7
    private let highVarianceThreshold = 7.0 // days
    private let missedPeriodThreshold = 7 // days past expected

    // MARK: - Detection Methods

    /// Analyze cycles and logs for irregularities
    func detectIrregularities(
        cycles: [Cycle],
        currentCycle: Cycle?,
        recentLogs: [DailyLog]
    ) -> [IrregularityAlert] {
        var alerts: [IrregularityAlert] = []

        // Check cycle length irregularities
        alerts.append(contentsOf: checkCycleLengths(cycles: cycles))

        // Check for missed period
        if let current = currentCycle {
            if let missedAlert = checkMissedPeriod(currentCycle: current, history: cycles) {
                alerts.append(missedAlert)
            }
        }

        // Check cycle variance
        if let varianceAlert = checkCycleVariance(cycles: cycles) {
            alerts.append(varianceAlert)
        }

        // Check period characteristics
        alerts.append(contentsOf: checkPeriodCharacteristics(cycles: cycles, logs: recentLogs))

        // Sort by severity (most concerning first)
        alerts.sort { $0.severity > $1.severity }

        return alerts
    }

    /// Quick check if current situation needs attention
    func needsAttention(currentCycle: Cycle?, history: [Cycle]) -> Bool {
        guard let current = currentCycle else { return false }

        // Check if period is significantly late
        if let prediction = predictedPeriodDate(currentCycle: current, history: history) {
            let daysLate = prediction.daysBetween(Date())
            if daysLate > missedPeriodThreshold {
                return true
            }
        }

        return false
    }

    // MARK: - Private Detection Methods

    private func checkCycleLengths(cycles: [Cycle]) -> [IrregularityAlert] {
        var alerts: [IrregularityAlert] = []

        for cycle in cycles.prefix(3) { // Check last 3 cycles
            guard cycle.cycleLength > 0 else { continue }
            let length = Int(cycle.cycleLength)

            if length < normalCycleRange.lowerBound {
                alerts.append(IrregularityAlert(
                    type: .shortCycle,
                    severity: length < 18 ? .moderate : .mild,
                    title: "Short Cycle Detected",
                    message: "Your cycle was \(length) days, which is shorter than typical (21-35 days).",
                    recommendation: "Short cycles occasionally happen due to stress, travel, or hormonal changes. If this continues, consider tracking more details or consulting a healthcare provider.",
                    detectedDate: cycle.startDate ?? Date()
                ))
            } else if length > normalCycleRange.upperBound {
                alerts.append(IrregularityAlert(
                    type: .longCycle,
                    severity: length > 45 ? .moderate : .mild,
                    title: "Long Cycle Detected",
                    message: "Your cycle was \(length) days, which is longer than typical (21-35 days).",
                    recommendation: "Longer cycles can be normal for some people. Stress, weight changes, or exercise can affect cycle length. Monitor for patterns.",
                    detectedDate: cycle.startDate ?? Date()
                ))
            }
        }

        return alerts
    }

    private func checkMissedPeriod(currentCycle: Cycle, history: [Cycle]) -> IrregularityAlert? {
        guard let startDate = currentCycle.startDate else { return nil }

        // Calculate expected period date
        let avgLength = calculateAverageCycleLength(cycles: history)
        let expectedDate = startDate.adding(days: avgLength)
        let today = Date().startOfDay

        // Check if we're past the expected date
        let daysLate = expectedDate.daysBetween(today)

        if daysLate > missedPeriodThreshold {
            let severity: AlertSeverity = daysLate > 14 ? .moderate : .mild

            return IrregularityAlert(
                type: .missedPeriod,
                severity: severity,
                title: "Period May Be Late",
                message: "Your period is about \(daysLate) days later than expected based on your history.",
                recommendation: "Late periods can happen due to stress, lifestyle changes, or other factors. If you're sexually active and this is unusual for you, consider taking a pregnancy test.",
                detectedDate: today
            )
        }

        return nil
    }

    private func checkCycleVariance(cycles: [Cycle]) -> IrregularityAlert? {
        let completedCycles = cycles.filter { $0.cycleLength > 0 }
        guard completedCycles.count >= 3 else { return nil }

        let lengths = completedCycles.prefix(6).map { Double($0.cycleLength) }
        let mean = lengths.reduce(0, +) / Double(lengths.count)
        let variance = lengths.map { pow($0 - mean, 2) }.reduce(0, +) / Double(lengths.count)
        let stdDev = sqrt(variance)

        if stdDev > highVarianceThreshold {
            return IrregularityAlert(
                type: .highVariance,
                severity: stdDev > 10 ? .moderate : .mild,
                title: "Irregular Cycle Pattern",
                message: "Your cycle lengths vary by about \(Int(stdDev)) days on average, which suggests some irregularity.",
                recommendation: "Some variation is normal, but consistent irregularity might be worth discussing with a healthcare provider, especially if it's new.",
                detectedDate: Date()
            )
        }

        return nil
    }

    private func checkPeriodCharacteristics(cycles: [Cycle], logs: [DailyLog]) -> [IrregularityAlert] {
        var alerts: [IrregularityAlert] = []

        // Check recent cycles for period length issues
        for cycle in cycles.prefix(2) {
            if cycle.periodLength > 0 {
                let periodLength = Int(cycle.periodLength)

                if periodLength > normalPeriodLength.upperBound {
                    alerts.append(IrregularityAlert(
                        type: .prolongedPeriod,
                        severity: periodLength > 10 ? .moderate : .mild,
                        title: "Longer Period Duration",
                        message: "Your period lasted \(periodLength) days, which is longer than typical (2-7 days).",
                        recommendation: "Occasional longer periods can be normal. If this is a new pattern or accompanied by heavy bleeding, consider consulting a healthcare provider.",
                        detectedDate: cycle.startDate ?? Date()
                    ))
                }
            }
        }

        // Check for consistently heavy flow
        let heavyFlowDays = logs.filter { $0.flowIntensity == FlowIntensity.heavy.rawValue }
        if heavyFlowDays.count >= 3 {
            let recentHeavyDays = heavyFlowDays.filter {
                guard let date = $0.date else { return false }
                return date.daysBetween(Date()) <= 30
            }

            if recentHeavyDays.count >= 3 {
                alerts.append(IrregularityAlert(
                    type: .heavyFlow,
                    severity: .info,
                    title: "Heavy Flow Days Noted",
                    message: "You've logged several days of heavy flow recently.",
                    recommendation: "Some heavy days are normal. Stay hydrated and rest when needed. If you're soaking through protection hourly, consider consulting a healthcare provider.",
                    detectedDate: Date()
                ))
            }
        }

        return alerts
    }

    // MARK: - Helpers

    private func calculateAverageCycleLength(cycles: [Cycle]) -> Int {
        let completed = cycles.filter { $0.cycleLength > 0 }
        guard !completed.isEmpty else { return 28 }

        let total = completed.prefix(6).reduce(0) { $0 + Int($1.cycleLength) }
        return total / min(completed.count, 6)
    }

    private func predictedPeriodDate(currentCycle: Cycle, history: [Cycle]) -> Date? {
        guard let startDate = currentCycle.startDate else { return nil }
        let avgLength = calculateAverageCycleLength(cycles: history)
        return startDate.adding(days: avgLength)
    }
}
