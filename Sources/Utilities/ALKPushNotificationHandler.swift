//
//  ALPushNotificationHandler.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import Applozic

@objc public class ALKPushNotificationHandler: NSObject {
    public static let shared = ALKPushNotificationHandler()
    var navVC: UINavigationController?

    var contactId: String?
    var groupId: NSNumber?
    var title: String = ""


    private var alContact: ALContact? {
        let alContactDbService = ALContactDBService()
        guard let alContact = alContactDbService.loadContact(byKey: "userId", value: self.contactId) else {
            return nil
        }
        return alContact
    }

    private var alChannel: ALChannel? {
        let alChannelService = ALChannelService()

        // TODO:  This is a workaround as other method uses closure.
        // Later replace this with:
        // alChannelService.getChannelInformation(, orClientChannelKey: , withCompletion: )
        guard let alChannel = alChannelService.getChannelByKey(self.groupId) else {
            return nil
        }
        return alChannel
    }


    @objc public func dataConnectionNotificationHandler() {

        // No need to add removeObserver() as it is present in pushAssist.
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "showNotificationAndLaunchChat"), object: nil, queue: nil, using: {[weak self] notification in
            print("launch chat push notification received")

            //Todo: Handle group

            guard let weakSelf = self, let object = notification.object as? String else { return }
            let components = object.components(separatedBy: ":")
            if components.count > 1 {
                guard let componentElement = Int(components[1]) else { return }
                let id = NSNumber(integerLiteral: componentElement)
                weakSelf.groupId = id
                guard let alChannel = weakSelf.alChannel, let name = alChannel.name else { return }
                weakSelf.title = name

            } else {
                weakSelf.contactId = object
                guard let alContact = weakSelf.alContact else { return }
                let displayName = alContact.getDisplayName() ?? "No name"
                weakSelf.title = displayName
            }

            if UIApplication.shared.applicationState == .active {
                guard let userInfo = notification.userInfo, let alertValue = userInfo["alertValue"] as? String else {
                        return
                }
                ALUtilityClass.thirdDisplayNotificationTS(alertValue, andForContactId: weakSelf.contactId, withGroupId: weakSelf.groupId, completionHandler: {

                    _ in
                    weakSelf.notificationTapped(userId: weakSelf.contactId, groupId: weakSelf.groupId)

                })
            } else {
                weakSelf.launchIndividualChatWith(userId: weakSelf.contactId, groupId: weakSelf.groupId)
            }

        })
    }

    func launchIndividualChatWith(userId: String?, groupId: NSNumber?) {
        NSLog("Called via notification and user id is: ", userId ?? "Not Present")

        let conversationVC = ALKConversationListViewController()
        conversationVC.title = "Conversation"
        conversationVC.tabBarItem = UITabBarItem.init(tabBarSystemItem: UITabBarSystemItem.more, tag: 0)
        let convNav = UINavigationController(rootViewController: conversationVC)
        
        let contactsVC = ALKContactListViewController()
        contactsVC.title = "Contacts"
        contactsVC.tabBarItem = UITabBarItem.init(tabBarSystemItem: .contacts, tag: 1)
        let contNav = UINavigationController(rootViewController: contactsVC)
        
        let controllers = [conversationVC, contactsVC]
        let tabBarController = UITabBarController()
        tabBarController.viewControllers = controllers.map { UINavigationController(rootViewController: $0) }
        tabBarController.tabBar.backgroundColor = UIColor.white
        
        let pushAssist = ALPushAssist()
        UIApplication.shared.keyWindow?.rootViewController = pushAssist.topViewController
        UIApplication.shared.keyWindow?.makeKeyAndVisible()
        
        pushAssist.topViewController.present(tabBarController, animated: true, completion: nil)
        
        conversationVC.launchChat(contactId: userId, groupId: groupId)
        
//        let messagesVC = ALKConversationListViewController()
//        messagesVC.contactId = userId
//        messagesVC.channelKey = groupId
//        let rootVC =  UIApplication.shared.keyWindow?.rootViewController?.presentedViewController
//        let nav = ALKBaseNavigationViewController(rootViewController: messagesVC)
//        navVC?.modalTransitionStyle = .crossDissolve
//        rootVC?.present(nav, animated: true, completion: nil)

    }

    func notificationTapped(userId: String?, groupId: NSNumber?) {
        launchIndividualChatWith(userId: userId, groupId: groupId)
    }

}
