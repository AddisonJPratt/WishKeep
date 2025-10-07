import SwiftUI

/// Animated Apple-Intelligence-style glow around a shape border.
struct AIHaloBorder<S: InsettableShape>: View {
    var shape: S
    var colors: [Color] = [.purple, .blue, .cyan, .blue, .purple]   // customize
    var lineWidth: CGFloat = 2
    var glow: CGFloat = 16
    var speed: Double = 12                                           // degrees per second

    @State private var phase: Double = 0

    var body: some View {
        ZStack {
            // Crisp gradient stroke
            shape
                .inset(by: lineWidth / 2)
                .stroke(AngularGradient(
                    colors: colors,
                    center: .center,
                    angle: .degrees(phase)),
                        lineWidth: lineWidth)

            // Soft halo (blurred duplicate, additive blend)
            shape
                .inset(by: lineWidth / 2)
                .stroke(AngularGradient(
                    colors: colors,
                    center: .center,
                    angle: .degrees(phase)),
                        lineWidth: lineWidth)
                .blur(radius: glow)
                .blendMode(.plusLighter) // additive glow
                .opacity(0.9)
                .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.linear(duration: 360.0 / speed).repeatForever(autoreverses: false)) {
                phase = 360
            }
        }
        .drawingGroup() // offscreen for smooth blending
    }
}

/// WishKeep-themed AI halo with brand colors
struct WKAIHaloBorder<S: InsettableShape>: View {
    var shape: S
    var theme: WKTheme
    var lineWidth: CGFloat = 2
    var glow: CGFloat = 18
    var speed: Double = 18

    @State private var phase: Double = 0

    var body: some View {
        let colors = [
            theme.accent,
            theme.accent.opacity(0.8),
            theme.accentAlt,
            theme.accent.opacity(0.6),
            theme.accent
        ]

        ZStack {
            // Crisp gradient stroke
            shape
                .inset(by: lineWidth / 2)
                .stroke(AngularGradient(
                    colors: colors,
                    center: .center,
                    angle: .degrees(phase)),
                        lineWidth: lineWidth)

            // Soft halo (blurred duplicate, additive blend)
            shape
                .inset(by: lineWidth / 2)
                .stroke(AngularGradient(
                    colors: colors,
                    center: .center,
                    angle: .degrees(phase)),
                        lineWidth: lineWidth)
                .blur(radius: glow)
                .blendMode(.plusLighter) // additive glow
                .opacity(0.9)
                .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(.linear(duration: 360.0 / speed).repeatForever(autoreverses: false)) {
                phase = 360
            }
        }
        .drawingGroup() // offscreen for smooth blending
    }
}
