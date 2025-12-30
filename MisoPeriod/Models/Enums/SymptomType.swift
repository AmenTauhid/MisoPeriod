import SwiftUI

enum SymptomType: String, CaseIterable, Identifiable, Codable {
    // Physical Symptoms
    case cramps
    case headache
    case backPain
    case breastTenderness
    case bloating
    case nausea
    case fatigue
    case acne
    case appetiteChanges
    case cravings
    case dizziness
    case hotFlashes
    case insomnia
    case jointPain
    case muscleAches

    // Emotional/Mental Symptoms
    case moodSwings
    case anxiety
    case irritability
    case depression
    case brainFog
    case crying

    // Digestive Symptoms
    case constipation
    case diarrhea

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cramps: return "Cramps"
        case .headache: return "Headache"
        case .backPain: return "Back Pain"
        case .breastTenderness: return "Breast Tenderness"
        case .bloating: return "Bloating"
        case .nausea: return "Nausea"
        case .fatigue: return "Fatigue"
        case .acne: return "Acne"
        case .appetiteChanges: return "Appetite Changes"
        case .cravings: return "Cravings"
        case .dizziness: return "Dizziness"
        case .hotFlashes: return "Hot Flashes"
        case .insomnia: return "Insomnia"
        case .jointPain: return "Joint Pain"
        case .muscleAches: return "Muscle Aches"
        case .moodSwings: return "Mood Swings"
        case .anxiety: return "Anxiety"
        case .irritability: return "Irritability"
        case .depression: return "Feeling Low"
        case .brainFog: return "Brain Fog"
        case .crying: return "Crying"
        case .constipation: return "Constipation"
        case .diarrhea: return "Diarrhea"
        }
    }

    var icon: String {
        switch self {
        case .cramps: return "bolt.fill"
        case .headache: return "brain.head.profile"
        case .backPain: return "figure.stand"
        case .breastTenderness: return "heart.fill"
        case .bloating: return "circle.fill"
        case .nausea: return "face.dashed"
        case .fatigue: return "battery.25"
        case .acne: return "face.smiling"
        case .appetiteChanges: return "fork.knife"
        case .cravings: return "birthday.cake"
        case .dizziness: return "tornado"
        case .hotFlashes: return "thermometer.sun"
        case .insomnia: return "moon.zzz"
        case .jointPain: return "figure.walk"
        case .muscleAches: return "figure.strengthtraining.traditional"
        case .moodSwings: return "theatermasks"
        case .anxiety: return "exclamationmark.triangle"
        case .irritability: return "flame"
        case .depression: return "cloud.rain"
        case .brainFog: return "cloud.fog"
        case .crying: return "drop.fill"
        case .constipation: return "arrow.down.circle"
        case .diarrhea: return "arrow.up.circle"
        }
    }

    var color: Color {
        switch category {
        case .physical: return .misoPrimary
        case .emotional: return .misoAccent
        case .digestive: return .misoSecondary
        }
    }

    var category: SymptomCategory {
        switch self {
        case .cramps, .headache, .backPain, .breastTenderness, .bloating, .nausea,
             .fatigue, .acne, .appetiteChanges, .cravings, .dizziness, .hotFlashes,
             .insomnia, .jointPain, .muscleAches:
            return .physical
        case .moodSwings, .anxiety, .irritability, .depression, .brainFog, .crying:
            return .emotional
        case .constipation, .diarrhea:
            return .digestive
        }
    }

    static var byCategory: [SymptomCategory: [SymptomType]] {
        Dictionary(grouping: allCases, by: { $0.category })
    }

    static var commonSymptoms: [SymptomType] {
        [.cramps, .bloating, .fatigue, .moodSwings, .headache, .cravings]
    }
}

enum SymptomCategory: String, CaseIterable, Identifiable {
    case physical
    case emotional
    case digestive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .physical: return "Physical"
        case .emotional: return "Emotional"
        case .digestive: return "Digestive"
        }
    }

    var icon: String {
        switch self {
        case .physical: return "figure.stand"
        case .emotional: return "heart.fill"
        case .digestive: return "leaf.fill"
        }
    }
}
