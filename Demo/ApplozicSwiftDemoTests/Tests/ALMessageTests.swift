//
//  ALMessageTests.swift
//  ApplozicSwiftDemoTests
//
//  Created by Mukesh Thawani on 25/03/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import XCTest

import ApplozicCore
@testable import ApplozicSwift

class ALMessageTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    func testMyMessage_WhenTypeIsMyMessage() {
        let message = MockMessage().message
        message.type = myMessage
        XCTAssertTrue(message.isMyMessage)
    }

    func testMyMessage_WhenTypeIsNil() {
        let message = MockMessage().message
        message.type = nil
        XCTAssertFalse(message.isMyMessage)
    }

    func testMessageType_WhenTypeIsText() {
        let message = MockMessage().message
        message.contentType = Int16(ALMESSAGE_CONTENT_DEFAULT)
        XCTAssert(message.messageType == .text)
        // TODO: Check if imageURL, path and other items are nil or empty as it's a text message
    }

    func testMessageType_WhenTypeIsImage() {
        let message = MockMessage().message
        message.contentType = Int16(ALMESSAGE_CONTENT_ATTACHMENT)
        let fileMetaInfo = ALFileMetaInfo()
        fileMetaInfo.contentType = "image/xyz"
        message.fileMeta = fileMetaInfo
        XCTAssert(message.messageType == .photo)
    }

    func testMessageType_WhenGenericCard() {
        let message = MockMessage().message
        let mockMetaData = NSMutableDictionary()
        mockMetaData["contentType"] = "300"
        mockMetaData["templateId"] = "10"
        message.metadata = mockMetaData
        XCTAssert(message.messageType == .cardTemplate)
    }

    func testMessageType_WhenFAQTemplate() {
        let message = MockMessage().message
        let mockMetaData = NSMutableDictionary()
        mockMetaData["contentType"] = "300"
        mockMetaData["templateId"] = "8"
        message.metadata = mockMetaData
        XCTAssert(message.messageType == .faqTemplate)
    }

    func testMessageType_WhenSourceIsEmail() {
        let message = MockMessage().message
        message.source = 7
        XCTAssert(message.messageType == .email)
    }
}
