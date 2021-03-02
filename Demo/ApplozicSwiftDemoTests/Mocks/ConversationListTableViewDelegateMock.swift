//
//  ConversationListTableViewDelegateMock.swift
//  ApplozicSwiftDemoTests
//
//  Created by Shivam Pokhriyal on 07/12/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation

@testable import ApplozicSwift

class ConversationListTableViewDelegateMock: ALKConversationListTableViewDelegate {
    func muteNotification(conversation _: ALMessage, isMuted _: Bool) {}

    func userBlockNotification(userId _: String, isBlocked _: Bool) {}

    func tapped(_: ALKChatViewModelProtocol, at _: Int) {}

    func emptyChatCellTapped() {}

    func scrolledToBottom() {}
}
