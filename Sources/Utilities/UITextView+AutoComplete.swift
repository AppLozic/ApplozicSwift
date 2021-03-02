//
//  UITextView+AutoComplete.swift
//  ApplozicSwift
//
//  Created by Mukesh on 18/09/19.
//

import UIKit

extension UITextView {
    func find(prefixes: Set<String>) -> (prefix: String, word: String, range: NSRange)? {
        guard !prefixes.isEmpty,
              let result = wordAtCaret,
              !result.word.isEmpty
        else { return nil }
        for prefix in prefixes {
            if result.word.hasPrefix(prefix) {
                return (prefix, result.word, result.range)
            }
        }
        return nil
    }

    var wordAtCaret: (word: String, range: NSRange)? {
        guard let caretRange = self.caretRange,
              let result = text.word(at: caretRange)
        else { return nil }

        let range = NSRange(result.range, in: text)
        return (result.word, range)
    }

    var caretRange: NSRange? {
        guard let selectedRange = selectedTextRange else { return nil }
        return NSRange(
            location: offset(from: beginningOfDocument, to: selectedRange.start),
            length: offset(from: selectedRange.start, to: selectedRange.end)
        )
    }
}
