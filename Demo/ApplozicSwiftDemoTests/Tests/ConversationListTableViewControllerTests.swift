//
//  ConversationListTableViewControllerTests.swift
//  ApplozicSwiftDemoTests
//
//  Created by Shivam Pokhriyal on 07/12/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation
import XCTest
@testable import ApplozicSwift

class ConversationListTableViewControllerTests: XCTestCase {
    var conversationVM: ALKConversationViewModel!

    override func setUp() {
        super.setUp()
        conversationVM = ALKConversationViewModel(contactId: nil, channelKey: nil, localizedStringFileName: ALKConfiguration().localizedStringFileName)
    }

    func testMuteConversationCalledFromDelegate() {
        let conversationListTableVCMock = ConversationListTableVCMock(viewModel: ALKConversationListViewModel(), dbService: ALMessageDBService(), configuration: ALKConfiguration(), showSearch: false)

        let muteConversationVC = MuteConversationViewController(delegate: conversationListTableVCMock.self, conversation: MockMessage().message, atIndexPath: IndexPath(row: 0, section: 0), configuration: ALKConfiguration())

        XCTAssertFalse(conversationListTableVCMock.isMuteCalled)

        muteConversationVC.tappedConfirm()

        XCTAssertTrue(conversationListTableVCMock.isMuteCalled)
    }
}
