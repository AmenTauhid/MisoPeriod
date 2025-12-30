import SwiftUI

enum FlowIntensity: Int16, CaseIterable, Identifiable, Codable {
    case none = 0
    case spotting = 1
    case light = 2
    case medium = 3
    case heavy = 4

    var id: Int16 { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .spotting: return "Spotting"
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        }
    }

    var shortName: String {
        switch self {
        case .none: return "None"
        case .spotting: return "Spot"
        case .light: return "Light"
        case .medium: return "Med"
        case .heavy: return "Heavy"
        }
    }

    var description: String {
        switch self {
        case .none: return "No bleeding"
        case .spotting: return "Very light, occasional spots"
        case .light: return "Light flow, changing pad/tampon every 4-6 hours"
        case .medium: return "Moderate flow, changing every 3-4 hours"
        case .heavy: return "Heavy flow, changing every 1-2 hours"
        }
    }

    var icon: String {
        switch self {
        case .none: return "drop"
        case .spotting: return "drop.fill"
        case .light: return "drop.fill"
        case .medium: return "drop.fill"
        case .heavy: return "drop.fill"
        }
    }

    var color: Color {
        switch self {
        case .none: return .misoFlowNone
        case .spotting: return .misoFlowSpotting
        case .light: return .misoFlowLight
        case .medium: return .misoFlowMedium
        case .heavy: return .misoFlowHeavy
        }
    }

    var dropCount: Int {
        switch self {
        case .none: return 0
        case .spotting: return 1
        case .light: return 2
        case .medium: return 3
        case .heavy: return 4
        }
    }

    var isPeriod: Bool {
        self != .none
    }

    static func from(_ value: Int16) -> FlowIntensity {
        FlowIntensity(rawValue: value) ?? .none
    }
}
