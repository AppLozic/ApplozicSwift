//
//  PushNotificationHandler.swift
//  ApplozicSwiftDemo
//
//  Created by Shivam Pokhriyal on 19/03/19.
//  Copyright © 2019 Applozic. All rights reserved.
//

import ApplozicCore
import ApplozicSwift
import Foundation

/* Handle following cases for notification ::
 /* 1. Detailed chat screen is on top.
  And chat was happening for the user for whom notification came.
  So, Don't show notification.
  */
 /* 2. Detailed chat screen is on top.
  And chat was happening with different user/group.
  Here, refresh chat screen to show chat with the user for whom notification came.
  */
 /* 3. Chat list screen is on top.
  Open detailed chat with the user/group.
  */
 /* 4. Any other screen is on top.
  Push chat list screen and then push detailed chat.
  Or you can directly push chat list while setting contactId/groupId
  and it will open detailed chat automatically.
  */
 */

class PushNotificationHandler {
    public static let shared = PushNotificationHandler()
    var configuration: ALKConfiguration!

    public func handleNotification(with configuration: ALKConfiguration) {
        self.configuration = configuration

        // No need to add removeObserver() as it is present in pushAssist.
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "showNotificationAndLaunchChat"), object: nil, queue: nil, using: { [weak self] notification in
            print("launch chat push notification received")
            let (notifData, msg) = NotificationHelper().notificationInfo(notification)

            guard
                let weakSelf = self,
                let notificationData = notifData,
                let message = msg
            else { return }

            /// If app is active then show notification and handle click.
            /// If app is inactive, then iOS notification will be shown, you only need to handle click.
            if UIApplication.shared.applicationState == .active {
                /// Before showing notification check if it is for active conversation.
                /// You can also check if notification came for muted or blocked conversation
                /// using NotificationData and show notification accordingly.
                /// - Note: This might not work if you added `ALKConversationViewController`
                ///         inside container. If thats the case then handle accordingly.
                guard !NotificationHelper().isNotificationForActiveThread(notificationData) else { return }
                /// Here you can use any view to display notification.
                /// Make sure on click of notification you call `launchIndividualChatWith` method
                ALUtilityClass.thirdDisplayNotificationTS(
                    message,
                    andForContactId: notificationData.userId,
                    withGroupId: notificationData.groupId,
                    completionHandler: {
                        _ in
                        weakSelf.launchIndividualChatWith(notificationData: notificationData)
                    }
                )
            } else {
                weakSelf.launchIndividualChatWith(notificationData: notificationData)
            }

        })
    }

    func launchIndividualChatWith(notificationData: NotificationHelper.NotificationData) {
        print("Called when user taps on notification.")

        /// This will give false if our viewControllers are being added as child views.
        if NotificationHelper().isApplozicVCAtTop() {
            NotificationHelper().handleNotificationTap(notificationData)
        } else {
            print("Applozic Controller not on top. Launch chat using helper methods.")
            handleNotificationWhenApplozicNotOnTop(notificationData)
        }
    }

    private func handleNotificationWhenApplozicNotOnTop(_ notificationData: NotificationHelper.NotificationData) {
        let pushAssistant = ALPushAssist()
        guard let topVC = pushAssistant.topViewController else { return }
        /// Below code needs to be changed depending on how you are using SDK.
        /// Currently it shows how it can be used with container view controllers.
        switch topVC {
        case let vc as ConversationContainerViewController:
            /// This is the container view in which list is added.
            /// If this is at top, then pass the instance of list in this helper method
            /// and the helper will launch the detail chat.
            NotificationHelper().openConversationFromListVC(vc.conversationVC, notification: notificationData)
        case let vc as ContainerViewController:
            /// This is the main container view for app.
            /// It indicates that chat view is not visible.
            /// Here call below helper method to get an instance of list VC which will open detail chat.
            let listVC = NotificationHelper().getConversationVCToLaunch(notification: notificationData, configuration: configuration)
            /// Navigate to the controller where list is added and use this instance there.
            vc.openConversationFromNotification(listVC)

        /// In below 2 cases some other view controller is open.
        /// Do same as above : Use helper method to get instance of listVC which will
        /// open detail chat. And navigate to the controller where list is addded
        /// In that controller use the instance returned by helper method.
        case let vc as MenuViewController:
            vc.dismiss(animated: true) {
                guard let top = pushAssistant.topViewController as? ContainerViewController else {
                    return
                }
                let listVC = NotificationHelper().getConversationVCToLaunch(notification: notificationData, configuration: AppDelegate.config)
                top.openConversationFromNotification(listVC)
            }
        case let vc as ViewController:
            let container = ContainerViewController()
            let nav = ALKBaseNavigationViewController(rootViewController: container)
            vc.present(nav, animated: true) {
                let listVC = NotificationHelper().getConversationVCToLaunch(notification: notificationData, configuration: self.configuration)
                /// Navigate to the controller where list is added and use this instance there.
                container.openConversationFromNotification(listVC)
            }
        default:
            print("Some other controller Handle It!")
        }
    }
}
