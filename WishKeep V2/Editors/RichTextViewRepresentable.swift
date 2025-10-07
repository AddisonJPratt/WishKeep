import SwiftUI
import UIKit

final class RichTextCoordinator: NSObject, UITextViewDelegate {
    var textDidChange: (NSAttributedString) -> Void
    var onSlash: () -> Void
    
    init(textDidChange: @escaping (NSAttributedString) -> Void, onSlash: @escaping () -> Void) {
        self.textDidChange = textDidChange
        self.onSlash = onSlash
    }
    
    func textViewDidChange(_ textView: UITextView) {
        textDidChange(textView.attributedText)
        if let last = textView.text.last, last == "/" {
            onSlash()
        }
    }
}

struct RichTextViewRepresentable: UIViewRepresentable {
    @Binding var attributed: NSAttributedString
    var font: UIFont = RichTextStyle.bodyFont
    var placeholder: String = ""
    var onSlash: () -> Void = {}

    func makeCoordinator() -> RichTextCoordinator {
        .init(textDidChange: { _ in }, onSlash: onSlash)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView(usingTextLayoutManager: true)
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.delegate = context.coordinator
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.textContainerInset = .zero
        tv.typingAttributes[.font] = font
        tv.attributedText = attributed.length == 0 ? NSAttributedString(string: "") : attributed
        tv.accessibilityLabel = placeholder
        tv.autocorrectionType = .yes
        tv.smartDashesType = .yes
        tv.smartQuotesType = .yes
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributed { 
            uiView.attributedText = attributed 
        }
    }
}

extension UITextView {
    func toggleBold() {
        guard let r = selectedTextRange else { return }
        let range = NSRange(location: offset(from: beginningOfDocument, to: r.start), length: offset(from: r.start, to: r.end))
        let m = NSMutableAttributedString(attributedString: attributedText)
        m.enumerateAttribute(.font, in: range) { value, subRange, _ in
            let current = (value as? UIFont) ?? RichTextStyle.bodyFont
            let new = UIFont.systemFont(ofSize: current.pointSize, weight: current.fontDescriptor.symbolicTraits.contains(.traitBold) ? .regular : .bold)
            m.addAttribute(.font, value: new, range: subRange)
        }
        attributedText = m
    }
    
    func toggleItalic() {
        guard let r = selectedTextRange else { return }
        let range = NSRange(location: offset(from: beginningOfDocument, to: r.start), length: offset(from: r.start, to: r.end))
        let m = NSMutableAttributedString(attributedString: attributedText)
        m.enumerateAttribute(.font, in: range) { value, subRange, _ in
            let current = (value as? UIFont) ?? RichTextStyle.bodyFont
            let isItalic = current.fontDescriptor.symbolicTraits.contains(.traitItalic)
            let new = isItalic ? 
                UIFont.systemFont(ofSize: current.pointSize, weight: .regular) :
                UIFont.italicSystemFont(ofSize: current.pointSize)
            m.addAttribute(.font, value: new, range: subRange)
        }
        attributedText = m
    }
    
    func toggleUnderline() {
        guard let r = selectedTextRange else { return }
        let range = NSRange(location: offset(from: beginningOfDocument, to: r.start), length: offset(from: r.start, to: r.end))
        let m = NSMutableAttributedString(attributedString: attributedText)
        let hasUnderline = m.attribute(.underlineStyle, at: range.location, effectiveRange: nil) != nil
        m.addAttribute(.underlineStyle, value: hasUnderline ? 0 : NSUnderlineStyle.single.rawValue, range: range)
        attributedText = m
    }
    
    func toggleStrikethrough() {
        guard let r = selectedTextRange else { return }
        let range = NSRange(location: offset(from: beginningOfDocument, to: r.start), length: offset(from: r.start, to: r.end))
        let m = NSMutableAttributedString(attributedString: attributedText)
        let hasStrike = m.attribute(.strikethroughStyle, at: range.location, effectiveRange: nil) != nil
        m.addAttribute(.strikethroughStyle, value: hasStrike ? 0 : NSUnderlineStyle.single.rawValue, range: range)
        attributedText = m
    }
    
    func toggleCode() {
        guard let r = selectedTextRange else { return }
        let range = NSRange(location: offset(from: beginningOfDocument, to: r.start), length: offset(from: r.start, to: r.end))
        let m = NSMutableAttributedString(attributedString: attributedText)
        let hasCode = m.attribute(.font, at: range.location, effectiveRange: nil) as? UIFont == RichTextStyle.codeFont
        m.addAttribute(.font, value: hasCode ? RichTextStyle.bodyFont : RichTextStyle.codeFont, range: range)
        attributedText = m
    }
    
    func toggleHighlight() {
        guard let r = selectedTextRange else { return }
        let range = NSRange(location: offset(from: beginningOfDocument, to: r.start), length: offset(from: r.start, to: r.end))
        let m = NSMutableAttributedString(attributedString: attributedText)
        let hasHighlight = m.attribute(.backgroundColor, at: range.location, effectiveRange: nil) != nil
        m.addAttribute(.backgroundColor, value: hasHighlight ? UIColor.clear : RichTextStyle.highlight, range: range)
        attributedText = m
    }
}
