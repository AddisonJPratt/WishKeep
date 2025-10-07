import Foundation
import SwiftUI

enum MarkdownCodec {
    // Build Markdown from Block arrays
    static func exportMarkdown(blocks: [Block]) -> String {
        blocks.sorted(by: { $0.order < $1.order }).map { b in
            let plain = b.attributed.string
            switch b.kind {
            case .heading1: return "# " + plain
            case .heading2: return "## " + plain
            case .bullet:   return "- " + plain
            case .number:   return "1. " + plain
            case .checklist: return "- [\(b.isChecked ? "x":" ")] " + plain
            case .quote:    return "> " + plain
            case .divider:  return "---"
            case .callout:  return "> 💬 " + plain
            case .paragraph: return plain
            }
        }.joined(separator: "\n")
    }

    // Parse Markdown into simple Blocks (headings, bullets, quotes, divider)
    static func importMarkdown(_ md: String) -> [Block] {
        var out: [Block] = []
        let lines = md.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
        var order = 0
        
        for line in lines {
            if line.hasPrefix("# ") {
                out.append(Block(kind: .heading1, text: .init(string: String(line.dropFirst(2))), order: order))
            } else if line.hasPrefix("## ") {
                out.append(Block(kind: .heading2, text: .init(string: String(line.dropFirst(3))), order: order))
            } else if line.hasPrefix("- [x] ") || line.hasPrefix("- [ ] ") {
                let checked = line.hasPrefix("- [x] ")
                out.append(Block(kind: .checklist, text: .init(string: String(line.dropFirst(6))), order: order, isChecked: checked))
            } else if line.hasPrefix("- ") {
                out.append(Block(kind: .bullet, text: .init(string: String(line.dropFirst(2))), order: order))
            } else if line.range(of: #"^\d+\.\s"#, options: String.CompareOptions.regularExpression) != nil {
                let content = line.replacingOccurrences(of: #"^\d+\.\s"#, with: "", options: String.CompareOptions.regularExpression)
                out.append(Block(kind: .number, text: .init(string: content), order: order))
            } else if line.hasPrefix("> ") {
                out.append(Block(kind: .quote, text: .init(string: String(line.dropFirst(2))), order: order))
            } else if line == "---" {
                out.append(Block(kind: .divider, text: .init(string: ""), order: order))
            } else {
                out.append(Block(kind: .paragraph, text: .init(string: line), order: order))
            }
            order += 1
        }
        return out
    }
}
