//
//  NotificationHelper.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 25/03/19.
//

import ApplozicCore

public class NotificationHelper {
    /// Stores information about the notification that arrives
    public struct NotificationData {
        public let userId: String?
        public let groupId: NSNumber?
        public let conversationId: NSNumber?
        public var isBlocked: Bool = false
        public var isMute: Bool = false
        public init(userId: String?, groupId: NSNumber?, conversationId: NSNumber?) {
            self.userId = userId
            self.groupId = groupId
            self.conversationId = conversationId

            /// Check block and mute for 1-1 chat.
            if groupId == nil, let userId = userId {
                let contact = ALContactService().loadContact(byKey: "userId", value: userId)
                isBlocked = contact?.block ?? false
                isMute = contact?.isNotificationMuted() ?? false
            }

            /// For group check mute only.
            if let groupId = groupId {
                let group = ALChannelService().getChannelByKey(groupId)
                isMute = group?.isNotificationMuted() ?? false
            }
        }
    }

    public init() {}

    // MARK: - Public methods

    /// Return information for incoming notification
    ///
    /// - Parameter notification: notification that arrived
    /// - Returns: `NotificationData` containing information about userId, groupId or conversationId
    ///             `String` which is the message for which notification came
    public func notificationInfo(_ notification: Notification) -> (NotificationData?, String?) {
        guard let object = notification.object as? String else { return (nil, nil) }
        let notifData = notificationData(using: object)
        guard
            let userInfo = notification.userInfo,
            let alertValue = userInfo["alertValue"] as? String
        else {
            return (notifData, nil)
        }
        return (notifData, alertValue)
    }

    /// Checks if the incoming notification is for currently opened chat.
    ///
    /// - NOTE: Use this information to decide whether to show/hide notification
    /// - Parameters:
    ///   - notification: notification that is tapped
    /// - Returns: Bool value indicating whether notification is for active chat.
    public func isNotificationForActiveThread(_ notification: NotificationData) -> Bool {
        guard
            let topVC = ALPushAssist().topViewController as? ALKConversationViewController,
            let viewModel = topVC.viewModel
        else {
            guard let topVC = ALPushAssist().topViewController,
                  let navVC = topVC.presentingViewController as? ALKBaseNavigationViewController,
                  let conversationViewController = navVC.topViewController as? ALKConversationViewController,
                  let viewModel = conversationViewController.viewModel
            else {
                return false
            }
            return isChatThreadIsOpen(notification, userId: viewModel.contactId, groupId: viewModel.channelKey)
        }
        return isChatThreadIsOpen(notification, userId: viewModel.contactId, groupId: viewModel.channelKey)
    }

    private func isChatThreadIsOpen(_ notification: NotificationData, userId: String?, groupId: NSNumber?) -> Bool {
        let isGroupMessage = notification.groupId != nil && notification.groupId == groupId
        let isOneToOneMessage = notification.groupId == nil && groupId == nil && notification.userId == userId
        if isGroupMessage || isOneToOneMessage {
            return true
        }
        return false
    }

    /// Launches `ALKConversationViewController` from list.
    ///
    /// - NOTE: Use this when list is at the top.
    /// - Parameters:
    ///   - viewController: `ALKConversationListViewController` instance which is on top.
    ///   - notification: notification that is tapped.
    public func openConversationFromListVC(_ viewController: ALKConversationListViewController, notification: NotificationData) {
        viewController.launchChat(contactId: notification.userId, groupId: notification.groupId, conversationId: notification.conversationId)
    }

    /// Returns an instance of list view controller which should be pushed from outside.
    /// It will launch `ALKConversationViewController`.
    ///
    /// - NOTE: Use this to launch chat when some other screen is opened.
    /// - Parameters:
    ///   - notification: notification that is tapped.
    ///   - configuration: `ALKConfiguration` object.
    /// - Returns: An instance of `ALKConversationListViewController`
    public func getConversationVCToLaunch(notification: NotificationData, configuration: ALKConfiguration) -> ALKConversationListViewController {
        let viewController = ALKConversationListViewController(configuration: configuration)
        viewController.contactId = notification.userId
        viewController.conversationId = notification.conversationId
        viewController.channelKey = notification.groupId
        return viewController
    }

