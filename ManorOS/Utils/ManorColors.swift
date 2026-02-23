import SwiftUI
import UIKit

// MARK: - Manor OS Color System

/// Centralized brand color system for Manor OS.
/// All colors are adaptive (light/dark) unless explicitly noted.
///
/// Usage: `Color.manor.primary`, `Color.manor.textPrimary`, etc.
enum ManorColors {

    // MARK: - Hex Initializer Helper

    /// Creates a UIColor from a hex value
    private static func uiColor(hex: UInt, opacity: CGFloat = 1.0) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: opacity
        )
    }

    /// Adaptive color that resolves differently in light vs dark mode
    private static func adaptive(light: UInt, dark: UInt) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? uiColor(hex: dark)
                : uiColor(hex: light)
        })
    }

    // MARK: - Primary (Manor Green)

    /// Deep emerald green — main brand color, CTAs
    /// Light: #1B6B47, Dark: #6AC49D
    static let primary = adaptive(light: 0x1B6B47, dark: 0x6AC49D)

    /// Text/icons on primary color surfaces
    /// Light: #FFFFFF, Dark: #003825
    static let onPrimary = adaptive(light: 0xFFFFFF, dark: 0x003825)

    // MARK: - Secondary (Estate Slate)

    /// Slate blue — secondary buttons, informational elements
    /// Light: #2E4D70, Dark: #98BCE0
    static let secondary = adaptive(light: 0x2E4D70, dark: 0x98BCE0)

    /// Text/icons on secondary color surfaces
    static let onSecondary = adaptive(light: 0xFFFFFF, dark: 0x0A2540)

    // MARK: - Accent (Energy Amber)

    /// Warm amber — energy data highlights, premium indicators
    /// Light: #C97D10, Dark: #FFC24D
    static let accent = adaptive(light: 0xC97D10, dark: 0xFFC24D)

    /// Text/icons on accent color surfaces
    static let onAccent = adaptive(light: 0xFFFFFF, dark: 0x3E2000)

    // MARK: - Tertiary (Sage Mist)

    /// Sage green — room categorization, ambient displays
    /// Light: #4A7A62, Dark: #8DCBA8
    static let tertiary = adaptive(light: 0x4A7A62, dark: 0x8DCBA8)

    // MARK: - Surfaces (Green-Undertone Neutrals)

    /// App background, deepest layer
    /// Light: #F2F7F4, Dark: #0D1410
    static let background = adaptive(light: 0xF2F7F4, dark: 0x0D1410)

    /// Default card/panel background
    /// Light: #FFFFFF, Dark: #141C17
    static let surface = adaptive(light: 0xFFFFFF, dark: 0x141C17)

    /// Cards, list items — default container
    /// Light: #EFF5F1, Dark: #181F1A
    static let surfaceContainer = adaptive(light: 0xEFF5F1, dark: 0x181F1A)

    /// Elevated cards, bottom sheets
    /// Light: #E8F0EB, Dark: #1F2820
    static let surfaceContainerHigh = adaptive(light: 0xE8F0EB, dark: 0x1F2820)

    /// Top-elevation surfaces, app bars
    /// Light: #E1EAE3, Dark: #273028
    static let surfaceContainerHighest = adaptive(light: 0xE1EAE3, dark: 0x273028)

    /// Slightly elevated surfaces
    /// Light: #F7FAF8, Dark: #111914
    static let surfaceContainerLow = adaptive(light: 0xF7FAF8, dark: 0x111914)

    /// Chips, card alt backgrounds
    /// Light: #D4E5DA, Dark: #283D2F
    static let surfaceVariant = adaptive(light: 0xD4E5DA, dark: 0x283D2F)

    // MARK: - Text

    /// Primary text — headings, key content
    /// Light: #0E1E15, Dark: #E0EDE6
    static let textPrimary = adaptive(light: 0x0E1E15, dark: 0xE0EDE6)

    /// Secondary text — body, labels
    /// Light: #3D5848, Dark: #9EBDAB
    static let textSecondary = adaptive(light: 0x3D5848, dark: 0x9EBDAB)

    /// Tertiary text — captions, hints
    /// Light: #6A8E7A, Dark: #6A8C78
    static let textTertiary = adaptive(light: 0x6A8E7A, dark: 0x6A8C78)

    /// Disabled text
    /// Light: #A8C0B0, Dark: #3A5042
    static let textDisabled = adaptive(light: 0xA8C0B0, dark: 0x3A5042)

    // MARK: - Borders

    /// Standard borders and dividers
    /// Light: #6A8E7A, Dark: #4E6C58
    static let outline = adaptive(light: 0x6A8E7A, dark: 0x4E6C58)

    /// Subtle separators
    /// Light: #BAD0C3, Dark: #283D2F
    static let outlineVariant = adaptive(light: 0xBAD0C3, dark: 0x283D2F)

    // MARK: - Semantic

    /// Success state — goals achieved, devices online
    /// Light: #16A34A, Dark: #4ADE80
    static let success = adaptive(light: 0x16A34A, dark: 0x4ADE80)

    /// Error state — offline, alerts, failures
    /// Light: #C62828, Dark: #FF8A80
    static let error = adaptive(light: 0xC62828, dark: 0xFF8A80)

    /// Warning state — high usage, maintenance
    /// Light: #B45309, Dark: #FCD34D
    static let warning = adaptive(light: 0xB45309, dark: 0xFCD34D)

    /// Info state — tips, tutorials, rate info
    /// Light: #1D4ED8, Dark: #93C5FD
    static let info = adaptive(light: 0x1D4ED8, dark: 0x93C5FD)

    // MARK: - Grade Colors

    /// Returns the brand color for an efficiency grade
    static func gradeColor(_ grade: EfficiencyGrade) -> Color {
        switch grade {
        case .a: return Color(uiColor(hex: 0x1B6B47)) // Manor Green
        case .b: return Color(uiColor(hex: 0x22C55E)) // Bright Green
        case .c: return Color(uiColor(hex: 0xEAB308)) // Amber
        case .d: return Color(uiColor(hex: 0xF97316)) // Orange
        case .f: return Color(uiColor(hex: 0xEF4444)) // Red
        }
    }

    // MARK: - Data Visualization

    /// Solar generation — yellow-gold
    static let dataSolar = adaptive(light: 0xD97706, dark: 0xFCD34D)

    /// Grid draw — blue
    static let dataGrid = adaptive(light: 0x2563EB, dark: 0x60A5FA)

    /// Battery storage — purple
    static let dataBattery = adaptive(light: 0x7C3AED, dark: 0xC4B5FD)

    /// HVAC / Climate — orange
    static let dataHVAC = adaptive(light: 0xEA580C, dark: 0xFB923C)

    /// Appliances — cyan
    static let dataAppliances = adaptive(light: 0x0891B2, dark: 0x67E8F9)

    /// EV Charging — mint green
    static let dataEV = adaptive(light: 0x059669, dark: 0x34D399)

    // MARK: - Onboarding

    /// Fixed dark background for onboarding (non-adaptive)
    static let onboardingBackground = Color(uiColor(hex: 0x0D1410))

    // MARK: - PDF Print Colors (Non-Adaptive)

    /// UIColor constants for PDF rendering — always use light-mode values on white paper
    enum pdf {
        static let title = UIColor(red: 0x1B / 255.0, green: 0x6B / 255.0, blue: 0x47 / 255.0, alpha: 1) // #1B6B47
        static let heading = UIColor(red: 0x1B / 255.0, green: 0x6B / 255.0, blue: 0x47 / 255.0, alpha: 1) // #1B6B47
        static let body = UIColor(red: 0x0E / 255.0, green: 0x1E / 255.0, blue: 0x15 / 255.0, alpha: 1) // #0E1E15
        static let highlight = UIColor(red: 0x16 / 255.0, green: 0xA3 / 255.0, blue: 0x4A / 255.0, alpha: 1) // #16A34A
        static let grade = UIColor(red: 0x1B / 255.0, green: 0x6B / 255.0, blue: 0x47 / 255.0, alpha: 1) // #1B6B47
    }
}

