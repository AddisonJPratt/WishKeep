import SwiftUI

// MARK: - Background & Surfaces

struct WKBackground: View {
    @Environment(\.wkTheme) var theme
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Base canvas gradient
            LinearGradient(
                colors: [theme.canvas, theme.canvas.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Honey glow from top-left
            RadialGradient(
                colors: [theme.glowA.opacity(0.22), .clear],
                center: .topLeading,
                startRadius: 40,
                endRadius: 420
            )
            .blur(radius: 40)
            
            // Sky glow from bottom-right
            RadialGradient(
                colors: [theme.glowB.opacity(0.18), .clear],
                center: .bottomTrailing,
                startRadius: 60,
                endRadius: 520
            )
            .blur(radius: 50)
            
            // Paper grain texture
            PaperGrain()
                .blendMode(.overlay)
                .opacity(0.12)
        }
        .ignoresSafeArea()
    }
}

struct PaperGrain: View {
    var body: some View {
        Canvas { context, size in
            for _ in 0..<900 {
                let x = Double.random(in: 0..<size.width)
                let y = Double.random(in: 0..<size.height)
                let width = Double.random(in: 0.3...1.2)
                let height = Double.random(in: 0.3...1.2)
                let opacity = Double.random(in: 0.03...0.08)
                
                let rect = CGRect(x: x, y: y, width: width, height: height)
                context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(opacity)))
            }
        }
    }
}

// MARK: - Card Modifier

extension View {
    func wkCard(_ theme: WKTheme) -> some View {
        self
            .padding(WKTok.pL)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: WKTok.cL, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: WKTok.cL)
                    .stroke(theme.mist.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: WKTok.shadowSoft, radius: 14, y: 8)
    }
}

// MARK: - Theme-Aware Background

struct WKThemeBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        WKBackground()
            .wkTheme(colorScheme == .dark ? .dark : .light)
    }
}
