//
//  QuickReplyConfig.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 09/01/19.
//
import Foundation

struct ChatCellPadding {
    enum SentMessage {
        enum Message {
            static let left: CGFloat = 95
            static let right: CGFloat = 10
        }

        enum QuickReply {
            static let left: CGFloat = 75
            static let top: CGFloat = 5
            static let right: CGFloat = 10
            static let bottom: CGFloat = 5
        }

        enum MessageButton {
            static let left: CGFloat = 75
            static let right: CGFloat = 10
            static let top: CGFloat = 5
            static let bottom: CGFloat = 5
        }
    }

    enum ReceivedMessage {
        enum Message {
            static let left: CGFloat = 10
            static let right: CGFloat = 95
            static let top: CGFloat = 2
        }

        enum QuickReply {
            static let left: CGFloat = 5
            static let top: CGFloat = 5
            static let right: CGFloat = 10
            static let bottom: CGFloat = 5
        }

        enum MessageButton {
            static let left: CGFloat = 60
            static let right: CGFloat = 40
            static let top: CGFloat = 5
            static let bottom: CGFloat = 5
        }
    }
}
