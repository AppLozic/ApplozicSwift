//
//  ALKTemplateMessagesViewModel.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 27/12/17.
//

import ApplozicCore
import Foundation

open class ALKTemplateMessagesViewModel: NSObject {
    open var messageTemplates: [ALKTemplateMessageModel]

    public var leftRightPadding: CGFloat = 10.0
    public var height: CGFloat = 40.0

    public var textFont = Font.normal(size: 16.0).font()

    public init(messageTemplates: [ALKTemplateMessageModel]) {
        self.messageTemplates = messageTemplates
    }

    open func getNumberOfItemsIn(section _: Int) -> Int {
        return messageTemplates.count
    }

    open func getTextForItemAt(row: Int) -> String? {
        guard row >= 0, row < messageTemplates.count else {
            return nil
        }
        return messageTemplates[row].text
    }

    open func getSizeForItemAt(row: Int) -> CGSize {
        guard row >= 0, row < messageTemplates.count else {
            return CGSize(width: 0, height: 0)
        }
        let size = (messageTemplates[row].text as NSString)
            .size(withAttributes: [NSAttributedString.Key.font: textFont])
        let newSize = CGSize(width: size.width + leftRightPadding, height: height)
        return newSize
    }

    open func getTemplateForItemAt(row: Int) -> ALKTemplateMessageModel? {
        guard row >= 0, row < messageTemplates.count else {
            return nil
        }
        return messageTemplates[row]
    }

    open func updateLast(message _: ALMessage) {
        // Use last message to check the message type and to see if it's receiver's or sender's message
    }
}
