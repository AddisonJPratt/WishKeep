import SwiftUI

enum Theme {
    enum Colors {
        // Palette from UX_PART_2.md
        static let canvas = Color(hex: "#FFF7F1")
        static let surface = Color(hex: "#F4F1EE")
        static let inkPrimary = Color(hex: "#1F1D1B")
        static let inkSecondary = Color(hex: "#5C5854")
        static let accentGlow = Color(hex: "#FFDFAE")
        static let brandStart = Color(hex: "#F5C5B2")
        static let brandEnd = Color(hex: "#F2A7A6")
        static let divider = Color(hex: "#E7E2DC")
        static let success = Color(hex: "#86D19A")
        static let warning = Color(hex: "#F7C85B")

        // Convenience
        static let background = canvas
        static let card = surface
        static let tertiary = Color(.tertiarySystemBackground)
        static let highlight = brandEnd
        static var brandGradient: LinearGradient { LinearGradient(colors: [brandStart, brandEnd], startPoint: .topLeading, endPoint: .bottomTrailing) }
    }

    enum Typography {
        static let title1: CGFloat = 34
        static let title2: CGFloat = 28
        static let title3: CGFloat = 22
        static let body: CGFloat = 17
        static let footnote: CGFloat = 13
    }

    enum Radii {
        static let large: CGFloat = 24
        static let medium: CGFloat = 16
        static let small: CGFloat = 12
    }

    enum Shadows {
        static let y: CGFloat = 8
        static let blur: CGFloat = 24
        static let opacity: Double = 0.08
    }

    enum Motion {
        static let standard = Animation.easeInOut(duration: 0.18)
    }

    enum Metrics {
        static let padding: CGFloat = 16
    }
}

enum TitleLevel { case h1, h2, h3 }

extension View {
    func titleStyle(_ level: TitleLevel) -> some View {
        let size: CGFloat = {
            switch level { case .h1: return Theme.Typography.title1; case .h2: return Theme.Typography.title2; case .h3: return Theme.Typography.title3 }
        }()
        return self.font(.system(size: size, weight: .bold, design: .rounded)).foregroundStyle(Theme.Colors.inkPrimary)
    }

    func cardStyle() -> some View {
        self
            .background(RoundedRectangle(cornerRadius: Theme.Radii.large).fill(Theme.Colors.card))
            .softShadow()
    }

    func chipStyle(selected: Bool = false) -> some View {
        self
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(selected ? Theme.Colors.accentGlow.opacity(0.6) : Theme.Colors.surface))
    }

    // Backwards-compat overload used earlier
    func chipStyle(active: Bool) -> some View { chipStyle(selected: active) }

    func softShadow() -> some View {
        self.shadow(color: .black.opacity(Theme.Shadows.opacity), radius: Theme.Shadows.blur, x: 0, y: Theme.Shadows.y)
    }

    func glowBackground() -> some View {
        self.background(Theme.Colors.brandGradient).opacity(0.85)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radii.large))
            .softShadow()
    }
}

extension Color {
    init(hex: String) {
        var hexString = hex
        if hexString.hasPrefix("#") { hexString.removeFirst() }
        var int: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}


