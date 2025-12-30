import Foundation
import CoreData

/// Predicts likely symptoms based on cycle day and historical patterns
class SymptomPredictor {

    // MARK: - Prediction Models

    struct SymptomPrediction {
        let symptom: SymptomType
        let likelihood: Double // 0-1
        let averageSeverity: Double // 1-3
        let basedOnOccurrences: Int

        var likelihoodDescription: String {
            switch likelihood {
            case 0.7...: return "Very Likely"
            case 0.5..<0.7: return "Likely"
            case 0.3..<0.5: return "Possible"
            default: return "Unlikely"
            }
        }
    }

    struct DayPrediction {
        let cycleDay: Int
        let phase: CyclePhase
        let predictedSymptoms: [SymptomPrediction]
        let overallDiscomfortLevel: Double // 0-1

        var topSymptoms: [SymptomPrediction] {
            predictedSymptoms
                .filter { $0.likelihood >= 0.3 }
                .sorted { $0.likelihood > $1.likelihood }
                .prefix(5)
                .map { $0 }
        }
    }

    // MARK: - Analysis

    /// Analyze historical symptoms to find patterns by cycle day
    func analyzeSymptomPatterns(logs: [DailyLog], cycles: [Cycle]) -> [Int: [SymptomType: (count: Int, totalSeverity: Int)]] {
        var patternsByDay: [Int: [SymptomType: (count: Int, totalSeverity: Int)]] = [:]

        for log in logs {
            guard let logDate = log.date,
                  let cycle = findCycle(for: logDate, in: cycles),
                  let cycleStart = cycle.startDate else { continue }

            let cycleDay = cycleStart.daysBetween(logDate) + 1

            // Only analyze days 1-35 (reasonable cycle range)
            guard cycleDay > 0 && cycleDay <= 35 else { continue }

            if patternsByDay[cycleDay] == nil {
                patternsByDay[cycleDay] = [:]
            }

            // Extract symptoms from this log
            if let symptoms = log.symptoms as? Set<Symptom> {
                for symptom in symptoms {
                    guard let typeString = symptom.type,
                          let symptomType = SymptomType(rawValue: typeString) else { continue }

                    var current = patternsByDay[cycleDay]?[symptomType] ?? (count: 0, totalSeverity: 0)
                    current.count += 1
                    current.totalSeverity += Int(symptom.severity)
                    patternsByDay[cycleDay]?[symptomType] = current
                }
            }
        }

        return patternsByDay
    }

    /// Predict symptoms for a specific cycle day
    func predictSymptoms(
        forCycleDay cycleDay: Int,
        patterns: [Int: [SymptomType: (count: Int, totalSeverity: Int)]],
        totalDaysAtCycleDay: [Int: Int],
        cycleLength: Int = 28
    ) -> DayPrediction {
        let phase = CyclePhase.from(cycleDay: cycleDay, cycleLength: cycleLength)

        // Get symptom data for this cycle day
        let dayPatterns = patterns[cycleDay] ?? [:]
        let totalDays = totalDaysAtCycleDay[cycleDay] ?? 1

        var predictions: [SymptomPrediction] = []

        for (symptom, data) in dayPatterns {
            let likelihood = Double(data.count) / Double(max(totalDays, 1))
            let avgSeverity = data.count > 0 ? Double(data.totalSeverity) / Double(data.count) : 1.0

            predictions.append(SymptomPrediction(
                symptom: symptom,
                likelihood: likelihood,
                averageSeverity: avgSeverity,
                basedOnOccurrences: data.count
            ))
        }

        // Add phase-based default predictions if no historical data
        if predictions.isEmpty {
            predictions = defaultPredictions(for: phase)
        }

        // Sort by likelihood
        predictions.sort { $0.likelihood > $1.likelihood }

        // Calculate overall discomfort level
        let discomfort = calculateDiscomfortLevel(predictions: predictions, phase: phase)

        return DayPrediction(
            cycleDay: cycleDay,
            phase: phase,
            predictedSymptoms: predictions,
            overallDiscomfortLevel: discomfort
        )
    }

    /// Get predictions for today based on current cycle
    func predictTodaySymptoms(currentCycle: Cycle, logs: [DailyLog], cycles: [Cycle]) -> DayPrediction? {
        guard let startDate = currentCycle.startDate else { return nil }

        let cycleDay = startDate.daysBetween(Date()) + 1
        guard cycleDay > 0 else { return nil }

        let patterns = analyzeSymptomPatterns(logs: logs, cycles: cycles)
        let daysCounted = countDaysAtEachCycleDay(logs: logs, cycles: cycles)

        return predictSymptoms(
            forCycleDay: cycleDay,
            patterns: patterns,
            totalDaysAtCycleDay: daysCounted,
            cycleLength: currentCycle.cycleLength > 0 ? Int(currentCycle.cycleLength) : 28
        )
    }

