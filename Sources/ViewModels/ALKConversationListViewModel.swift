//
//  ALKConversationListViewModel.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation

public protocol ALKConversationListViewModelDelegate: AnyObject {
    func startedLoading()
    func listUpdated()
    func rowUpdatedAt(position: Int)
}

/**
 The `ConversationListViewModelProtocol` protocol defines the common interface though which an object provides message list information to an instance of `ConversationListTableViewController`.

 A concrete class that conforms to this protocol is provided in the SDK. See `ALKConversationListViewModel`.
 */
public protocol ALKConversationListViewModelProtocol: AnyObject {
    /**
     This method is returns the number of sections in the tableView.
     - Returns: The number of sections in the tableView
     */
    func numberOfSections() -> Int

    /**
     This method is returns the number of rows in a particular tableview section.
     - Parameter section: Section of the tableView.
     - Returns: The number of rows in `section`
     */
    func numberOfRowsInSection(_ section: Int) -> Int

    /**
     This method returns the message object for the given indexpath of the tableview.
     - Parameter indexPath: IndexPath of the current tableView cell.
     - Returns: An object that conforms to ALKChatViewModelProtocol for the required indexPath.
     */
    func chatFor(indexPath: IndexPath) -> ALKChatViewModelProtocol?

    /**
     This method returns the complete message list.
     - Returns: An array of all the messages in the list.
     */
    func getChatList() -> [Any]

    /**
     This method is used to remove a message from the message list.
     - Parameter message: The message object to be removed from the message list.
     */
    func remove(message: ALMessage)

    /**
     This method is used to mute a particular conversation thread.
     - Parameters:
     - message: The message object whose conversation is to be muted.
     - tillTime: NSNumber determining the amount of time conversation is to be muted.
     - withCompletion: Escaping Closure when the mute request is complete.
     */
    func sendMuteRequestFor(message: ALMessage, tillTime: NSNumber, withCompletion: @escaping (Bool) -> Void)

    /**
     This method is used to unmute a particular conversation thread.
     - Parameters:
     - message: The message object whose conversation is to be unmuted.
     - withCompletion: Escaping Closure when the unmute request is complete.
     */
    func sendUnmuteRequestFor(message: ALMessage, withCompletion: @escaping (Bool) -> Void)

    /// This method is used to block a user whose conversation is present in chatlist.
    ///
    /// - Parameters:
    ///   - conversation: Message with the user whom we are going to block
    ///   - withCompletion: Escaping closure when block request is complete.
    func block(conversation: ALMessage, withCompletion: @escaping (Error?, Bool) -> Void)

    /// This method is used to unblock a user whose conversation is present in chatlist.
    ///
    /// - Parameters:
    ///   - conversation: Message with the user whom we are going to unblock
    ///   - withCompletion: Escaping closure when unblock request is complete.
    func unblock(conversation: ALMessage, withCompletion: @escaping (Error?, Bool) -> Void)
}

public final class ALKConversationListViewModel: NSObject, ALKConversationListViewModelProtocol {
    public weak var delegate: ALKConversationListViewModelDelegate?

    var alChannelService = ALChannelService()
    var alContactService = ALContactService()
    var conversationService = ALConversationService()

    override public init() {
        super.init()
    }

    fileprivate var allMessages = [Any]()

    public func prepareController(dbService: ALMessageDBService) {
        delegate?.startedLoading()
        dbService.getMessages(nil)
    }

    public func getChatList() -> [Any] {
        return allMessages
    }

    public func numberOfSections() -> Int {
        return 1
    }

    public func numberOfRowsInSection(_: Int) -> Int {
        return allMessages.count
    }

    public func chatFor(indexPath: IndexPath) -> ALKChatViewModelProtocol? {
        guard indexPath.row < allMessages.count else {
            return nil
        }

        guard let alMessage = allMessages[indexPath.row] as? ALMessage else {
            return nil
        }
        return alMessage
    }

    public func remove(message: ALMessage) {
        let messageToDelete = allMessages.filter { ($0 as? ALMessage) == message }
        guard let messageDel = messageToDelete.first as? ALMessage,
              let index = (allMessages as? [ALMessage])?.firstIndex(of: messageDel)
        else {
            return
        }
        allMessages.remove(at: index)
    }

    public func updateTypingStatus(in viewController: ALKConversationViewController, userId: String, status: Bool) {
        let contactDbService = ALContactDBService()
        let contact = contactDbService.loadContact(byKey: "userId", value: userId)
        guard let alContact = contact else { return }
        guard !alContact.block || !alContact.blockBy else { return }

        viewController.showTypingLabel(status: status, userId: userId)
    }

