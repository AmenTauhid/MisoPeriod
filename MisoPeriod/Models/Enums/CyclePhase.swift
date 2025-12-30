import SwiftUI

enum CyclePhase: String, CaseIterable, Identifiable, Codable {
    case menstrual
    case follicular
    case ovulation
    case luteal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .menstrual: return "Menstrual"
        case .follicular: return "Follicular"
        case .ovulation: return "Ovulation"
        case .luteal: return "Luteal"
        }
    }

    var description: String {
        switch self {
        case .menstrual:
            return "Your period is here. Take it easy and be gentle with yourself."
        case .follicular:
            return "Energy levels rising! Great time for new projects."
        case .ovulation:
            return "Peak energy and fertility window. You might feel extra social!"
        case .luteal:
            return "Winding down. Perfect for cozy activities and self-care."
        }
    }

    var shortDescription: String {
        switch self {
        case .menstrual: return "Period time"
        case .follicular: return "Rising energy"
        case .ovulation: return "Peak energy"
        case .luteal: return "Winding down"
        }
    }

    var icon: String {
        switch self {
        case .menstrual: return "drop.fill"
        case .follicular: return "sunrise.fill"
        case .ovulation: return "sun.max.fill"
        case .luteal: return "moon.fill"
        }
    }

    var color: Color {
        switch self {
        case .menstrual: return .misoPeriod
        case .follicular: return .misoWarm
        case .ovulation: return .misoFertile
        case .luteal: return .misoAccent
        }
    }

    var backgroundColor: Color {
        color.opacity(0.15)
    }

    var typicalDays: ClosedRange<Int> {
        switch self {
        case .menstrual: return 1...5
        case .follicular: return 6...13
        case .ovulation: return 14...16
        case .luteal: return 17...28
        }
    }

    var energyLevel: String {
        switch self {
        case .menstrual: return "Low"
        case .follicular: return "Rising"
        case .ovulation: return "High"
        case .luteal: return "Decreasing"
        }
    }

    var affirmations: [String] {
        switch self {
        case .menstrual:
            return [
                "Rest is productive too",
                "Honor what your body needs",
                "This too shall pass",
                "You're doing great",
                "Be gentle with yourself today",
                "Take all the time you need",
                "Your body is amazing",
                "It's okay to slow down",
                "Comfort is your priority right now",
                "You're stronger than you know",
                "Warm hugs and cozy blankets energy",
                "Permission to cancel plans: granted"
            ]
        case .follicular:
            return [
                "Fresh starts are beautiful",
                "Your energy is building",
                "Great things are coming",
                "You've got this!",
                "Time to bloom",
                "Embrace new beginnings",
                "The world is your oyster",
                "Your creativity is flowing",
                "Chase those dreams today",
                "You're ready for anything",
                "New chapter, new energy",
                "Watch you grow and glow"
            ]
        case .ovulation:
            return [
                "You're glowing!",
                "Shine bright today",
                "Your energy is radiant",
                "Make the most of today",
                "You're unstoppable",
                "Embrace your power",
                "Main character energy",
                "Confidence looks good on you",
                "Go conquer the world",
                "Your vibe is magnetic",
                "Nothing can stop you today",
                "Yes queen, yes!"
            ]
        case .luteal:
            return [
                "Slow down and breathe",
                "Self-care is essential",
                "Be kind to yourself",
                "You deserve rest",
                "Listen to your body",
                "Cozy vibes only",
                "Snacks and naps are valid",
                "Your feelings are valid",
                "Take it one moment at a time",
                "You're doing better than you think",
                "Soft hours only",
                "Treat yourself gently"
            ]
        }
    }

    var selfCareTip: String {
        switch self {
        case .menstrual:
            return "Try a warm bath, herbal tea, or your favorite comfort show"
        case .follicular:
            return "Great time for trying new things or starting a project"
        case .ovulation:
            return "Perfect for social events, dates, or important meetings"
        case .luteal:
            return "Stock up on your comfort foods and plan some quiet time"
        }
    }

    var emoji: String {
        switch self {
        case .menstrual: return "🌸"
        case .follicular: return "🌱"
        case .ovulation: return "✨"
        case .luteal: return "🌙"
        }
    }

    func randomAffirmation() -> String {
        affirmations.randomElement() ?? "You're doing great!"
    }

    static func from(cycleDay: Int, cycleLength: Int = 28) -> CyclePhase {
        let periodLength = 5
        let ovulationDay = cycleLength - 14 // Ovulation typically 14 days before next period

        if cycleDay <= periodLength {
            return .menstrual
        } else if cycleDay < ovulationDay - 1 {
            return .follicular
        } else if cycleDay <= ovulationDay + 1 {
            return .ovulation
        } else {
            return .luteal
        }
    }
}
