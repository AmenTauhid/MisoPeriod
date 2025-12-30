import Foundation
import CoreData

/// Handles exporting user data to JSON format
class DataExportService {
    private let cycleService: CycleService

    init(cycleService: CycleService = CycleService()) {
        self.cycleService = cycleService
    }

    // MARK: - Export Models
    struct ExportData: Codable {
        let exportDate: Date
        let appVersion: String
        let cycles: [ExportCycle]
        let dailyLogs: [ExportDailyLog]
        let settings: ExportSettings
    }

    struct ExportCycle: Codable {
        let id: String
        let startDate: Date
        let endDate: Date?
        let cycleLength: Int
        let periodLength: Int
        let isActive: Bool
    }

    struct ExportDailyLog: Codable {
        let id: String
        let date: Date
        let flowIntensity: Int
        let mood: Int
        let energy: Int
        let symptoms: [ExportSymptom]
        let notes: String?
    }

    struct ExportSymptom: Codable {
        let type: String
        let severity: Int
    }

    struct ExportSettings: Codable {
        let averageCycleLength: Int
        let averagePeriodLength: Int
        let loggingStreak: Int
    }

    // MARK: - Export
    func exportAllData() throws -> Data {
        let cycles = try cycleService.fetchAllCycles()
        let logs = try cycleService.fetchRecentLogs(limit: 1000) // Get all logs
        let settings = try cycleService.fetchOrCreateUserSettings()

        let exportData = ExportData(
            exportDate: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            cycles: cycles.map { exportCycle($0) },
            dailyLogs: logs.map { exportDailyLog($0) },
            settings: ExportSettings(
                averageCycleLength: Int(settings.averageCycleLength),
                averagePeriodLength: Int(settings.averagePeriodLength),
                loggingStreak: Int(settings.loggingStreak)
            )
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(exportData)
    }

    func exportToFile() throws -> URL {
        let data = try exportAllData()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())

        let fileName = "MisoPeriod_Export_\(dateString).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try data.write(to: tempURL)

        return tempURL
    }

    // MARK: - Helpers
    private func exportCycle(_ cycle: Cycle) -> ExportCycle {
        ExportCycle(
            id: cycle.id?.uuidString ?? UUID().uuidString,
            startDate: cycle.startDate ?? Date(),
            endDate: cycle.endDate,
            cycleLength: Int(cycle.cycleLength),
            periodLength: Int(cycle.periodLength),
            isActive: cycle.isActive
        )
    }

    private func exportDailyLog(_ log: DailyLog) -> ExportDailyLog {
        let symptoms: [ExportSymptom]
        if let symptomSet = log.symptoms as? Set<Symptom> {
            symptoms = symptomSet.map { symptom in
                ExportSymptom(
                    type: symptom.type ?? "",
                    severity: Int(symptom.severity)
                )
            }
        } else {
            symptoms = []
        }

        return ExportDailyLog(
            id: log.id?.uuidString ?? UUID().uuidString,
            date: log.date ?? Date(),
            flowIntensity: Int(log.flowIntensity),
            mood: Int(log.mood),
            energy: Int(log.energy),
            symptoms: symptoms,
            notes: log.notes
        )
    }

    // MARK: - Summary for sharing
    func generateSummary() throws -> String {
        let cycles = try cycleService.fetchAllCycles()
        let settings = try cycleService.fetchOrCreateUserSettings()

        let completedCycles = cycles.filter { $0.cycleLength > 0 }
        let avgCycleLength = completedCycles.isEmpty ? 28 :
            completedCycles.reduce(0) { $0 + Int($1.cycleLength) } / completedCycles.count

        var summary = """
        MisoPeriod Summary
        ==================

        Average Cycle: \(avgCycleLength) days
        Average Period: \(settings.averagePeriodLength) days
        Cycles Tracked: \(completedCycles.count)

        """

        // Add next period prediction if available
        if let activeCycle = cycles.first(where: { $0.isActive }),
           let startDate = activeCycle.startDate {
            let nextPeriod = startDate.adding(days: avgCycleLength)
            let daysUntil = Date().startOfDay.daysBetween(nextPeriod)

            if daysUntil > 0 {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                summary += """
                Next Period: \(dateFormatter.string(from: nextPeriod))
                (in \(daysUntil) days)

                """
            }
        }

        summary += """

        Generated: \(Date().formatted())
        """

        return summary
    }
}
