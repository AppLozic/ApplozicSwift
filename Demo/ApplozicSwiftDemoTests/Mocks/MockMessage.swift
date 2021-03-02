//
//  MockMessage.swift
//  ApplozicSwiftDemoTests
//
//  Created by Shivam Pokhriyal on 11/03/19.
//  Copyright © 2019 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation

struct MockMessage {
    var message: ALMessage = {
        let alMessage = ALMessage()
        alMessage.to = "testexample"
        alMessage.contactIds = "testexample"
        alMessage.message = "hello there"
        alMessage.type = "5"
        let date = Date(timeIntervalSince1970: -123_456_789.0).timeIntervalSince1970 * 1000
        alMessage.createdAtTime = NSNumber(value: date)
        alMessage.sendToDevice = false
        alMessage.deviceKey = ALUserDefaultsHandler.getDeviceKeyString()
        alMessage.shared = false
        alMessage.fileMeta = nil
        alMessage.storeOnDevice = false
        alMessage.contentType = Int16(ALMESSAGE_CONTENT_DEFAULT)
        alMessage.key = UUID().uuidString
        alMessage.source = Int16(AL_SOURCE_IOS)
        alMessage.conversationId = nil
        alMessage.groupId = nil
        alMessage.status = NSNumber(integerLiteral: Int(SENT.rawValue))
        return alMessage
    }()
}
