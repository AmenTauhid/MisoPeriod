import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create user settings
        let settings = UserSettings(context: viewContext)
        settings.id = UUID()
        settings.createdAt = Date()
        settings.averageCycleLength = 28
        settings.averagePeriodLength = 5
        settings.onboardingCompleted = true
        settings.loggingStreak = 5

        // Create a sample cycle (started 10 days ago)
        let cycle = Cycle(context: viewContext)
        cycle.id = UUID()
        cycle.startDate = Date().adding(days: -10)
        cycle.endDate = Date().adding(days: -5)
        cycle.periodLength = 5
        cycle.isActive = true

        // Calculate fertility dates (ovulation around day 14)
        let ovulationDay = 14
        cycle.ovulationDate = cycle.startDate?.adding(days: ovulationDay - 1)
        cycle.fertileWindowStart = cycle.startDate?.adding(days: ovulationDay - 6)
        cycle.fertileWindowEnd = cycle.startDate?.adding(days: ovulationDay)

        // Create sample daily logs
        for dayOffset in 0..<10 {
            let log = DailyLog(context: viewContext)
            log.id = UUID()
            log.date = Date().adding(days: -dayOffset).startOfDay
            log.createdAt = Date()
            log.updatedAt = Date()
            log.cycle = cycle

            // Period days (first 5 days)
            if dayOffset >= 5 {
                let intensity: Int16
                switch 10 - dayOffset {
                case 1: intensity = 2 // Light
                case 2: intensity = 3 // Medium
                case 3: intensity = 4 // Heavy
                case 4: intensity = 3 // Medium
                case 5: intensity = 2 // Light
                default: intensity = 0
                }
                log.flowIntensity = intensity
            } else {
                log.flowIntensity = 0
            }

            log.mood = Int16.random(in: 2...5)
            log.energy = Int16.random(in: 2...5)

            // Add some symptoms for period days
            if dayOffset >= 5 && dayOffset <= 8 {
                let symptom1 = Symptom(context: viewContext)
                symptom1.id = UUID()
                symptom1.type = SymptomType.cramps.rawValue
                symptom1.severity = Int16.random(in: 1...3)
                symptom1.timestamp = log.date ?? Date()
                symptom1.dailyLog = log

                if Bool.random() {
                    let symptom2 = Symptom(context: viewContext)
                    symptom2.id = UUID()
                    symptom2.type = SymptomType.fatigue.rawValue
                    symptom2.severity = Int16.random(in: 1...3)
                    symptom2.timestamp = log.date ?? Date()
                    symptom2.dailyLog = log
                }
            }
        }

        // Create a previous cycle for history
        let previousCycle = Cycle(context: viewContext)
        previousCycle.id = UUID()
        previousCycle.startDate = Date().adding(days: -38)
        previousCycle.endDate = Date().adding(days: -33)
        previousCycle.cycleLength = 28
        previousCycle.periodLength = 5
        previousCycle.isActive = false

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MisoPeriod")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // In production, handle this error gracefully instead of crashing
                // Common issues:
                // - Parent directory doesn't exist
                // - Device storage is full
                // - Data protection when device is locked
                // - Model migration needed
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