    public func updateMessageList(messages: [Any]) {
        allMessages = messages
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.delegate?.listUpdated()
        }
    }

    public func updateDeliveryReport(convVC: ALKConversationViewController?, messageKey: String?, contactId: String?, status: Int32?) {
        guard let vc = convVC else { return }
        vc.updateDeliveryReport(messageKey: messageKey, contactId: contactId, status: status)
    }

    public func updateStatusReport(convVC: ALKConversationViewController?, forContact contact: String?, status: Int32?) {
        guard let vc = convVC else { return }
        vc.updateStatusReport(contactId: contact, status: status)
    }

    public func addMessages(messages: Any) {
        guard let alMessages = messages as? [ALMessage], var allMessages = allMessages as? [ALMessage] else {
            return
        }

        for currentMessage in alMessages {
            var messagePresent = [ALMessage]()
            if currentMessage.groupId != nil {
                messagePresent = allMessages.filter { ($0.groupId != nil) ? $0.groupId == currentMessage.groupId : false }
            } else {
                messagePresent = allMessages.filter {
                    $0.groupId == nil ? (($0.contactId != nil) ? $0.contactId == currentMessage.contactId : false) : false
                }
            }

            if let firstElement = messagePresent.first, let index = allMessages.firstIndex(of: firstElement) {
                allMessages[index] = currentMessage
                self.allMessages[index] = currentMessage
            } else {
                self.allMessages.append(currentMessage)
            }
        }
        if self.allMessages.count > 1 {
            self.allMessages = allMessages.sorted { ($0.createdAtTime != nil && $1.createdAtTime != nil) ? Int(truncating: $0.createdAtTime) > Int(truncating: $1.createdAtTime) : false }
        }
        delegate?.listUpdated()
    }

    public func updateStatusFor(userDetail: ALUserDetail) {
        guard let alMessages = allMessages as? [ALMessage], let userId = userDetail.userId else { return }
        let messages = alMessages.filter { ($0.contactId != nil) ? $0.contactId == userId : false }
        guard let firstMessage = messages.first, let index = alMessages.firstIndex(of: firstMessage) else { return }
        delegate?.rowUpdatedAt(position: index)
    }

    public func syncCall(viewController: ALKConversationViewController?, message: ALMessage, isChatOpen: Bool) {
        if isChatOpen {
            viewController?.sync(message: message)
        }
    }

    public func fetchMoreMessages(dbService: ALMessageDBService) {
        guard !ALUserDefaultsHandler.getFlagForAllConversationFetched() else { return }
        delegate?.startedLoading()
        dbService.fetchConversationfromServer(completion: {
            _ in
            NSLog("List updated")
        })
    }

    public func sendUnmuteRequestFor(message: ALMessage, withCompletion: @escaping (Bool) -> Void) {
        let time = (Int(Date().timeIntervalSince1970) * 1000)
        sendMuteRequestFor(message: message, tillTime: time as NSNumber) { success in
            withCompletion(success)
        }
    }

    public func sendMuteRequestFor(message: ALMessage, tillTime: NSNumber, withCompletion: @escaping (Bool) -> Void) {
        if message.isGroupChat, let channel = ALChannelService().getChannelByKey(message.groupId) {
            // Unmute channel
            let muteRequest = ALMuteRequest()
            muteRequest.id = channel.key
            muteRequest.notificationAfterTime = tillTime as NSNumber
            ALChannelService().muteChannel(muteRequest) { _, error in
                if error != nil {
                    withCompletion(false)
                }
                withCompletion(true)
            }
        } else if let contact = ALContactService().loadContact(byKey: "userId", value: message.contactId) {
            // Unmute Contact
            let muteRequest = ALMuteRequest()
            muteRequest.userId = contact.userId
            muteRequest.notificationAfterTime = tillTime as NSNumber
            ALUserService().muteUser(muteRequest) { _, error in
                if error != nil {
                    withCompletion(false)
                }
                withCompletion(true)
            }
        } else {
            withCompletion(false)
        }
    }

    public func block(conversation: ALMessage, withCompletion: @escaping (Error?, Bool) -> Void) {
        ALUserService().blockUser(conversation.contactIds) { error, _ in
            guard let error = error else {
                print("UserId \(String(describing: conversation.contactIds)) is successfully blocked")
                withCompletion(nil, true)
                return
            }
            print("Error while blocking userId \(String(describing: conversation.contactIds)) :: \(error)")
            withCompletion(error, false)
        }
    }

    public func unblock(conversation: ALMessage, withCompletion: @escaping (Error?, Bool) -> Void) {
        ALUserService().unblockUser(conversation.contactIds) { error, _ in
            guard let error = error else {
                print("UserId \(String(describing: conversation.contactIds)) is successfully unblocked")
                withCompletion(nil, true)
                return
            }
            print("Error while unblocking userId \(String(describing: conversation.contactIds)) :: \(error)")
            withCompletion(error, false)
        }
    }

    public func updateUserDetail(userId: String, completion: @escaping (Bool) -> Void) {
        ALUserService.updateUserDetail(userId, withCompletion: {
            userDetail in
            guard let detail = userDetail else {
                completion(false)
                return
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "USER_DETAIL_OTHER_VC"), object: detail)
            completion(true)
        })
    }

    public func muteNotification(conversation: ALMessage, isMuted: Bool) {
        var dic = [AnyHashable: Any]()
        dic["Muted"] = isMuted
        dic["Controller"] = self
        if conversation.isGroupChat {
            dic["ChannelKey"] = conversation.groupId
        } else {
            dic["UserId"] = conversation.contactIds
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: ALKNotification.conversationListAction), object: self, userInfo: dic)
    }

    public func userBlockNotification(userId: String, isBlocked: Bool) {
        var dic = [AnyHashable: Any]()
        dic["UserId"] = userId
        dic["Controller"] = self
        dic["Blocked"] = isBlocked
        NotificationCenter.default.post(name: Notification.Name(rawValue: ALKNotification.conversationListAction), object: self, userInfo: dic)
    }

    public func conversationViewModelOf(
        type conversationViewModelType: ALKConversationViewModel.Type,
        contactId: String?,
        channelId: NSNumber?,
        conversationId: NSNumber?,
        localizedStringFileName: String?
    ) -> ALKConversationViewModel {
        var convProxy: ALConversationProxy?
        if let convId = conversationId, let conversationProxy = conversationService.getConversationByKey(convId) {
            convProxy = conversationProxy
        }

        let convViewModel = conversationViewModelType.init(
            contactId: contactId,
            channelKey: channelId,
            conversationProxy: convProxy,
            localizedStringFileName: localizedStringFileName
        )
        return convViewModel
    }
}
