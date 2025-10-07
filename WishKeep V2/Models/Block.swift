import SwiftUI
import SwiftData

@Model
final class Block {
    enum Kind: String, Codable, CaseIterable {
        case paragraph, heading1, heading2, bullet, number, checklist, quote, divider, callout
    }
    
    var id: UUID
    var kindRaw: String
    var attributedData: Data   // archived NSAttributedString (RTF) or Markdown
    var isChecked: Bool        // used for checklist
    var order: Int
    
    init(kind: Kind = .paragraph, text: NSAttributedString = .init(string: ""), order: Int = 0, isChecked: Bool = false) {
        self.id = UUID()
        self.kindRaw = kind.rawValue
        self.attributedData = try! text.archivedData()
        self.isChecked = isChecked
        self.order = order
    }
    
    var kind: Kind {
        get { Kind(rawValue: kindRaw) ?? .paragraph }
        set { kindRaw = newValue.rawValue }
    }
    
    var attributed: NSAttributedString {
        get { 
            do {
                return try NSAttributedString(data: attributedData, options: [.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil)
            } catch {
                return NSAttributedString(string: "")
            }
        }
        set { attributedData = (try? newValue.archivedData()) ?? Data() }
    }
}

extension NSAttributedString {
    func archivedData() throws -> Data {
        try self.data(from: NSRange(location: 0, length: length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd])
    }
}
