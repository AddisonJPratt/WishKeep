import SwiftUI

struct WKBlockEditorView: View {
    @Environment(\.wkTheme) var theme
    var blocks: [Block]
    @State private var showSlashAtIndex: Int? = nil
    @State private var isEditing = false

    var body: some View {
        VStack(spacing: 10) {
            ForEach(blocks.sorted(by: { $0.order < $1.order }), id: \.id) { block in
                HStack(alignment: .top, spacing: 12) {
                    DragHandle()
                        .gesture(dragGesture(for: block))
                    
                    WKBlockView(block: block, isEditing: $isEditing, showSlashAtIndex: $showSlashAtIndex)
                }
            }
        }
        .onTapGesture {
            isEditing = true
        }
    }

    private func dragGesture(for block: Block) -> some Gesture {
        DragGesture()
            .onEnded { _ in
                // TODO: Implement drag reordering
            }
    }
}

struct WKBlockView: View {
    @Environment(\.wkTheme) var theme
    var block: Block
    @Binding var isEditing: Bool
    @Binding var showSlashAtIndex: Int?
    
    var body: some View {
        Group {
            switch block.kind {
            case .divider:
                WKDividerView()
            case .checklist:
                WKChecklistView(block: block)
            case .quote:
                WKQuoteView(block: block)
            case .callout:
                WKCalloutView(block: block)
            default:
                WKDefaultBlockView(block: block, isEditing: $isEditing, showSlashAtIndex: $showSlashAtIndex)
            }
        }
    }
}

struct WKDefaultBlockView: View {
    @Environment(\.wkTheme) var theme
    var block: Block
    @Binding var isEditing: Bool
    @Binding var showSlashAtIndex: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RichTextViewRepresentable(
                attributed: Binding(
                    get: { block.attributed },
                    set: { 
                        block.attributed = $0
                        RichTextStyle.apply(kind: block.kind, to: $0.mutableCopy() as! NSMutableAttributedString, theme: theme)
                    }
                ),
                placeholder: placeholderText,
                onSlash: { showSlashAtIndex = block.order }
            )
            .font(blockFont)
            .foregroundStyle(theme.ink)
            .padding(.vertical, blockVerticalPadding)
            .overlay(alignment: .topLeading) {
                if showSlashAtIndex == block.order {
                    WKSlashMenuView { newKind in
                        block.kind = newKind
                        showSlashAtIndex = nil
                    }
                    .offset(y: -40)
                }
            }
        }
    }
    
    private var placeholderText: String {
        switch block.kind {
        case .heading1, .heading2: return "Heading..."
        case .bullet: return "List item..."
        case .number: return "Numbered item..."
        case .paragraph: return "Paste or write a memory..."
        default: return "Type something..."
        }
    }
    
    private var blockFont: Font {
        switch block.kind {
        case .heading1: return WKFont.h1
        case .heading2: return WKFont.h2
        default: return WKFont.body
        }
    }
    
    private var blockVerticalPadding: CGFloat {
        switch block.kind {
        case .heading1: return 14
        case .heading2: return 10
        default: return 6
        }
    }
}

struct WKChecklistView: View {
    @Environment(\.wkTheme) var theme
    var block: Block
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                withAnimation(WKTok.spring) {
                    block.isChecked.toggle()
                }
            } label: {
                Image(systemName: block.isChecked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(theme.accent)
                    .font(.title3)
                    .scaleEffect(block.isChecked ? 1.0 : 0.92)
            }
            .accessibilityLabel(block.isChecked ? "Checked" : "Unchecked")
            
            RichTextViewRepresentable(
                attributed: Binding(
                    get: { block.attributed },
                    set: { block.attributed = $0 }
                ),
                placeholder: "Checklist item..."
            )
            .font(WKFont.body)
            .foregroundStyle(theme.ink)
            .strikethrough(block.isChecked)
        }
    }
}

struct WKQuoteView: View {
    @Environment(\.wkTheme) var theme
    var block: Block
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(theme.accent.opacity(0.22))
                .frame(width: 4)
                .cornerRadius(2)
            
            RichTextViewRepresentable(
                attributed: Binding(
                    get: { block.attributed },
                    set: { block.attributed = $0 }
                ),
                placeholder: "Quote..."
            )
            .font(WKFont.body)
            .foregroundStyle(theme.subInk)
            .italic()
        }
        .padding(.vertical, 8)
    }
}

struct WKCalloutView: View {
    @Environment(\.wkTheme) var theme
    var block: Block
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(theme.accent)
                .font(.title3)
            
            RichTextViewRepresentable(
                attributed: Binding(
                    get: { block.attributed },
                    set: { block.attributed = $0 }
                ),
                placeholder: "Callout..."
            )
            .font(WKFont.body)
            .foregroundStyle(theme.ink)
        }
        .padding(WKTok.pM)
        .background(
            LinearGradient(
                colors: [theme.glowA.opacity(0.22), theme.surface.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18)
        )
    }
}

struct WKDividerView: View {
    @Environment(\.wkTheme) var theme
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [theme.mist, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.vertical, 8)
    }
}

struct WKSlashMenuView: View {
    @Environment(\.wkTheme) var theme
    var onPick: (Block.Kind) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add or Turn into")
                .font(WKFont.h2)
                .foregroundStyle(theme.ink)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                menuRow(.heading1, "Heading 1", "textformat.size")
                menuRow(.heading2, "Heading 2", "textformat.size")
                menuRow(.paragraph, "Paragraph", "text.alignleft")
                menuRow(.bullet, "Bulleted list", "list.bullet")
                menuRow(.number, "Numbered list", "list.number")
                menuRow(.checklist, "Checklist", "checklist")
                menuRow(.quote, "Quote", "quote.bubble")
                menuRow(.divider, "Divider", "minus")
                menuRow(.callout, "Callout", "sparkles")
            }
        }
        .padding(WKTok.pM)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: WKTok.cM))
        .overlay(
            RoundedRectangle(cornerRadius: WKTok.cM)
                .stroke(theme.mist.opacity(0.45), lineWidth: 1)
        )
        .shadow(color: WKTok.shadowSoft, radius: 12, y: 6)
    }
    
    @ViewBuilder 
    private func menuRow(_ kind: Block.Kind, _ label: String, _ icon: String) -> some View {
        Button {
            onPick(kind)
            Haptic.light()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(theme.accent)
                    .font(.title3)
                Text(label)
                    .font(WKFont.meta)
                    .foregroundStyle(theme.ink)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.accent.opacity(0.14))
                    .opacity(0) // Will be animated on selection
            )
        }
        .buttonStyle(.plain)
    }
}
