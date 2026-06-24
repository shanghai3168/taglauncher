import SwiftUI
import AppKit

enum AppGridTheme: String, CaseIterable, Identifiable {
    case defaultLight
    case deepBlue
    case black
    case pink
    case purple
    case green
    case blue
    case colorful

    static let storageKey = "appGridThemeID"
    static let fallback = AppGridTheme.defaultLight

    var id: String { rawValue }

    init(storedID: String) {
        self = AppGridTheme(rawValue: storedID) ?? .fallback
    }

    var titleKey: String {
        switch self {
        case .defaultLight: return "theme.default"
        case .deepBlue: return "theme.deepBlue"
        case .black: return "theme.black"
        case .pink: return "theme.pink"
        case .purple: return "theme.purple"
        case .green: return "theme.green"
        case .blue: return "theme.blue"
        case .colorful: return "theme.colorful"
        }
    }

    var isDefaultLight: Bool {
        self == .defaultLight
    }

    var usesVisualEffectBackdrop: Bool {
        self != .black
    }

    var isPureBlackBackground: Bool {
        self == .black
    }

    var usesDarkGlass: Bool {
        switch self {
        case .deepBlue, .black:
            return true
        case .defaultLight, .pink, .purple, .green, .blue, .colorful:
            return false
        }
    }

    var material: NSVisualEffectView.Material {
        usesDarkGlass ? .underWindowBackground : .hudWindow
    }

    var backgroundDimmingOpacity: Double {
        switch self {
        case .deepBlue:
            return 0.20
        case .defaultLight, .black, .pink, .purple, .green, .blue, .colorful:
            return 0
        }
    }

    var editPrimaryTextColor: Color {
        usesDarkGlass ? Color.white : Color(red: 0.08, green: 0.10, blue: 0.13)
    }

    var editSecondaryTextColor: Color {
        usesDarkGlass
            ? Color.white.opacity(0.78)
            : Color(red: 0.10, green: 0.13, blue: 0.17).opacity(0.78)
    }

    var editTertiaryTextColor: Color {
        usesDarkGlass
            ? Color.white.opacity(0.58)
            : Color(red: 0.10, green: 0.13, blue: 0.17).opacity(0.56)
    }

    var editDividerColor: Color {
        usesDarkGlass ? Color.white.opacity(0.22) : Color.black.opacity(0.16)
    }

    var editToolbarSurfaceColor: Color {
        if isPureBlackBackground {
            return Color.black.opacity(0.82)
        }
        return usesDarkGlass ? Color.black.opacity(0.54) : Color.white.opacity(0.56)
    }

    var editControlSurfaceColor: Color {
        usesDarkGlass ? Color.white.opacity(0.18) : Color.white.opacity(0.72)
    }

    var editControlStrokeColor: Color {
        usesDarkGlass ? Color.white.opacity(0.38) : Color.black.opacity(0.18)
    }

    var editInactiveIndicatorColor: Color {
        usesDarkGlass ? Color.white.opacity(0.42) : Color.black.opacity(0.36)
    }

    var editDisabledTextColor: Color {
        usesDarkGlass
            ? Color.white.opacity(0.70)
            : Color(red: 0.10, green: 0.13, blue: 0.17).opacity(0.58)
    }

    var editDisabledSurfaceColor: Color {
        usesDarkGlass ? Color.white.opacity(0.10) : Color.black.opacity(0.07)
    }

    var editButtonShadowColor: Color {
        usesDarkGlass ? Color.black.opacity(0.28) : Color.black.opacity(0.10)
    }

    var editAccentColor: Color {
        switch self {
        case .defaultLight:
            return Color.accentColor
        case .deepBlue:
            return Color(red: 0.26, green: 0.68, blue: 1.00)
        case .black:
            return Color(red: 0.10, green: 0.52, blue: 1.00)
        case .pink:
            return Color(red: 0.92, green: 0.20, blue: 0.58)
        case .purple:
            return Color(red: 0.50, green: 0.24, blue: 0.92)
        case .green:
            return Color(red: 0.12, green: 0.62, blue: 0.24)
        case .blue:
            return Color(red: 0.08, green: 0.42, blue: 0.96)
        case .colorful:
            return Color(red: 0.00, green: 0.58, blue: 0.92)
        }
    }

    var editConfirmForegroundColor: Color {
        Color.white
    }

