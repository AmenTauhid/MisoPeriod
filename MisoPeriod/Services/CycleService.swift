import CoreData
import Foundation
import Combine

class CycleService: ObservableObject {
    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
    }

    // MARK: - Cycle Operations

    func createCycle(startDate: Date) throws -> Cycle {
        // End any currently active cycle
        if let activeCycle = try fetchActiveCycle() {
            activeCycle.isActive = false
            activeCycle.cycleLength = Int16(activeCycle.startDate!.daysBetween(startDate))
        }

        let cycle = Cycle(context: viewContext)
        cycle.id = UUID()
        cycle.startDate = startDate.startOfDay
        cycle.isActive = true

        // Calculate estimated ovulation and fertile window based on average cycle
        let settings = try fetchOrCreateUserSettings()
        let avgCycleLength = Int(settings.averageCycleLength)
        updateFertilityDates(for: cycle, cycleLength: avgCycleLength)

        try saveContext()
        return cycle
    }

    func endPeriod(for cycle: Cycle, endDate: Date) throws {
        cycle.endDate = endDate.startOfDay
        cycle.periodLength = Int16(cycle.startDate!.daysBetween(endDate) + 1)
        try saveContext()
    }

    func fetchActiveCycle() throws -> Cycle? {
        let request: NSFetchRequest<Cycle> = Cycle.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Cycle.startDate, ascending: false)]
        request.fetchLimit = 1
        return try viewContext.fetch(request).first
    }

    func fetchAllCycles() throws -> [Cycle] {
        let request: NSFetchRequest<Cycle> = Cycle.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Cycle.startDate, ascending: false)]
        return try viewContext.fetch(request)
    }

    func fetchCycles(limit: Int) throws -> [Cycle] {
        let request: NSFetchRequest<Cycle> = Cycle.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Cycle.startDate, ascending: false)]
        request.fetchLimit = limit
        return try viewContext.fetch(request)
    }

    func deleteCycle(_ cycle: Cycle) throws {
        viewContext.delete(cycle)
        try saveContext()
    }

    /// Create a historical cycle (not active) for logging past periods
    func createHistoricalCycle(startDate: Date) throws -> Cycle {
        let cycle = Cycle(context: viewContext)
        cycle.id = UUID()
        cycle.startDate = startDate.startOfDay
        cycle.isActive = false // Historical cycles are not active

        // Calculate estimated ovulation and fertile window based on average cycle
        let settings = try fetchOrCreateUserSettings()
        let avgCycleLength = Int(settings.averageCycleLength)
        updateFertilityDates(for: cycle, cycleLength: avgCycleLength)

        try saveContext()
        return cycle
    }

    /// Find or create a cycle that covers the given date
    func findOrCreateCycle(for date: Date) throws -> Cycle {
        let targetDate = date.startOfDay

        // First, check if there's an existing cycle that starts on this exact date
        let allCycles = try fetchAllCycles()

        for cycle in allCycles {
            guard let cycleStart = cycle.startDate else { continue }

            // Exact match - return this cycle
            if cycleStart.isSameDay(as: targetDate) {
                return cycle
            }
        }

        // Check if the date falls within an existing cycle's period (first ~7 days)
        for cycle in allCycles {
            guard let cycleStart = cycle.startDate else { continue }

            let daysSinceCycleStart = cycleStart.daysBetween(targetDate)

            // If within the first 7 days of a cycle, it's part of that cycle's period
            if daysSinceCycleStart >= 0 && daysSinceCycleStart <= 7 {
                return cycle
            }
        }

        // Check if this date is before all existing cycles (user logging historical period)
        if let oldestCycle = allCycles.last,
           let oldestStart = oldestCycle.startDate,
           targetDate < oldestStart {
            // Create a new historical cycle and calculate its length
            let newCycle = try createHistoricalCycle(startDate: targetDate)
            // The cycle length is the days until the next cycle starts
            newCycle.cycleLength = Int16(targetDate.daysBetween(oldestStart))
            try saveContext()
            return newCycle
        }

        // Check if this could be a NEW cycle (more than 18 days after last cycle start)
        if let newestCycle = allCycles.first,
           let newestStart = newestCycle.startDate {
            let daysSinceLastCycle = newestStart.daysBetween(targetDate)

            if daysSinceLastCycle >= 18 {
                // Mark the old cycle as complete with calculated length
                newestCycle.cycleLength = Int16(daysSinceLastCycle)
                newestCycle.isActive = false

                // Determine if this should be active (is it the most recent/current period?)
                let isCurrentPeriod = targetDate.daysBetween(Date()) <= 7

                // Create a new cycle
                let newCycle = Cycle(context: viewContext)
                newCycle.id = UUID()
                newCycle.startDate = targetDate
                newCycle.isActive = isCurrentPeriod

                let settings = try fetchOrCreateUserSettings()
                updateFertilityDates(for: newCycle, cycleLength: Int(settings.averageCycleLength))

                try saveContext()
                return newCycle
            }
        }

        // No existing cycles at all - create the first one
        if allCycles.isEmpty {
            // Determine if this should be active
            let isCurrentPeriod = targetDate.daysBetween(Date()) <= 7
            let newCycle = Cycle(context: viewContext)
            newCycle.id = UUID()
            newCycle.startDate = targetDate.startOfDay
            newCycle.isActive = isCurrentPeriod

            let settings = try fetchOrCreateUserSettings()
            updateFertilityDates(for: newCycle, cycleLength: Int(settings.averageCycleLength))

            try saveContext()
            return newCycle
        }

        // Default: associate with the most recent cycle
        return allCycles.first!
    }

    /// Recalculate cycle lengths for all cycles based on their sequence
    func recalculateCycleLengths() throws {
        let allCycles = try fetchAllCycles() // sorted by startDate descending

        // Go through cycles from oldest to newest and calculate lengths
        for i in stride(from: allCycles.count - 1, through: 1, by: -1) {
            let olderCycle = allCycles[i]
            let newerCycle = allCycles[i - 1]

            guard let olderStart = olderCycle.startDate,
                  let newerStart = newerCycle.startDate else { continue }

            let length = olderStart.daysBetween(newerStart)
            if length > 0 && length < 60 { // Sanity check
                olderCycle.cycleLength = Int16(length)
            }
        }

        // The most recent cycle shouldn't have a length yet (it's ongoing)
        // Unless it's historical and there's a newer active one

        // Ensure the most recent cycle with period data is active
        if let newestCycle = allCycles.first {
            // Check if any cycle is active
            let hasActive = allCycles.contains { $0.isActive }
            if !hasActive {
                newestCycle.isActive = true
            }
        }

        try saveContext()
    }

    // MARK: - Daily Log Operations

    func createOrUpdateDailyLog(
        date: Date,
        flowIntensity: FlowIntensity,
        mood: Int16? = nil,
        energy: Int16? = nil,
        symptoms: [(SymptomType, Int16)] = [],
        notes: String? = nil,
        cycle: Cycle? = nil
    ) throws -> DailyLog {
        let targetDate = date.startOfDay

        // Check if log exists for this date
        if let existingLog = try fetchDailyLog(for: targetDate) {
            existingLog.flowIntensity = flowIntensity.rawValue
            existingLog.mood = mood ?? existingLog.mood
            existingLog.energy = energy ?? existingLog.energy
            existingLog.notes = notes ?? existingLog.notes
            existingLog.updatedAt = Date()

            // Update symptoms
            if !symptoms.isEmpty {
                // Remove existing symptoms
                if let existingSymptoms = existingLog.symptoms as? Set<Symptom> {
                    existingSymptoms.forEach { viewContext.delete($0) }
                }
                // Add new symptoms
                for (type, severity) in symptoms {
                    let symptom = Symptom(context: viewContext)
                    symptom.id = UUID()
                    symptom.type = type.rawValue
                    symptom.severity = severity
                    symptom.timestamp = Date()
                    symptom.dailyLog = existingLog
                }
            }

            try saveContext()
            return existingLog
        }

        // Create new log
        let log = DailyLog(context: viewContext)
        log.id = UUID()
        log.date = targetDate
        log.flowIntensity = flowIntensity.rawValue
        log.mood = mood ?? 0
        log.energy = energy ?? 0
        log.notes = notes
        log.createdAt = Date()
        log.updatedAt = Date()
        log.cycle = cycle ?? (try? fetchActiveCycle())

        // Add symptoms
        for (type, severity) in symptoms {
            let symptom = Symptom(context: viewContext)
            symptom.id = UUID()
            symptom.type = type.rawValue
            symptom.severity = severity
            symptom.timestamp = Date()
            symptom.dailyLog = log
        }

        try saveContext()
        return log
    }

    func fetchDailyLog(for date: Date) throws -> DailyLog? {
        let targetDate = date.startOfDay
        let request: NSFetchRequest<DailyLog> = DailyLog.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", targetDate as NSDate)
        request.fetchLimit = 1
        return try viewContext.fetch(request).first
    }

    func fetchDailyLogs(from startDate: Date, to endDate: Date) throws -> [DailyLog] {
        let request: NSFetchRequest<DailyLog> = DailyLog.fetchRequest()
        request.predicate = NSPredicate(
            format: "date >= %@ AND date <= %@",
            startDate.startOfDay as NSDate,
            endDate.endOfDay as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyLog.date, ascending: true)]
        return try viewContext.fetch(request)
    }

    func fetchRecentLogs(limit: Int = 30) throws -> [DailyLog] {
        let request: NSFetchRequest<DailyLog> = DailyLog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DailyLog.date, ascending: false)]
        request.fetchLimit = limit
        return try viewContext.fetch(request)
    }

    func deleteDailyLog(_ log: DailyLog) throws {
        viewContext.delete(log)
        try saveContext()
    }

    // MARK: - User Settings Operations

    func fetchOrCreateUserSettings() throws -> UserSettings {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.fetchLimit = 1

        if let settings = try viewContext.fetch(request).first {
            return settings
        }

        let settings = UserSettings(context: viewContext)
        settings.id = UUID()
        settings.createdAt = Date()
        settings.averageCycleLength = 28
        settings.averagePeriodLength = 5
        settings.onboardingCompleted = false
        settings.loggingStreak = 0

        try saveContext()
        return settings
    }

    func updateUserSettings(cycleLength: Int16? = nil, periodLength: Int16? = nil, onboardingCompleted: Bool? = nil) throws {
        let settings = try fetchOrCreateUserSettings()
        if let cycleLength = cycleLength {
            settings.averageCycleLength = cycleLength
        }
        if let periodLength = periodLength {
            settings.averagePeriodLength = periodLength
        }
        if let onboardingCompleted = onboardingCompleted {
            settings.onboardingCompleted = onboardingCompleted
        }
        try saveContext()
    }

    func incrementLoggingStreak() throws {
        let settings = try fetchOrCreateUserSettings()
        settings.loggingStreak += 1
        try saveContext()
    }

    func resetLoggingStreak() throws {
        let settings = try fetchOrCreateUserSettings()
        settings.loggingStreak = 0
        try saveContext()
    }

    // MARK: - Prediction Operations

    func createPrediction(type: String, predictedDate: Date, confidence: Double, for cycle: Cycle, symptomType: String? = nil) throws -> Prediction {
        let prediction = Prediction(context: viewContext)
        prediction.id = UUID()
        prediction.type = type
        prediction.predictedDate = predictedDate
        prediction.confidence = confidence
        prediction.symptomType = symptomType
        prediction.createdAt = Date()
        prediction.cycle = cycle

        try saveContext()
        return prediction
    }

    func fetchPredictions(for cycle: Cycle) throws -> [Prediction] {
        let request: NSFetchRequest<Prediction> = Prediction.fetchRequest()
        request.predicate = NSPredicate(format: "cycle == %@", cycle)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Prediction.predictedDate, ascending: true)]
        return try viewContext.fetch(request)
    }

    // MARK: - Analytics Helpers

    func calculateAverageCycleLength() throws -> Double {
        let cycles = try fetchCycles(limit: 12)
        let completedCycles = cycles.filter { $0.cycleLength > 0 }
        guard !completedCycles.isEmpty else { return 28.0 }

        let total = completedCycles.reduce(0) { $0 + Int($1.cycleLength) }
        return Double(total) / Double(completedCycles.count)
    }

    func calculateAveragePeriodLength() throws -> Double {
        let cycles = try fetchCycles(limit: 12)
        let completedPeriods = cycles.filter { $0.periodLength > 0 }
        guard !completedPeriods.isEmpty else { return 5.0 }

        let total = completedPeriods.reduce(0) { $0 + Int($1.periodLength) }
        return Double(total) / Double(completedPeriods.count)
    }

    // MARK: - Fertility Calculations

    private func updateFertilityDates(for cycle: Cycle, cycleLength: Int) {
        guard let startDate = cycle.startDate else { return }

        // Ovulation typically occurs 14 days before next period
        let ovulationDay = cycleLength - 14
        cycle.ovulationDate = startDate.adding(days: ovulationDay - 1)

        // Fertile window: 5 days before ovulation to 1 day after
        cycle.fertileWindowStart = startDate.adding(days: ovulationDay - 6)
        cycle.fertileWindowEnd = startDate.adding(days: ovulationDay)
    }

    // MARK: - Core Data Helpers

    private func saveContext() throws {
        if viewContext.hasChanges {
            try viewContext.save()
        }
    }
}

