import Foundation
import Vision
import CoreGraphics

struct RecognizedLine: Identifiable {
    enum Side { case left, right }
    let id = UUID()
    let text: String
    let confidence: Float
    let rect: CGRect   // normalized [0,1] Vision space
    let side: Side
    let isSystem: Bool
}

enum OCRCleanup {
    static func clean(observations: [VNRecognizedTextObservation], image: CGImage) -> [RecognizedLine] {
        let topCrop: CGFloat = 0.08
        let bottomCrop: CGFloat = 0.12
        let minConfidence: Float = 0.65
        let minHeight: CGFloat = 0.008
        let maxWidth: CGFloat = 0.95
        let centerBand: ClosedRange<CGFloat> = 0.45...0.55

        let noiseRegex = try? NSRegularExpression(
            pattern: #"(?i)^(delivered|read|imessage|text message|sms|tapback|liked|loved|emphasized|today|yesterday|\n|\r|\s*)$"#,
            options: []
        )
        let noiseContainsRegex = try? NSRegularExpression(
            pattern: #"(?i)(captured|imported|note)"#,
            options: []
        )

        // Sort top→bottom, then left→right
        let sorted = observations.sorted { a, b in
            if abs(a.boundingBox.maxY - b.boundingBox.maxY) > 0.001 { return a.boundingBox.maxY > b.boundingBox.maxY }
            return a.boundingBox.minX < b.boundingBox.minX
        }

        var cleaned: [RecognizedLine] = []
        cleaned.reserveCapacity(sorted.count)

        for obs in sorted {
            guard let top = obs.topCandidates(1).first else { continue }
            let conf = top.confidence
            guard conf >= minConfidence else { continue }
            var rect = obs.boundingBox

            // crop: drop top 8% and bottom 12%
            if rect.maxY > (1.0 - topCrop) { continue }
            if rect.minY < bottomCrop { continue }

            // size constraints
            if rect.height < minHeight { continue }
            if rect.width > maxWidth { continue }

            let midX = rect.midX
            // drop centered meta text (keep only left or right columns)
            if centerBand.contains(midX) { continue }

            let text = top.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            // noise filters
            if let re = noiseRegex, re.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil {
                continue
            }
            if let re2 = noiseContainsRegex, re2.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) != nil {
                continue
            }

            let side: RecognizedLine.Side = (midX < 0.5) ? .left : .right
            cleaned.append(RecognizedLine(text: text, confidence: conf, rect: rect, side: side, isSystem: false))
        }

        return cleaned
    }
}

#if DEBUG
enum OCRDebugStore {
    static var lastLines: [RecognizedLine] = []
}
#endif



