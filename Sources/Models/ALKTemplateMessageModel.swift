//
//  ALKTemplateMessageModel.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 27/12/17.
//

import Foundation

open class ALKTemplateMessageModel: NSObject {
    /// Should be a unique identifier.
    open var identifier: String

    /// Text to display.
    open var text: String

    /// If not set and `sendMessageOnSelection` is true
    /// then the value of `text` will be used to send the message.
    open var messageToSend: String?

    /// If true then the template will be shown
    /// irrespective of the message type of last message.
    open var showInAllCases: Bool = true

    open var onlyShowWhenLastMessageIsText: Bool = false
    open var onlyShowWhenLastMessageIsImage: Bool = false
    open var onlyShowWhenLastMessageIsVideo: Bool = false

    /// If set to false then the message will not be sent.
    open var sendMessageOnSelection: Bool = true

    public init(identifier: String, text: String) {
        self.identifier = identifier
        self.text = text
    }
}

public extension ALKTemplateMessageModel {
    /// Json will be parsed and mapped to the model.
    convenience init?(json: [String: Any]) {
        guard let identifier = json["identifier"] as? String,
              let text = json["text"] as? String
        else {
            return nil
        }
        self.init(identifier: identifier, text: text)

        if let messageToSend = json["messageToSend"] as? String {
            self.messageToSend = messageToSend
        }
        if let sendMessageOnSelection = json["sendMessageOnSelection"] as? Bool {
            self.sendMessageOnSelection = sendMessageOnSelection
        }
    }
}
