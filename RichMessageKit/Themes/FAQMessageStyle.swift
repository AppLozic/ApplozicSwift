//
//  FAQMessageStyle.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 03/06/19.
//

import Foundation

public struct FAQMessageStyle {
    public var title = Style(
        font: UIFont.boldSystemFont(ofSize: 14),
        text: .black
    )

    public var description = Style(
        font: UIFont.systemFont(ofSize: 12),
        text: .black
    )

    public var buttonLabel = Style(
        font: UIFont.systemFont(ofSize: 14),
        text: .black
    )

    public var bubble = MessageBubbleStyle(color: UIColor.lightGray, cornerRadius: 5, padding: Padding(left: 10, right: 10, top: 10, bottom: 10))
}

public enum FAQMessageTheme {
    public static var sentMessage = FAQMessageStyle()
    public static var receivedMessage = FAQMessageStyle()
}
