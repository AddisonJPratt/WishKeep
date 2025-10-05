import Foundation
import Vision
import Photos
import UIKit
internal import CoreData
import CryptoKit

final class OCRService {
    static let shared = OCRService()

    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.maxConcurrentOperationCount = 2
        q.qualityOfService = .utility
        return q
    }()

    private init() { }

    func enqueue(noteObjectID: NSManagedObjectID, assetLocalIdentifier: String, context: NSManagedObjectContext) {
        let op = BlockOperation { [weak self] in
            self?.performOCR(noteObjectID: noteObjectID, assetLocalIdentifier: assetLocalIdentifier, context: context)
        }
        queue.addOperation(op)
    }

    private func performOCR(noteObjectID: NSManagedObjectID, assetLocalIdentifier: String, context: NSManagedObjectContext) {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetLocalIdentifier], options: nil).firstObject else {
            return
        }

        let targetSize = CGSize(width: 2000, height: 2000)
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true

        var imageForOCR: UIImage?
        PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { image, _ in
            imageForOCR = image
        }

        guard let image = imageForOCR, let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return
        }

        let observations = (request.results as? [VNRecognizedTextObservation]) ?? []

        let cleaned = OCRCleanup.clean(observations: observations, image: cgImage)
        #if DEBUG
        OCRDebugStore.lastLines = cleaned
        #endif
        let lines = cleaned.map { $0.text }
        let normalized = normalizeText(lines: lines)
        let isTruncated = normalized.hasSuffix("…") || normalized.hasSuffix("...")

        guard !normalized.isEmpty else { return }

        context.perform {
            if let note = try? context.existingObject(with: noteObjectID) as? Note {
                note.text = normalized
                note.textHash = self.computeTextHash(normalized)
                note.isTruncated = isTruncated
                // Store simple metrics for display policy
                let avgConf = cleaned.isEmpty ? 0 : cleaned.map { Double($0.confidence) }.reduce(0, +) / Double(cleaned.count)
                note.ocrConfidence = avgConf
                note.lineCount = Int32(cleaned.count)
                let leftCount = cleaned.filter { $0.side == .left }.count
                let rightCount = cleaned.count - leftCount
                note.isMostlyOneSpeaker = (leftCount == 0 || rightCount == 0) || max(leftCount, rightCount) >= Int(Double(cleaned.count) * 0.8)
                try? context.save()
            }
        }
    }

    private func normalizeText(lines: [String]) -> String {
        guard !lines.isEmpty else { return "" }
        let joined = lines.joined(separator: "\n")
        let collapsed = joined.replacingOccurrences(of: "\n{2,}", with: "\n", options: .regularExpression)
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isNoise(_ line: String) -> Bool {
        let lower = line.lowercased()
        if lower == "delivered" || lower == "read" || lower == "imessage" { return true }
        if lower == "today" || lower == "yesterday" { return true }
        // Timestamp formats like "3:18 PM", "3:18PM", "15:18"
        let patterns = [
            "^\\d{1,2}:[0-5]\\d\\s?(am|pm)$",
            "^\\d{1,2}:[0-5]\\d$",
            "^\\d{1,2}\\s?(am|pm)$"
        ]
        for p in patterns {
            if line.range(of: p, options: [.regularExpression, .caseInsensitive]) != nil { return true }
        }
        return false
    }

    func computeTextHash(_ text: String) -> String {
        let lower = text.lowercased()
        let nfkd = lower.applyingTransform(.toUnicodeName, reverse: false) ?? lower
        let stripped = nfkd.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
        let data = Data(stripped.utf8)
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
}

