import SwiftUI

enum ColorTag: Int, CaseIterable, Identifiable, Codable {
    case none = 0
    case red = 1
    case orange = 2
    case yellow = 3
    case green = 4
    case blue = 5
    case pink = 6
    case purple = 7

    var id: Int { rawValue }

    var color: Color {
        switch self {
        case .none: return .clear
        case .red: return Color(red: 1.0, green: 0.22, blue: 0.22)
        case .orange: return Color(red: 1.0, green: 0.58, blue: 0.0)
        case .yellow: return Color(red: 1.0, green: 0.92, blue: 0.23)
        case .green: return Color(red: 0.30, green: 0.85, blue: 0.39)
        case .blue: return Color(red: 0.0, green: 0.48, blue: 1.0)
        case .pink: return Color(red: 1.0, green: 0.18, blue: 0.33)
        case .purple: return Color(red: 0.69, green: 0.32, blue: 0.87)
        }
    }

    var name: String {
        switch self {
        case .none: return "None"
        case .red: return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        case .pink: return "Pink"
        case .purple: return "Purple"
        }
    }

    var keyboardShortcut: String? {
        switch self {
        case .red: return "-"
        case .green: return "+"
        case .yellow: return "*"
        default: return nil
        }
    }
}
