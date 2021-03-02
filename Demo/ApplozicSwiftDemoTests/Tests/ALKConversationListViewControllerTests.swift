//
//  ALKConversationListViewControllerTests.swift
//  ApplozicSwiftDemoTests
//
//  Created by Shivam Pokhriyal on 13/10/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import ApplozicCore
import XCTest
@testable import ApplozicSwift
class ALKConversationListViewControllerTests: XCTestCase {
    var conversationListVC: ALKConversationListViewController!

    override func setUp() {
        super.setUp()
        conversationListVC = ALKConversationListViewController(configuration: ALKConfiguration())
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testNewMessage_WhenActiveThreadIsDifferent() {
        let conversationVM = ALKConversationViewModel(contactId: nil, channelKey: nil, localizedStringFileName: ALKConfiguration().localizedStringFileName)
        let message = MockMessage().message
        let result = conversationListVC.isNewMessageForActiveThread(alMessage: message, vm: conversationVM)
        XCTAssertFalse(result)
    }

    func testNewMessage_WhenActiveThreadIsSame() {
        let conversationVM = ALKConversationViewModel(
            contactId: "testUser123",
            channelKey: nil,
            localizedStringFileName: ALKConfiguration().localizedStringFileName
        )
        let message = MockMessage().message
        message.contactIds = "testUser123"
        let result = conversationListVC
            .isNewMessageForActiveThread(alMessage: message, vm: conversationVM)
        XCTAssertTrue(result)
    }

    func testDelegateCallback_whenMessageThreadIsSelected() {
        let selectItemExpectation = XCTestExpectation(description: "Conversation list item selected")
        let conversation = ConversationListTest()
        conversation.selectItemExpectation = selectItemExpectation
        let conversationVC = ALKConversationViewControllerMock(configuration: ALKConfiguration(), individualLaunch: true)
        conversationVC.viewModel = ALKConversationViewModelMock(contactId: nil, channelKey: 000, localizedStringFileName: ALKConfiguration().localizedStringFileName)

        // Pass all mocks
        conversationListVC.delegate = conversation
        conversationListVC.dbService = ALMessageDBServiceMock()
        conversationListVC.conversationViewController = conversationVC

        // Select first thread
        conversationListVC.viewWillAppear(false)
        let firstIndex = IndexPath(row: 0, section: 0)
        XCTAssertNotNil(conversationListVC.tableView)
        let tableView = conversationListVC.tableView
        tableView.delegate?.tableView?(tableView, didSelectRowAt: firstIndex)

        wait(for: [selectItemExpectation], timeout: 2)
    }

    func testMessageSentByLoggedInUser_WhenTypeOutBox() {
        let message = MockMessage().message
        message.contactIds = "testUser123"
        message.type = "5" // Message type OUTBOX
        XCTAssertTrue(conversationListVC.isMessageSentByLoggedInUser(alMessage: message))
    }

    func testMessageSentByLoggedInUser_WhenTypeInBox() {
        let message = MockMessage().message
        message.contactIds = "testUser123"
        message.type = "4" // Message type INBOX
        XCTAssertFalse(conversationListVC.isMessageSentByLoggedInUser(alMessage: message))
    }
}
