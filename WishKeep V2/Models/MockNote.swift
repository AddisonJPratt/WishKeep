import Foundation
import SwiftUI

struct MockNote: Identifiable, Equatable, Hashable {
    let id: UUID
    let imageName: String
    let text: String
    let dateCaptured: Date
    let dateImported: Date
}

extension MockNote {
    static let samples: [MockNote] = [
        MockNote(id: UUID(), imageName: "photo", text: "How about someplace downtown on the river?", dateCaptured: Date().addingTimeInterval(-3600 * 24), dateImported: Date().addingTimeInterval(-3600 * 12)),
        MockNote(id: UUID(), imageName: "photo.fill", text: "That sounds great 👍", dateCaptured: Date().addingTimeInterval(-3600 * 48), dateImported: Date().addingTimeInterval(-3600 * 36)),
        MockNote(id: UUID(), imageName: "photo.on.rectangle", text: "How about the French café?", dateCaptured: Date().addingTimeInterval(-3600 * 72), dateImported: Date().addingTimeInterval(-3600 * 60)),
        MockNote(id: UUID(), imageName: "rectangle.on.rectangle.angled", text: "Perfect! I’ll see you there at 10:30.", dateCaptured: Date().addingTimeInterval(-3600 * 96), dateImported: Date().addingTimeInterval(-3600 * 84)),
        MockNote(id: UUID(), imageName: "photo.stack", text: "Remind me to tell you about our trip!", dateCaptured: Date().addingTimeInterval(-3600 * 120), dateImported: Date().addingTimeInterval(-3600 * 108))
    ]
}


