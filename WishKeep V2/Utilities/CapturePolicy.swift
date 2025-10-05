import Foundation

enum CaptureMode: String { case screenshots, clipboard, mixed }

struct CaptureDecisionInput {
    let recentScreenshots: [Note]
    let clipboardText: String?
    let newScreenshotOCR: String?
}

enum DecisionResult {
    case createNew(mode: CaptureMode)
    case mergeIntoScreenshot(screenshotId: UUID, mode: CaptureMode)
}

enum CapturePolicy {
    static func decideOnScreenshotImport(ocr: String, isTruncated: Bool) -> (mode: CaptureMode, flags: [String: Bool]) {
        return (.screenshots, ["isTruncated": isTruncated])
    }

    static func decideOnClipboardSave(text: String, recentScreenshots: [Note]) -> DecisionResult {
        // Choose the screenshot with maximum similarity
        let best = recentScreenshots.max { a, b in
            similarity(a.text ?? "", text) < similarity(b.text ?? "", text)
        }
        if let s = best, shouldMerge(screenshotText: s.text ?? "", clipboardText: text) {
            return .mergeIntoScreenshot(screenshotId: s.id ?? UUID(), mode: .mixed)
        }
        return .createNew(mode: .clipboard)
    }

    static func shouldMerge(screenshotText: String, clipboardText: String) -> Bool {
        return isPrefix(screenshotText, clipboardText) || (similarity(screenshotText, clipboardText) >= 0.8 && clipboardText.count > screenshotText.count)
    }

    private static func isPrefix(_ a: String, _ b: String) -> Bool {
        let al = a.lowercased()
        let bl = b.lowercased()
        return bl.hasPrefix(al) || al.hasPrefix(bl)
    }

    private static func similarity(_ a: String, _ b: String) -> Double {
        // Jaccard similarity over word tokens
        let ta = Set(a.lowercased().split{ !$0.isLetter && !$0.isNumber })
        let tb = Set(b.lowercased().split{ !$0.isLetter && !$0.isNumber })
        if ta.isEmpty && tb.isEmpty { return 1 }
        let inter = Double(ta.intersection(tb).count)
        let union = Double(ta.union(tb).count)
        return inter / max(union, 1)
    }
}


