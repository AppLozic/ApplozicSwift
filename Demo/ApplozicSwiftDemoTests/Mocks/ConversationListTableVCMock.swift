//
//  ConversationListTableVCMock.swift
//  ApplozicSwiftDemoTests
//
//  Created by Shivam Pokhriyal on 19/12/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation
@testable import ApplozicSwift

class ConversationListTableVCMock: ALKConversationListTableViewController {
    var isMuteCalled: Bool = false

    override func mute(conversation _: ALMessage, forTime _: Int64, atIndexPath _: IndexPath) {
        isMuteCalled = true
    }

    func tapped(_: ALKChatViewModelProtocol, at _: Int) {}

    func emptyChatCellTapped() {}
}
