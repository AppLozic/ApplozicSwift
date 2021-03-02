//
//  ViewController.swift
//  ApplozicSwiftDemo
//
//  Created by Mukesh Thawani on 11/08/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import ApplozicSwift
import UIKit

class ViewController: UIViewController {
    override func viewDidAppear(_: Bool) {
        //        registerAndLaunch()
    }

    override func viewDidLoad() {}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func logoutAction(_: UIButton) {
        guard let applicationKey = ALUserDefaultsHandler.getApplicationKey() else {
            return
        }
        let chatManager = ALChatManager(applicationKey: applicationKey as NSString)
        chatManager.logoutUser { _ in
            self.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func launchChatList(_: Any) {
        let conversationVC = ALKConversationListViewController(configuration: AppDelegate.config)
        let nav = ALKBaseNavigationViewController(rootViewController: conversationVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
//        Use this to check sample for custom push notif. Comment above lines.
//        let vc = ContainerViewController()
//        let nav = ALKBaseNavigationViewController(rootViewController: vc)
//        self.present(nav, animated: false, completion: nil)
    }
}
