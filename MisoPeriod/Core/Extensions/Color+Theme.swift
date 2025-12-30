import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // MARK: - Primary Colors
    static let misoPrimary = Color(hex: "E8A598")      // Soft coral - period
    static let misoSecondary = Color(hex: "A8D5BA")    // Soft sage green - fertile
    static let misoAccent = Color(hex: "5FBDAA")       // Teal - ovulation
    static let misoWarm = Color(hex: "F5E6D3")         // Warm cream

    // MARK: - Background Colors
    static let misoBgPrimary = Color(hex: "FFF9F5")    // Warm off-white
    static let misoBgSecondary = Color(hex: "F5EDE8")  // Light warm
    static let misoBgCard = Color.white

    // MARK: - Text Colors
    static let misoTextPrimary = Color(hex: "4A4A4A")
    static let misoTextSecondary = Color(hex: "7A7A7A")
    static let misoTextTertiary = Color(hex: "A0A0A0")

    // MARK: - Semantic Colors
    static let misoPeriod = Color(hex: "E8A598")
    static let misoFertile = Color(hex: "A8D5BA")
    static let misoOvulation = Color(hex: "5FBDAA")
    static let misoPredicted = Color(hex: "E8A598").opacity(0.5)

    // MARK: - Mood Colors (1-5 scale)
    static let misoMood1 = Color(hex: "E8A598")        // Low mood - coral
    static let misoMood2 = Color(hex: "E8C498")        // Below average - peach
    static let misoMood3 = Color(hex: "F5E6D3")        // Neutral - cream
    static let misoMood4 = Color(hex: "C4DFC4")        // Good - light green
    static let misoMood5 = Color(hex: "A8D5BA")        // Great - sage green

    // MARK: - Flow Intensity Colors
    static let misoFlowNone = Color(hex: "F5EDE8")
    static let misoFlowSpotting = Color(hex: "F5D5CF")
    static let misoFlowLight = Color(hex: "E8B8AE")
    static let misoFlowMedium = Color(hex: "E8A598")
    static let misoFlowHeavy = Color(hex: "D88E80")

    static func moodColor(for value: Int) -> Color {
        switch value {
        case 1: return .misoMood1
        case 2: return .misoMood2
        case 3: return .misoMood3
        case 4: return .misoMood4
        case 5: return .misoMood5
        default: return .misoMood3
        }
    }
}

// MARK: - Font Extensions
extension Font {
    static let misoLargeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let misoTitle = Font.system(.title, design: .rounded).weight(.semibold)
    static let misoTitle2 = Font.system(.title2, design: .rounded).weight(.semibold)
    static let misoTitle3 = Font.system(.title3, design: .rounded).weight(.medium)
    static let misoHeadline = Font.system(.headline, design: .rounded)
    static let misoBody = Font.system(.body, design: .rounded)
    static let misoCallout = Font.system(.callout, design: .rounded)
    static let misoSubheadline = Font.system(.subheadline, design: .rounded)
    static let misoFootnote = Font.system(.footnote, design: .rounded)
    static let misoCaption = Font.system(.caption, design: .rounded)
}
