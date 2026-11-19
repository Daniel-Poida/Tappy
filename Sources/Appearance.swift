import SwiftUI
import Cocoa

enum AppVersion {
    static let short = "1.4.2"
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self { case .system: return "System"; case .light: return "Light"; case .dark: return "Dark" }
    }
    var colorScheme: ColorScheme? {
        switch self { case .system: return nil; case .light: return .light; case .dark: return .dark }
    }
    var appearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

struct TappyPalette {
    let scheme: ColorScheme
    var ink: Color { Color(nsColor: .labelColor) }
    var background: Color { Color(nsColor: .windowBackgroundColor) }
    var card: Color { Color(nsColor: .controlBackgroundColor) }
}
