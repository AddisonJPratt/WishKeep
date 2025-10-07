import SwiftUI

struct SlashMenuView: View {
    var onPick: (Block.Kind) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add or Turn into")
                .font(.headline)
            
            menuRow(.heading1, "Heading 1")
            menuRow(.heading2, "Heading 2")
            menuRow(.paragraph, "Paragraph")
            menuRow(.bullet, "Bulleted list")
            menuRow(.number, "Numbered list")
            menuRow(.checklist, "Checklist")
            menuRow(.quote, "Quote")
            menuRow(.divider, "Divider")
            menuRow(.callout, "Callout")
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 12)
    }
    
    @ViewBuilder private func menuRow(_ kind: Block.Kind, _ label: String) -> some View {
        Button { onPick(kind) } label: {
            HStack { 
                Image(systemName: "plus.circle")
                Text(label)
                Spacer() 
            }
        }
    }
}
