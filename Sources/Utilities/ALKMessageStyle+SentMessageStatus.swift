//
//  ALKMessageStyle+SentMessageStatus.swift
//  ApplozicSwift
//
//  Created by Mukesh on 02/03/20.
//

import Foundation

public extension ALKMessageStyle {
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
                        image: UIImage(
                            named: "read_state_2",
                            in: Bundle.applozic,
                            compatibleWith: nil
                        ) ?? UIImage(),
                        tintColor: UIColor(netHex: 0x0578FF)
                    )
                case .delivered:
                    icons[.delivered] = .normalImage(
                        image: UIImage(
                            named: "read_state_2",
                            in: Bundle.applozic,
                            compatibleWith: nil
                        ) ?? UIImage()
                    )
                case .sent:
                    icons[.sent] = .normalImage(
                        image: UIImage(
                            named: "read_state_1",
                            in: Bundle.applozic,
                            compatibleWith: nil
                        ) ?? UIImage()
                    )
                case .pending:
                    icons[.pending] = .templateImageWithTint(
                        image: UIImage(
                            named: "seen_state_0",
                            in: Bundle.applozic,
                            compatibleWith: nil
                        ) ?? UIImage(),
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
