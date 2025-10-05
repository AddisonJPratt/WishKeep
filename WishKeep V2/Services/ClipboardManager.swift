import Foundation
import UIKit
internal import CoreData

final class ClipboardManager {
    static let shared = ClipboardManager()
    private init() {}

    func saveClipboardIfAvailable(context: NSManagedObjectContext) {
        guard UIPasteboard.general.hasStrings, let text = UIPasteboard.general.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        ImportService.shared.mergeOrCreate(fromClipboard: text, context: context)
    }
}

