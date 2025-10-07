import SwiftUI

struct KeyboardAccessoryView: View {
    var actions: (bold: ()->Void, italic: ()->Void, underline: ()->Void, strike: ()->Void, code: ()->Void, highlight: ()->Void, link: ()->Void, checklist: ()->Void)
    
    var body: some View {
        HStack(spacing: 14) {
            Button("B", action: actions.bold)
                .fontWeight(.heavy)
                .keyboardShortcut("b", modifiers: .command)
            
            Button("I", action: actions.italic)
                .italic()
                .keyboardShortcut("i", modifiers: .command)
            
            Button("U", action: actions.underline)
                .underline()
                .keyboardShortcut("u", modifiers: .command)
            
            Button("S", action: actions.strike)
                .strikethrough()
            
            Button(action: actions.code) { 
                Image(systemName: "curlybraces") 
            }
            
            Button(action: actions.highlight) { 
                Image(systemName: "highlighter") 
            }
            
            Button(action: actions.link) { 
                Image(systemName: "link") 
            }
            
            Spacer()
            
            Button(action: actions.checklist) { 
                Image(systemName: "checklist") 
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial)
    }
}