    var backgroundBaseColors: [Color] {
        switch self {
        case .defaultLight:
            return [
                Color.white.opacity(0.16),
                Color.white.opacity(0.08)
            ]
        case .deepBlue:
            return [
                Color(red: 0.02, green: 0.04, blue: 0.09).opacity(0.96),
                Color(red: 0.04, green: 0.09, blue: 0.18).opacity(0.94),
                Color(red: 0.02, green: 0.20, blue: 0.22).opacity(0.88)
            ]
        case .black:
            return [
                Color.black,
                Color.black
            ]
        case .pink:
            return [
                Color(red: 1.00, green: 0.86, blue: 0.94),
                Color(red: 1.00, green: 0.57, blue: 0.78),
                Color(red: 1.00, green: 0.82, blue: 0.66)
            ]
        case .purple:
            return [
                Color(red: 0.83, green: 0.75, blue: 1.00),
                Color(red: 0.58, green: 0.34, blue: 0.95),
                Color(red: 0.96, green: 0.72, blue: 1.00)
            ]
        case .green:
            return [
                Color(red: 0.80, green: 0.96, blue: 0.58),
                Color(red: 0.22, green: 0.78, blue: 0.36),
                Color(red: 0.66, green: 0.92, blue: 0.44)
            ]
        case .blue:
            return [
                Color(red: 0.70, green: 0.91, blue: 1.00),
                Color(red: 0.22, green: 0.58, blue: 1.00),
                Color(red: 0.45, green: 0.96, blue: 1.00)
            ]
        case .colorful:
            return [
                Color(red: 0.10, green: 0.78, blue: 1.00),
                Color(red: 0.34, green: 0.96, blue: 0.94),
                Color(red: 0.73, green: 0.78, blue: 1.00),
                Color(red: 1.00, green: 0.58, blue: 0.94)
            ]
        }
    }

    var backgroundAccentColors: [Color] {
        switch self {
        case .defaultLight:
            return [Color.clear, Color.clear]
        case .deepBlue:
            return [
                Color(red: 0.48, green: 0.35, blue: 0.88).opacity(0.18),
                Color.clear,
                Color(red: 0.00, green: 0.78, blue: 0.86).opacity(0.16)
            ]
        case .black:
            return [
                Color.clear,
                Color.clear
            ]
        case .pink:
            return [
                Color.white.opacity(0.28),
                Color(red: 1.00, green: 0.38, blue: 0.74).opacity(0.24),
                Color(red: 1.00, green: 0.72, blue: 0.42).opacity(0.18)
            ]
        case .purple:
            return [
                Color.white.opacity(0.20),
                Color(red: 0.43, green: 0.22, blue: 0.92).opacity(0.28),
                Color(red: 1.00, green: 0.52, blue: 0.92).opacity(0.18)
            ]
        case .green:
            return [
                Color.white.opacity(0.22),
                Color(red: 0.10, green: 0.62, blue: 0.22).opacity(0.20),
                Color(red: 0.70, green: 1.00, blue: 0.54).opacity(0.22)
            ]
        case .blue:
            return [
                Color.white.opacity(0.20),
                Color(red: 0.00, green: 0.40, blue: 1.00).opacity(0.24),
                Color(red: 0.00, green: 0.90, blue: 1.00).opacity(0.18)
            ]
        case .colorful:
            return [
                Color.white.opacity(0.16),
                Color(red: 0.00, green: 0.78, blue: 1.00).opacity(0.22),
                Color(red: 1.00, green: 0.45, blue: 0.95).opacity(0.22),
                Color(red: 0.35, green: 1.00, blue: 0.92).opacity(0.18)
            ]
        }
    }

    var previewColors: [Color] {
        switch self {
        case .defaultLight:
            return [Color.white, Color(red: 0.88, green: 0.90, blue: 0.92)]
        case .deepBlue:
            return [Color(red: 0.03, green: 0.08, blue: 0.16), Color(red: 0.02, green: 0.24, blue: 0.28)]
        case .black:
            return [Color.black, Color.black]
        case .pink:
            return [Color(red: 1.00, green: 0.86, blue: 0.94), Color(red: 1.00, green: 0.57, blue: 0.78)]
        case .purple:
            return [Color(red: 0.83, green: 0.75, blue: 1.00), Color(red: 0.58, green: 0.34, blue: 0.95)]
        case .green:
            return [Color(red: 0.80, green: 0.96, blue: 0.58), Color(red: 0.22, green: 0.78, blue: 0.36)]
        case .blue:
            return [Color(red: 0.70, green: 0.91, blue: 1.00), Color(red: 0.22, green: 0.58, blue: 1.00)]
        case .colorful:
            return [
                Color(red: 0.10, green: 0.78, blue: 1.00),
                Color(red: 0.34, green: 0.96, blue: 0.94),
                Color(red: 0.75, green: 0.82, blue: 1.00),
                Color(red: 1.00, green: 0.56, blue: 0.94)
            ]
        }
    }
}
