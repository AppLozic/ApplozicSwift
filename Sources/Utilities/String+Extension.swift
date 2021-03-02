//
//  String+Extension.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Extension for String

// get char at index
extension String {
    subscript(idx: Int) -> Character {
        guard let strIdx = index(startIndex, offsetBy: idx, limitedBy: endIndex)
        else { fatalError("String index out of bounds") }
        return self[strIdx]
    }

    // let testStr:String = "12345"
    // print(testStr[2])
}

extension String {
    func isCompose(of word: String) -> Bool {
        return range(of: word, options: .literal) != nil ? true : false
    }
}

// get index of char
public extension String {
    func indexOfCharacter(char: Character) -> Int? {
        guard let range = range(of: String(char)) else {
            return nil
        }
        return distance(from: startIndex, to: range.lowerBound)
    }
}

// get w h
extension String {
    func rectWithConstrainedSize(_ size: CGSize, font: UIFont) -> CGRect {
        let boundingBox = (self as NSString).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return boundingBox
    }

    func evaluateStringWidth(textToEvaluate: String, fontSize: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes = NSDictionary(object: font, forKey: NSAttributedString.Key.font as NSCopying)
        let sizeOfText = textToEvaluate.size(withAttributes: attributes as! [NSAttributedString.Key: Any] as [NSAttributedString.Key: Any])
        return sizeOfText.width
    }
}

extension String {
    func stripHTML() -> String {
        return addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }

    func trim() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension String {
    func isValidEmail(email: String) -> Bool {
        let REGEX: String
        REGEX = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", REGEX).evaluate(with: email)
    }
}

extension String {
    var data: Data {
        return Data(utf8)
    }
}
