//
//  ALKConversationViewController+NavigationBar.swift
//  ApplozicSwift
//
//  Created by Mukesh on 22/06/20.
//

import ApplozicCore
import Foundation

extension ALKConversationViewController: NavigationBarCallbacks {
    open func titleTapped() {
        if let contact = contactDetails(), let contactId = contact.userId {
            let info: [String: Any] =
                ["Id": contactId,
                 "Name": contact.getDisplayName() ?? "",
                 "Controller": self]

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "UserProfileSelected"), object: info)
        }
        guard isGroupDetailActionEnabled else {
            if viewModel != nil, let channelKey = viewModel.channelKey {
                let info: [String: Any] =
                    ["ChannelKey": channelKey,
                     "Controller": self]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ChannelDetailSelected"), object: info)
            }
            return
        }
        showParticipantListChat()
    }

    private func contactDetails() -> ALContact? {
        guard viewModel != nil else { return nil }
        guard
            viewModel.channelKey == nil,
            viewModel.conversationProxy == nil,
            let contactId = viewModel.contactId
        else {
            return nil
        }
        return ALContactService().loadContact(byKey: "userId", value: contactId)
    }
}
