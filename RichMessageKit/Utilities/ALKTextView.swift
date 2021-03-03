//
//  ALKTextView.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 13/06/19.
//

import Foundation

/// This disables selection in UITextView.
/// https://stackoverflow.com/a/44878203/6671572
class ALKTextView: UITextView {
    override open func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
        guard let pos = closestPosition(to: point) else { return false }
        guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }
        let startIndex = offset(from: beginningOfDocument, to: range.start)
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }

    override open var canBecomeFirstResponder: Bool {
        return true
    }
}
