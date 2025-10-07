import SwiftUI

struct BlockEditorView: View {
    @State var blocks: [Block]   // pass @State or SwiftData relationship
    @State private var showSlashAtIndex: Int? = nil

    var body: some View {
        VStack(spacing: 10) {
            ForEach($blocks.sorted(by: { $0.order.wrappedValue < $1.order.wrappedValue })) { $block in
                HStack(alignment: .top) {
                    DragHandle()
                        .gesture(dragGesture(for: block))
                    blockView($block)
                }
            }
        }
    }

    @ViewBuilder private func blockView(_ block: Binding<Block>) -> some View {
        switch block.wrappedValue.kind {
        case .divider:
            Divider()
                .padding(.vertical, 8)
                
        case .checklist:
            HStack(alignment: .top) {
                Button { 
                    block.wrappedValue.isChecked.toggle()
                    Haptic.light()
                } label: {
                    Image(systemName: block.wrappedValue.isChecked ? "checkmark.square.fill" : "square")
                        .foregroundColor(.primary)
                }
                .accessibilityLabel(block.wrappedValue.isChecked ? "Uncheck item" : "Check item")
                
                RichTextViewRepresentable(
                    attributed: Binding(
                        get: { block.wrappedValue.attributed },
                        set: { 
                            block.wrappedValue.attributed = $0
                            RichTextStyle.apply(kind: block.wrappedValue.kind, to: $0.mutableCopy() as! NSMutableAttributedString, theme: WKTheme.light) 
                        }
                    ), 
                    placeholder: "Checklist item"
                )
                .onTapGesture { showSlashAtIndex = nil }
            }
            
        default:
            RichTextViewRepresentable(
                attributed: Binding(
                    get: { block.wrappedValue.attributed },
                    set: { 
                        block.wrappedValue.attributed = $0
                        RichTextStyle.apply(kind: block.wrappedValue.kind, to: $0.mutableCopy() as! NSMutableAttributedString, theme: WKTheme.light)
                    }
                ), 
                placeholder: "Type '/' for commands", 
                onSlash: { 
                    showSlashAtIndex = block.wrappedValue.order
                    Haptic.light()
                }
            )
            .overlay(alignment: .topLeading) {
                if showSlashAtIndex == block.wrappedValue.order {
                    SlashMenuView { newKind in
                        block.wrappedValue.kind = newKind
                        showSlashAtIndex = nil
                        Haptic.medium()
                    }
                    .offset(y: -40)
                }
            }
        }
    }

    private func dragGesture(for block: Block) -> some Gesture {
        DragGesture()
            .onEnded { _ in 
                // Simple reorder implementation - could be enhanced with proper drag and drop
                Haptic.medium()
            }
    }
}