    // MARK: - Helpers

    private func findCycle(for date: Date, in cycles: [Cycle]) -> Cycle? {
        let targetDate = date.startOfDay

        for cycle in cycles {
            guard let startDate = cycle.startDate else { continue }

            // Check if date falls within this cycle
            if let nextCycleStart = cycles.first(where: {
                guard let start = $0.startDate else { return false }
                return start > startDate
            })?.startDate {
                if targetDate >= startDate && targetDate < nextCycleStart {
                    return cycle
                }
            } else {
                // This is the most recent/active cycle
                if targetDate >= startDate {
                    return cycle
                }
            }
        }

        return nil
    }

    private func countDaysAtEachCycleDay(logs: [DailyLog], cycles: [Cycle]) -> [Int: Int] {
        var counts: [Int: Int] = [:]

        for log in logs {
            guard let logDate = log.date,
                  let cycle = findCycle(for: logDate, in: cycles),
                  let cycleStart = cycle.startDate else { continue }

            let cycleDay = cycleStart.daysBetween(logDate) + 1
            guard cycleDay > 0 && cycleDay <= 35 else { continue }

            counts[cycleDay, default: 0] += 1
        }

        return counts
    }

    private func defaultPredictions(for phase: CyclePhase) -> [SymptomPrediction] {
        // Return typical symptoms for each phase when no personal data exists
        switch phase {
        case .menstrual:
            return [
                SymptomPrediction(symptom: .cramps, likelihood: 0.7, averageSeverity: 2.0, basedOnOccurrences: 0),
                SymptomPrediction(symptom: .fatigue, likelihood: 0.6, averageSeverity: 2.0, basedOnOccurrences: 0),
                SymptomPrediction(symptom: .bloating, likelihood: 0.5, averageSeverity: 1.5, basedOnOccurrences: 0),
                SymptomPrediction(symptom: .headache, likelihood: 0.4, averageSeverity: 1.5, basedOnOccurrences: 0),
                SymptomPrediction(symptom: .moodSwings, likelihood: 0.4, averageSeverity: 1.5, basedOnOccurrences: 0)
            ]

        case .follicular:
            return [
                SymptomPrediction(symptom: .fatigue, likelihood: 0.2, averageSeverity: 1.0, basedOnOccurrences: 0)
            ]

        case .ovulation:
            return [
                SymptomPrediction(symptom: .bloating, likelihood: 0.3, averageSeverity: 1.0, basedOnOccurrences: 0),
                SymptomPrediction(symptom: .breastTenderness, likelihood: 0.3, averageSeverity: 1.0, basedOnOccurrences: 0)
            ]

        case .luteal:
            return [
                SymptomPrediction(symptom: .bloating, likelihood: 0.5, averageSeverity: 1.5, basedOnOccurrences: 0),
                SymptomPrediction(symptom: .moodSwings, likelihood: 0.5, averageSeverity: 1.5, basedOnOccurrences: 0),
                SymptomPrediction(symptom: .fatigue, likelihood: 0.4, averageSeverity: 1.5, basedOnOccurrences: 0),
                SymptomPrediction(symptom: .cravings, likelihood: 0.4, averageSeverity: 1.5, basedOnOccurrences: 0),
                SymptomPrediction(symptom: .breastTenderness, likelihood: 0.4, averageSeverity: 1.5, basedOnOccurrences: 0),
                SymptomPrediction(symptom: .acne, likelihood: 0.3, averageSeverity: 1.0, basedOnOccurrences: 0)
            ]
        }
    }

    private func calculateDiscomfortLevel(predictions: [SymptomPrediction], phase: CyclePhase) -> Double {
        guard !predictions.isEmpty else {
            // Base discomfort by phase
            switch phase {
            case .menstrual: return 0.6
            case .luteal: return 0.4
            case .ovulation: return 0.2
            case .follicular: return 0.1
            }
        }

        // Weight by likelihood and severity
        let weightedSum = predictions.reduce(0.0) { sum, prediction in
            sum + (prediction.likelihood * prediction.averageSeverity / 3.0)
        }

        return min(1.0, weightedSum / Double(min(predictions.count, 5)))
    }
}
