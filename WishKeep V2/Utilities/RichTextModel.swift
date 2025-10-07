import Foundation
import Combine

final class RichTextModel: ObservableObject {
    @Published var text: String
    @Published var selectedRange: NSRange = NSRange(location: 0, length: 0)

    init(text: String) { self.text = text }

    private var nsText: NSMutableString { NSMutableString(string: text) }

    private func paragraphRange() -> NSRange {
        let ns = text as NSString
        if selectedRange.location <= ns.length {
            return ns.paragraphRange(for: selectedRange)
        }
        return NSRange(location: 0, length: ns.length)
    }

    func applyBody() {
        // Remove heading markers at paragraph start
        let ns = NSMutableString(string: text)
        let range = paragraphRange()
        let line = ns.substring(with: range)
        let cleaned = line.replacingOccurrences(of: "^[#•\\t\\s]+", with: "", options: .regularExpression)
        ns.replaceCharacters(in: range, with: cleaned)
        text = ns as String
    }

    func applyTitle() { applyHeading(prefix: "# ") }
    func applySubtitle() { applyHeading(prefix: "## ") }

    private func applyHeading(prefix: String) {
        let ns = NSMutableString(string: text)
        let range = paragraphRange()
        var line = ns.substring(with: range)
        line = line.replacingOccurrences(of: "^[#\\s]*", with: "", options: .regularExpression)
        ns.replaceCharacters(in: range, with: prefix + line)
        text = ns as String
    }

    func toggleList() {
        let ns = NSMutableString(string: text)
        let range = paragraphRange()
        let line = ns.substring(with: range)
        if line.trimmingCharacters(in: .whitespaces).hasPrefix("• ") {
            let new = line.replacingOccurrences(of: "^\\n?\\s*• ", with: "", options: .regularExpression)
            ns.replaceCharacters(in: range, with: new)
        } else {
            let new = "• " + line
            ns.replaceCharacters(in: range, with: new)
        }
        text = ns as String
    }

    func indent() {
        let ns = NSMutableString(string: text)
        let range = paragraphRange()
        let line = ns.substring(with: range)
        ns.replaceCharacters(in: range, with: "    " + line)
        text = ns as String
    }
}

extension RichTextModel {
    func applyReturning(_ block: (RichTextModel) -> Void) -> String {
        block(self)
        return self.text
    }
}

