//
//  AppDelegate.swift
//  ApplozicSwiftDemo
//
//  Created by Mukesh Thawani on 11/08/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import ApplozicSwift
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var window: UIWindow?

    static let config: ALKConfiguration = {
        var config = ALKConfiguration()
        // Change config based on requirement like:
        // config.isTapOnNavigationBarEnabled = false
        return config
    }()

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BuddyBuildSDK.setup()

        let navigationBarProxy = UINavigationBar.appearance(whenContainedInInstancesOf: [ALKBaseNavigationViewController.self])
        navigationBarProxy.barTintColor
            = UIColor(red: 0.93, green: 0.94, blue: 0.95, alpha: 1.0) // light nav blue
        navigationBarProxy.isTranslucent = false

        /// Use this for Customizing notification.
        /// - NOTE:
        ///       Before using, comment ALKPushNotification line and remove
        ///       ALApplozicSetting.setListOfViewController from ALChatManager.
        ///       If you want to try this in our sample, then comment lines in ViewController's launchChatList method.
        ///       Finally, Uncomment below line
        /// PushNotificationHandler.shared.handleNotification(with: AppDelegate.config)
        ALKPushNotificationHandler.shared.dataConnectionNotificationHandlerWith(AppDelegate.config)
        let alApplocalNotificationHnadler = ALAppLocalNotifications.appLocalNotificationHandler()
        alApplocalNotificationHnadler?.dataConnectionNotificationHandler()

        if ALUserDefaultsHandler.isLoggedIn() {
            // Get login screen from storyboard and present it
            let viewController: UIViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ViewController") as UIViewController
            window?.makeKeyAndVisible()
            viewController.modalPresentationStyle = .fullScreen
            window?.rootViewController!.present(viewController, animated: true, completion: nil)
        }

        UNUserNotificationCenter.current().delegate = self
        registerForNotification()
        return true
    }

    func applicationWillResignActive(_: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_: UIApplication) {
        print("APP_ENTER_IN_BACKGROUND")
    }

    func applicationWillEnterForeground(_: UIApplication) {
        print("APP_ENTER_IN_FOREGROUND")
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationDidBecomeActive(_: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_: UIApplication) {
        ALDBHandler.sharedInstance().saveContext()
    }

    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("DEVICE_TOKEN_DATA :: \(deviceToken.description)") // (SWIFT = 3) : TOKEN PARSING

        var deviceTokenString: String = ""
        for i in 0 ..< deviceToken.count {
            deviceTokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        print("DEVICE_TOKEN_STRING :: \(deviceTokenString)")

        if ALUserDefaultsHandler.getApnDeviceToken() != deviceTokenString {
            let alRegisterUserClientService = ALRegisterUserClientService()
            alRegisterUserClientService.updateApnDeviceToken(withCompletion: deviceTokenString, withCompletion: { response, _ in
                print("REGISTRATION_RESPONSE :: \(String(describing: response))")
            })
        }
    }

    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Couldn’t register: \(error)")
    }

    func registerForNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in
        }
        UIApplication.shared.registerForRemoteNotifications()
    }

    func userNotificationCenter(_: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let service = ALPushNotificationService()
        guard !service.isApplozicNotification(notification.request.content.userInfo) else {
            service.notificationArrived(to: UIApplication.shared, with: notification.request.content.userInfo)
            completionHandler([])
            return
        }
        completionHandler([])
    }

    func userNotificationCenter(_: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let service = ALPushNotificationService()
        let dict = response.notification.request.content.userInfo
        guard !service.isApplozicNotification(dict) else {
            switch UIApplication.shared.applicationState {
            case .active:
                service.processPushNotification(dict, updateUI: NSNumber(value: APP_STATE_ACTIVE.rawValue))
            case .background:
                service.processPushNotification(dict, updateUI: NSNumber(value: APP_STATE_BACKGROUND.rawValue))
            case .inactive:
                service.processPushNotification(dict, updateUI: NSNumber(value: APP_STATE_INACTIVE.rawValue))
            @unknown default:
                print("Unknown application state in appdelegate")
            }
            completionHandler()
            return
        }
        completionHandler()
    }
}
