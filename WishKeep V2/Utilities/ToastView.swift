import SwiftUI

struct ToastView: View {
    let text: String
    var body: some View {
        Text(text)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial, in: Capsule())
            .softShadow()
            .accessibilityLabel(text)
    }
}