// MARK: - Color.manor Extension

extension Color {
    /// Namespace for Manor OS brand colors
    /// Usage: `Color.manor.primary`, `Color.manor.success`, etc.
    static let manor = ManorColorNamespace()
}

struct ManorColorNamespace {
    // Primary
    var primary: Color { ManorColors.primary }
    var onPrimary: Color { ManorColors.onPrimary }

    // Secondary
    var secondary: Color { ManorColors.secondary }
    var onSecondary: Color { ManorColors.onSecondary }

    // Accent
    var accent: Color { ManorColors.accent }
    var onAccent: Color { ManorColors.onAccent }

    // Tertiary
    var tertiary: Color { ManorColors.tertiary }

    // Surfaces
    var background: Color { ManorColors.background }
    var surface: Color { ManorColors.surface }
    var surfaceContainer: Color { ManorColors.surfaceContainer }
    var surfaceContainerHigh: Color { ManorColors.surfaceContainerHigh }
    var surfaceContainerHighest: Color { ManorColors.surfaceContainerHighest }
    var surfaceContainerLow: Color { ManorColors.surfaceContainerLow }
    var surfaceVariant: Color { ManorColors.surfaceVariant }

    // Text
    var textPrimary: Color { ManorColors.textPrimary }
    var textSecondary: Color { ManorColors.textSecondary }
    var textTertiary: Color { ManorColors.textTertiary }
    var textDisabled: Color { ManorColors.textDisabled }

    // Borders
    var outline: Color { ManorColors.outline }
    var outlineVariant: Color { ManorColors.outlineVariant }

    // Semantic
    var success: Color { ManorColors.success }
    var error: Color { ManorColors.error }
    var warning: Color { ManorColors.warning }
    var info: Color { ManorColors.info }

    // Data Visualization
    var dataSolar: Color { ManorColors.dataSolar }
    var dataGrid: Color { ManorColors.dataGrid }
    var dataBattery: Color { ManorColors.dataBattery }
    var dataHVAC: Color { ManorColors.dataHVAC }
    var dataAppliances: Color { ManorColors.dataAppliances }
    var dataEV: Color { ManorColors.dataEV }

    // Special
    var onboardingBackground: Color { ManorColors.onboardingBackground }
}
