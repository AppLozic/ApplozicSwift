//
//  NSAttributedString+Extension.swift
//  ApplozicSwift
//
//  Created by Mukesh on 29/08/19.
//

import Foundation

extension NSAttributedString {
    func replacingCharacters(in range: NSRange, with attributedString: NSAttributedString) -> NSMutableAttributedString {
        let ns = NSMutableAttributedString(attributedString: self)
        ns.replaceCharacters(in: range, with: attributedString)
        return ns
    }

    static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        let ns = NSMutableAttributedString(attributedString: lhs)
        ns.append(rhs)
        return NSAttributedString(attributedString: ns)
    }

    func trimmingCharacters(in set: CharacterSet) -> NSAttributedString {
        let modifiedString = NSMutableAttributedString(attributedString: self)
        modifiedString.trimCharacters(in: set)
        return NSAttributedString(attributedString: modifiedString)
    }
}

public extension NSMutableAttributedString {
    func trimCharacters(in set: CharacterSet) {
        var range = (string as NSString).rangeOfCharacter(from: set, options: .anchored)

        // Trim leading characters from character set.
        while range.location != NSNotFound {
            replaceCharacters(in: range, with: "")
            range = (string as NSString).rangeOfCharacter(from: set, options: .anchored)
        }

        // Trim trailing characters from character set.
        range = (string as NSString).rangeOfCharacter(from: set, options: [.anchored, .backwards])
        while range.location != NSNotFound {
            replaceCharacters(in: range, with: "")
            range = (string as NSString).rangeOfCharacter(from: set, options: [.anchored, .backwards])
        }
    }
}

public extension NSAttributedString.Key {
    static let secondaryFont = NSAttributedString.Key("ALKSecondaryFont")
}