// MARK: - Cycle Extension for computed properties
extension Cycle {
    var currentCycleDay: Int? {
        guard let startDate = startDate else { return nil }
        return startDate.daysBetween(Date()) + 1
    }

    var currentPhase: CyclePhase? {
        guard let cycleDay = currentCycleDay else { return nil }
        return CyclePhase.from(cycleDay: cycleDay, cycleLength: Int(cycleLength > 0 ? cycleLength : 28))
    }

    var isInPeriod: Bool {
        guard let startDate = startDate else { return false }
        if let endDate = endDate {
            return Date() >= startDate && Date() <= endDate
        }
        // If no end date, assume period lasts ~5 days
        let daysSinceStart = startDate.daysBetween(Date())
        return daysSinceStart >= 0 && daysSinceStart < 5
    }

    var isInFertileWindow: Bool {
        guard let start = fertileWindowStart, let end = fertileWindowEnd else { return false }
        let today = Date().startOfDay
        return today >= start && today <= end
    }

    var daysUntilNextPeriod: Int? {
        guard let startDate = startDate else { return nil }
        let cycleLen = cycleLength > 0 ? Int(cycleLength) : 28
        let nextPeriod = startDate.adding(days: cycleLen)
        return Date().startOfDay.daysBetween(nextPeriod)
    }
}

// MARK: - DailyLog Extension
extension DailyLog {
    var flow: FlowIntensity {
        FlowIntensity.from(flowIntensity)
    }

    var symptomTypes: [SymptomType] {
        guard let symptoms = symptoms as? Set<Symptom> else { return [] }
        return symptoms.compactMap { SymptomType(rawValue: $0.type ?? "") }
    }
}
