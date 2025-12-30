import Foundation
import CoreData
import Combine

/// Orchestrates all prediction and analysis services
class PredictionService: ObservableObject {
    // MARK: - Published Properties
    @Published var periodPrediction: CycleAnalyzer.PeriodPrediction?
    @Published var fertilityWindow: CycleAnalyzer.FertilityWindow?
    @Published var symptomPrediction: SymptomPredictor.DayPrediction?
    @Published var cycleStatistics: CycleAnalyzer.CycleStatistics?
    @Published var alerts: [IrregularityDetector.IrregularityAlert] = []
    @Published var isLoading = false

    // MARK: - Dependencies
    private let cycleAnalyzer = CycleAnalyzer()
    private let symptomPredictor = SymptomPredictor()
    private let irregularityDetector = IrregularityDetector()
    private let cycleService: CycleService

    // MARK: - Initialization
    init(cycleService: CycleService = CycleService()) {
        self.cycleService = cycleService
    }

    // MARK: - Main Update Method

    /// Refresh all predictions based on current data
    func updatePredictions() async {
        await MainActor.run { isLoading = true }

        do {
            let currentCycle = try cycleService.fetchActiveCycle()
            let allCycles = try cycleService.fetchAllCycles()
            let recentLogs = try cycleService.fetchRecentLogs(limit: 90)

            await MainActor.run {
                // Update cycle statistics
                self.cycleStatistics = cycleAnalyzer.analyzeHistory(cycles: allCycles)

                // Update period prediction
                if let current = currentCycle {
                    self.periodPrediction = cycleAnalyzer.predictNextPeriod(
                        currentCycle: current,
                        history: allCycles
                    )

                    // Update fertility window
                    let avgLength = Int(cycleStatistics?.averageCycleLength ?? 28)
                    self.fertilityWindow = cycleAnalyzer.calculateFertileWindow(
                        currentCycle: current,
                        averageCycleLength: avgLength
                    )

                    // Update symptom predictions
                    self.symptomPrediction = symptomPredictor.predictTodaySymptoms(
                        currentCycle: current,
                        logs: recentLogs,
                        cycles: allCycles
                    )
                }

                // Check for irregularities
                self.alerts = irregularityDetector.detectIrregularities(
                    cycles: allCycles,
                    currentCycle: currentCycle,
                    recentLogs: recentLogs
                )

                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            print("Error updating predictions: \(error)")
        }
    }

    // MARK: - Convenience Getters

    /// Days until next predicted period
    var daysUntilPeriod: Int? {
        periodPrediction?.daysUntil
    }

    /// Whether user is currently in fertile window
    var isInFertileWindow: Bool {
        fertilityWindow?.isActive ?? false
    }

    /// Days until fertile window starts (if not currently active)
    var daysUntilFertile: Int? {
        fertilityWindow?.daysUntilFertile
    }

    /// Top predicted symptoms for today
    var topPredictedSymptoms: [SymptomPredictor.SymptomPrediction] {
        symptomPrediction?.topSymptoms ?? []
    }

    /// Overall expected discomfort level for today
    var todayDiscomfortLevel: Double {
        symptomPrediction?.overallDiscomfortLevel ?? 0.0
    }

    /// Current cycle phase
    var currentPhase: CyclePhase {
        symptomPrediction?.phase ?? .follicular
    }

    /// Whether cycles are regular
    var hasRegularCycles: Bool {
        cycleStatistics?.isRegular ?? false
    }

    /// Prediction confidence (0-1)
    var predictionConfidence: Double {
        periodPrediction?.confidence ?? 0.5
    }

    /// Number of cycles used for predictions
    var cyclesAnalyzed: Int {
        cycleStatistics?.totalCyclesAnalyzed ?? 0
    }

    /// Whether there are any alerts that need attention
    var hasAlerts: Bool {
        !alerts.isEmpty
    }

    /// Most severe alert
    var topAlert: IrregularityDetector.IrregularityAlert? {
        alerts.first
    }

    // MARK: - Formatted Outputs

    /// Human-readable period prediction
    var periodPredictionText: String {
        guard let prediction = periodPrediction else {
            return "Log more cycles for predictions"
        }

        let days = prediction.daysUntil

        if days < 0 {
            return "Period may have started"
        } else if days == 0 {
            return "Period expected today"
        } else if days == 1 {
            return "Period expected tomorrow"
        } else {
            return "Period in \(days) days"
        }
    }

    /// Confidence text
    var confidenceText: String {
        let confidence = predictionConfidence

        switch confidence {
        case 0.8...: return "High confidence"
        case 0.6..<0.8: return "Good confidence"
        case 0.4..<0.6: return "Moderate confidence"
        default: return "Learning your patterns"
        }
    }

    /// Fertility status text
    var fertilityStatusText: String {
        if isInFertileWindow {
            return "Fertile window active"
        } else if let days = daysUntilFertile, days > 0 {
            return "Fertile window in \(days) days"
        } else {
            return "Not in fertile window"
        }
    }

    /// Phase-appropriate message
    var phaseMessage: String {
        currentPhase.description
    }

    // MARK: - Symptom Insights

    /// Get symptom likelihood description
    func symptomLikelihood(for symptom: SymptomType) -> String? {
        guard let prediction = symptomPrediction else { return nil }

        if let match = prediction.predictedSymptoms.first(where: { $0.symptom == symptom }) {
            return match.likelihoodDescription
        }

        return nil
    }

    /// Symptoms likely to occur today
    var likelySymptoms: [SymptomType] {
        topPredictedSymptoms
            .filter { $0.likelihood >= 0.4 }
            .map { $0.symptom }
    }

    /// Prepare for these symptoms message
    var symptomPrepMessage: String? {
        let likely = likelySymptoms

        if likely.isEmpty {
            return nil
        }

        let symptomNames = likely.prefix(3).map { $0.displayName.lowercased() }

        if symptomNames.count == 1 {
            return "You might experience \(symptomNames[0]) today"
        } else {
            let allButLast = symptomNames.dropLast().joined(separator: ", ")
            return "You might experience \(allButLast) or \(symptomNames.last!) today"
        }
    }
}

// MARK: - Preview Helper
extension PredictionService {
    static var preview: PredictionService {
        PredictionService(cycleService: CycleService(context: PersistenceController.preview.container.viewContext))
    }
}
