import SwiftUI

struct LargeTitle: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.system(size: Theme.Typography.title2, weight: .bold, design: .rounded))
            .foregroundStyle(Theme.Colors.inkPrimary)
    }
}

extension View {
    func largeTitle() -> some View { modifier(LargeTitle()) }
}

// Subtle Sparkle overlay for favorite
struct SparkleView: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.0
    var body: some View {
        ZStack {
            Circle().fill(Theme.Colors.accentGlow).frame(width: 10, height: 10)
            Circle().stroke(Theme.Colors.accentGlow, lineWidth: 1).frame(width: 16, height: 16)
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(Theme.Motion.standard) {
                scale = 1.2
                opacity = 1
            }
            withAnimation(Theme.Motion.standard.delay(0.15)) {
                scale = 1.6
                opacity = 0
            }
        }
    }
}


