//
//  MessageStyle.swift
//  RichMessageKit
//
//  Created by Shivam Pokhriyal on 18/01/19.
//

import Foundation

public struct MessageStyle {
    /// Style for display name
    public var displayName = Style(
        font: UIFont.systemFont(ofSize: 14),
        text: UIColor.darkText
    )

    /// Style for message text.
    public var message = Style(
        font: UIFont.systemFont(ofSize: 14),
        text: UIColor.black
    )

    /// Style for time.
    public var time = Style(
        font: UIFont.systemFont(ofSize: 12),
        text: UIColor.darkText
    )

    /// Style for message bubble
    public var bubble = MessageBubbleStyle(color: UIColor.lightGray, cornerRadius: 5, padding: Padding(left: 10, right: 10, top: 10, bottom: 10))

    public init() {}
}

/// Message view theme.
public enum MessageTheme {
    /// Message style for sent message
    public static var sentMessage = MessageStyle()

    /// Message style for received message
    public static var receivedMessage = MessageStyle()

    /// Style for sent message status icon like read, delivered etc.
    public static var messageStatus = SentMessageStatus()
}

public extension MessageTheme {
    typealias MessageStatusType = MessageStatus

    enum StatusIcon {
        case templateImageWithTint(image: UIImage, tintColor: UIColor)
        case normalImage(image: UIImage)
        case none
    }

    /// Style information for Sent Message status(read receipt).
    struct SentMessageStatus {
        private(set) var statusIcons: [MessageStatusType: StatusIcon] = {
            var icons = [MessageStatusType: StatusIcon]()
            for option in MessageStatusType.allCases {
                switch option {
                case .read:
                    icons[.read] = .templateImageWithTint(
                        image: UIImage(named: "read", in: Bundle.richMessageKit, compatibleWith: nil) ?? UIImage(),
                        tintColor: UIColor(netHex: 0x0578FF)
                    )
                case .delivered:
                    icons[.delivered] = .normalImage(
                        image: UIImage(named: "delivered", in: Bundle.richMessageKit, compatibleWith: nil) ?? UIImage()
                    )
                case .sent:
                    icons[.sent] = .normalImage(
                        image: UIImage(named: "sent", in: Bundle.richMessageKit, compatibleWith: nil) ?? UIImage()
                    )
                case .pending:
                    icons[.pending] = .templateImageWithTint(
                        image: UIImage(named: "pending", in: Bundle.richMessageKit, compatibleWith: nil) ?? UIImage(),
                        tintColor: .red
                    )
                }
            }
            return icons
        }()

        /// Sets the icon and tint color for the given message status type.
        ///
        /// - Parameters:
        ///   - icon: The image to use for specific status type.
        ///   - type: The status(`MessageStatusType`) for which the specified icon
        ///           will be used.
        public mutating func set(
            icon: StatusIcon,
            for type: MessageStatusType
        ) {
            statusIcons[type] = icon
        }
    }
}
