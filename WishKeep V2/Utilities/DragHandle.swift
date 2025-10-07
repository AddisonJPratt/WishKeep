import SwiftUI

struct DragHandle: View {
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<3) { _ in 
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: 18, height: 3)
                    .opacity(0.25) 
            }
        }
        .padding(.trailing, 6)
        .accessibilityLabel("Reorder block")
    }
}
