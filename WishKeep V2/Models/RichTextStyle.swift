import UIKit
import SwiftUI

struct RichTextStyle {
    static let bodyFont = UIFont.preferredFont(forTextStyle: .body)
    static let h1 = UIFont.systemFont(ofSize: 26, weight: .bold)
    static let h2 = UIFont.systemFont(ofSize: 22, weight: .semibold)
    static let codeFont = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
    static let highlight = UIColor.systemYellow.withAlphaComponent(0.35)
    
    static func apply(kind: Block.Kind, to attr: NSMutableAttributedString, theme: WKTheme) {
        let range = NSRange(location: 0, length: attr.length)
        
        // Apply base text color
        attr.addAttribute(.foregroundColor, value: UIColor(theme.ink), range: range)
        
        switch kind {
        case .heading1: 
            attr.addAttribute(.font, value: h1, range: range)
            attr.addAttribute(.kern, value: 0.2, range: range)
        case .heading2: 
            attr.addAttribute(.font, value: h2, range: range)
        case .callout:
            attr.addAttribute(.font, value: bodyFont, range: range)
            attr.addAttribute(.foregroundColor, value: UIColor(theme.ink), range: range)
        default: 
            attr.addAttribute(.font, value: bodyFont, range: range)
        }
    }
}
