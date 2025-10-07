import SwiftUI

struct RichTextToolbar: View {
    struct State: Equatable {
        var isBody = true
        var isTitle = false
        var isSubtitle = false
        var isList = false
        var isIndented = false
    }

    @Binding var state: State
    var onBody: () -> Void
    var onTitle: () -> Void
    var onSubtitle: () -> Void
    var onList: () -> Void
    var onIndent: () -> Void
    var onMore: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let buttonSize: CGFloat = 44

    var body: some View {
        HStack(spacing: 12) {
            item(icon: "textformat", active: state.isBody, label: "Body Style", action: onBody)
            item(icon: "textformat.size.larger", active: state.isTitle, label: "Title Style", action: onTitle)
            item(icon: "textformat.size.smaller", active: state.isSubtitle, label: "Subtitle Style", action: onSubtitle)
            item(icon: "list.bullet", active: state.isList, label: "List Format", action: onList)
            item(icon: "increase.indent", active: state.isIndented, label: "Indent Text", action: onIndent)
            item(icon: "textformat.alt", active: false, label: "More Options", action: onMore)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Formatting toolbar")
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .move(edge: .bottom).combined(with: .opacity)))
        .animation(reduceMotion ? .default : .spring(response: 0.4, dampingFraction: 0.8), value: state)
    }

    private func item(icon: String, active: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptic.light()
            withAnimation(Theme.Motion.standard) { action() }
        }) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .frame(width: buttonSize, height: buttonSize)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(active ? Color(hex: "#f2e2db").opacity(0.7) : Color.clear)
                )
                .foregroundStyle(active ? Color(hex: "#275d38") : Theme.Colors.inkPrimary.opacity(0.6))
                .shadow(color: active ? Color.white.opacity(0.6) : Color.clear, radius: active ? 4 : 0, y: active ? -1 : 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

