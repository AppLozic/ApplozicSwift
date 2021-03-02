//
//  ALPushNotificationHandler.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation

public class ALKPushNotificationHandler: Localizable {
    public static let shared = ALKPushNotificationHandler()
    var configuration: ALKConfiguration!

    public func dataConnectionNotificationHandlerWith(_ configuration: ALKConfiguration) {
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

            guard let userInfo = notification.userInfo as? [String: Any], let state = userInfo["updateUI"] as? NSNumber else { return }

            switch state {
            case NSNumber(value: APP_STATE_ACTIVE.rawValue):
                guard !NotificationHelper().isNotificationForActiveThread(notificationData) else { return }
                // TODO: FIX HERE. USE conversationId also.
                guard !configuration.isInAppNotificationBannerDisabled else { return }
                ALUtilityClass.thirdDisplayNotificationTS(
                    message,
                    andForContactId: notificationData.userId,
                    withGroupId: notificationData.groupId,
                    completionHandler: {
                        _ in
                        weakSelf.launchIndividualChatWith(notificationData: notificationData)
                    }
                )
            default:
                weakSelf.launchIndividualChatWith(notificationData: notificationData)
            }
        })
    }

    func launchIndividualChatWith(notificationData: NotificationHelper.NotificationData) {
        guard !NotificationHelper().isApplozicVCAtTop() else {
            NotificationHelper().handleNotificationTap(notificationData)
            return
        }
        let topVC = ALPushAssist().topViewController
        let listVC = NotificationHelper().getConversationVCToLaunch(notification: notificationData, configuration: configuration)
        let nav = ALKBaseNavigationViewController(rootViewController: listVC)
        nav.modalTransitionStyle = .crossDissolve
        nav.modalPresentationStyle = .fullScreen
        topVC?.present(nav, animated: true, completion: nil)
    }
}
