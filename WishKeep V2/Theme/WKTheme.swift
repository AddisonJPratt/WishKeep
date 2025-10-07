import SwiftUI

// MARK: - Color Palette

struct WKPaletteLight {
    static let canvas     = Color.wkHex("#F7F4F0")   // warm porcelain
    static let surface    = Color.wkHex("#FFFFFF")   // cards
    static let ink        = Color.wkHex("#1E1B18")   // primary text
    static let subInk     = Color.wkHex("#4F4A44")   // secondary text
    static let faintInk   = Color.wkHex("#817A72")   // tertiary text
    static let mist       = Color.wkHex("#D9D4CC")   // strokes / dividers
    static let glowA      = Color.wkHex("#FFE7B8")   // honey glow
    static let glowB      = Color.wkHex("#BDE3FF")   // sky glow
    static let accent     = Color.wkHex("#6C5CE7")   // wish violet
    static let accentAlt  = Color.wkHex("#22A699")   // teal alt
    static let danger     = Color.wkHex("#E05D5D")
}

struct WKPaletteDark {
    static let canvas     = Color.wkHex("#111012")
    static let surface    = Color.wkHex("#1A191C")
    static let ink        = Color.wkHex("#F3F0EC")
    static let subInk     = Color.wkHex("#CFCAC3")
    static let faintInk   = Color.wkHex("#9C948B")
    static let mist       = Color.wkHex("#2A282C")
    static let glowA      = Color.wkHex("#5E4A1E")
    static let glowB      = Color.wkHex("#1E3E54")
    static let accent     = Color.wkHex("#8D7CFF")
    static let accentAlt  = Color.wkHex("#3CCFC1")
    static let danger     = Color.wkHex("#FF7A7A")
}

// MARK: - Hex Color Extension

extension Color {
    static func wkHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Carrier

struct WKTheme {
    let canvas: Color
    let surface: Color
    let ink: Color
    let subInk: Color
    let faintInk: Color
    let mist: Color
    let glowA: Color
    let glowB: Color
    let accent: Color
    let accentAlt: Color
    let danger: Color
}

extension WKTheme {
    static let light = WKTheme(
        canvas: WKPaletteLight.canvas,
        surface: WKPaletteLight.surface,
        ink: WKPaletteLight.ink,
        subInk: WKPaletteLight.subInk,
        faintInk: WKPaletteLight.faintInk,
        mist: WKPaletteLight.mist,
        glowA: WKPaletteLight.glowA,
        glowB: WKPaletteLight.glowB,
        accent: WKPaletteLight.accent,
        accentAlt: WKPaletteLight.accentAlt,
        danger: WKPaletteLight.danger
    )
    
    static let dark = WKTheme(
        canvas: WKPaletteDark.canvas,
        surface: WKPaletteDark.surface,
        ink: WKPaletteDark.ink,
        subInk: WKPaletteDark.subInk,
        faintInk: WKPaletteDark.faintInk,
        mist: WKPaletteDark.mist,
        glowA: WKPaletteDark.glowA,
        glowB: WKPaletteDark.glowB,
        accent: WKPaletteDark.accent,
        accentAlt: WKPaletteDark.accentAlt,
        danger: WKPaletteDark.danger
    )
}

// MARK: - Environment

private struct WKThemeKey: EnvironmentKey {
    static let defaultValue = WKTheme.light
}

extension EnvironmentValues {
    var wkTheme: WKTheme {
        get { self[WKThemeKey.self] }
        set { self[WKThemeKey.self] = newValue }
    }
}

extension View {
    func wkTheme(_ theme: WKTheme) -> some View {
        environment(\.wkTheme, theme)
    }
}

// MARK: - Typography

enum WKFont {
    static func display(_ width: CGFloat) -> Font {
        .system(size: max(30, width * 0.068), weight: .black, design: .rounded)
    }
    static let h1 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let h2 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let body = Font.system(.body, design: .rounded)
    static let meta = Font.system(size: 13, weight: .medium, design: .rounded)
    static let code = Font.system(.callout, design: .monospaced)
}

// MARK: - Design Tokens

enum WKTok {
    static let cS: CGFloat = 16
    static let cM: CGFloat = 22
    static let cL: CGFloat = 28
    static let pS: CGFloat = 10
    static let pM: CGFloat = 16
    static let pL: CGFloat = 20
    static let shadowSoft = Color.black.opacity(0.10)
    static let shadowLift = Color.black.opacity(0.22)
    static let spring = Animation.spring(response: 0.32, dampingFraction: 0.85)
}