    /// Refrehses `ALKConversationViewController` for the arrived notification.
    ///
    /// - NOTE: Use this when `ALKConversationViewController` is at top
    /// - Parameters:
    ///   - viewController: An instance of `ALKConversationViewController` which is at top.
    ///   - notification: notification that is tapped.
    public func refreshConversation(_ viewController: ALKConversationViewController, with notification: NotificationData) {
        viewController.unsubscribingChannel()
        if !isChatThreadIsOpen(notification,
                               userId: viewController.viewModel.contactId,
                               groupId: viewController.viewModel.channelKey)
        {
            viewController.viewModel.prefilledMessage = nil
        }
        viewController.viewModel.contactId = notification.userId
        viewController.viewModel.channelKey = notification.groupId
        var convProxy: ALConversationProxy?
        if let convId = notification.conversationId, let conversationProxy = ALConversationService().getConversationByKey(convId) {
            convProxy = conversationProxy
        }
        viewController.viewModel.conversationProxy = convProxy
        viewController.viewWillLoadFromTappingOnNotification()
        viewController.refreshViewController()
    }

    /// Checks whether Applozic ViewController is at top.
    ///
    /// - WARNING: Doesn't work if Applozic's Controller is added inside some container.
    /// - Returns: Bool value indicating whether Applozic view is at top.
    public func isApplozicVCAtTop() -> Bool {
        guard let topVC = ALPushAssist().topViewController else { return false }
        let topVCName = String(describing: topVC.classForCoder)
        switch topVCName {
        case "MuteConversationViewController",
             "ALKWebViewController",
             "SelectProfilePicViewController",
             "CNContactPickerViewController",
             "CAMImagePickerCameraViewController",
             "UIDocumentPickerViewController":
            return true
        case _ where topVCName.hasPrefix("ALK"):
            return true
        default:
            if let searchVC = topVC as? UISearchController,
               searchVC.searchResultsController as? ALKSearchResultViewController != nil
            {
                return true
            }
            return false
        }
    }

    /// Handles notification tap when any of Applozic's VC is at top.
    ///
    /// - WARNING: Use this only when `isApplozicVCAtTop` returns true.
    /// - Parameter notification: Contains details about arrived notification.
    public func handleNotificationTap(_ notification: NotificationData) {
        guard let topVC = ALPushAssist().topViewController else { return }
        switch topVC {
        case let vc as ALKConversationListViewController:
            print("ConversationListViewController on top")
            openConversationFromListVC(vc, notification: notification)
        case let vc as ALKConversationViewController:
            print("ConversationViewController on top")
            refreshConversation(vc, with: notification)
        default:
            if let searchVC = topVC as? UISearchController,
               let vc = searchVC.presentingViewController as? ALKConversationListViewController
            {
                openConversationFromListVC(vc, notification: notification)
                return
            }
            print("Some other view controller need to find chat vc")
            findChatVC(notification)
        }
    }

    // MARK: - Private helper methods

    private func notificationData(using object: String) -> NotificationData? {
        let components = object.components(separatedBy: ":")
        switch components.count {
        case 3:
            guard let componentElement = Int(components[1]) else { return nil }
            let groupId = NSNumber(integerLiteral: componentElement)
            return NotificationData(userId: nil, groupId: groupId, conversationId: nil)
        case 2:
            guard let conversationComponent = Int(components[1]) else { return nil }
            let conversationId = NSNumber(integerLiteral: conversationComponent)
            let userId = components[0]
            return NotificationData(userId: userId, groupId: nil, conversationId: conversationId)
        case 1:
            let userId = object
            return NotificationData(userId: userId, groupId: nil, conversationId: nil)
        default:
            print("Not handled")
            return nil
        }
    }

    private func findChatVC(_ notification: NotificationData) {
        guard let vc = ALPushAssist().topViewController else { return }
        if vc.navigationController?.viewControllers != nil {
            findControllerInStack(vc) {
                self.handleNotificationTap(notification)
            }
        } else {
            vc.dismiss(animated: true) {
                self.findChatVC(notification)
            }
        }
    }

    private func findControllerInStack(_ vc: UIViewController,
                                       completion: @escaping () -> Void)
    {
        guard !String(describing: vc.classForCoder).hasPrefix("ALKConversation") else {
            completion()
            return
        }
        guard
            vc.navigationController != nil,
            vc.navigationController?.popViewController(animated: true) == nil
        else {
            completion()
            return
        }
        vc.dismiss(animated: true) {
            completion()
        }
    }
}
