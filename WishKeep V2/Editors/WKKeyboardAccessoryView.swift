import SwiftUI

struct WKKeyboardAccessoryView: View {
    @Environment(\.wkTheme) var theme
    var actions: (bold: ()->Void, italic: ()->Void, underline: ()->Void, strike: ()->Void, code: ()->Void, highlight: ()->Void, link: ()->Void, checklist: ()->Void)
    @State private var activeButtons: Set<FormatButton> = []
    
    enum FormatButton: CaseIterable {
        case bold, italic, underline, strike, code, highlight, link, checklist
    }
    
    var body: some View {
        HStack(spacing: 14) {
            formatButton(.bold, "B", action: actions.bold)
            formatButton(.italic, "I", action: actions.italic)
            formatButton(.underline, "U", action: actions.underline)
            formatButton(.strike, "S", action: actions.strike)
            formatButton(.code, "{}", action: actions.code)
            formatButton(.highlight, "✨", action: actions.highlight)
            formatButton(.link, "🔗", action: actions.link)
            
            Spacer()
            
            formatButton(.checklist, "☑", action: actions.checklist)
        }
        .padding(.horizontal, WKTok.pM)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WKTok.cM))
        .overlay(
            RoundedRectangle(cornerRadius: WKTok.cM)
                .stroke(theme.mist.opacity(0.4), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private func formatButton(_ type: FormatButton, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            withAnimation(WKTok.spring) {
                if activeButtons.contains(type) {
                    activeButtons.remove(type)
                } else {
                    activeButtons.insert(type)
                }
            }
        }) {
            Text(title)
                .font(WKFont.meta)
                .foregroundStyle(activeButtons.contains(type) ? theme.accent : theme.subInk)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(activeButtons.contains(type) ? theme.accent.opacity(0.14) : .clear)
                )
        }
        .buttonStyle(.plain)
        .modifier(KeyboardShortcutModifier(shortcut: shortcut(for: type)))
    }
    
    private func shortcut(for type: FormatButton) -> KeyEquivalent? {
        switch type {
        case .bold: return KeyEquivalent("b")
        case .italic: return KeyEquivalent("i")
        case .underline: return KeyEquivalent("u")
        default: return nil
        }
    }
}

struct KeyboardShortcutModifier: ViewModifier {
    let shortcut: KeyEquivalent?
    
    func body(content: Content) -> some View {
        if let shortcut = shortcut {
            content.keyboardShortcut(shortcut, modifiers: .command)
        } else {
            content
        }
    }
}
