import SwiftUI

struct LiquidGlassButton: View {
    @Environment(\.wkTheme) var theme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Save message action
            Haptic.light()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.message")
                    .font(.system(size: 14, weight: .medium))
                
                Text("Save Message")
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(wkHex: "#FFB3BA"), // Soft blush
                                Color(wkHex: "#FFDFBA"), // Warm cream
                                Color(wkHex: "#BAFFC9")  // Sage green
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(wkHex: "#FF9AA2").opacity(0.6),
                                        Color(wkHex: "#FFD3A5").opacity(0.4),
                                        Color(wkHex: "#A8E6CF").opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {
            // Handle press
        })
    }
}

// Helper extension for hex colors
extension Color {
    init(wkHex: String) {
        let hex = wkHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
