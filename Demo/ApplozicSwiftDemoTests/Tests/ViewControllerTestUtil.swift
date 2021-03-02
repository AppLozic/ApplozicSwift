//
//  ViewControllerTestUtil.swift
//  ApplozicSwiftDemoTests
//
//  Created by Mukesh on 25/12/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import UIKit
import XCTest

class ViewControllerTestUtil<T: UIViewController> {
    private var rootWindow: UIWindow!

    func setupTopLevelUI(withViewController viewController: T) {
        rootWindow = UIWindow(frame: UIScreen.main.bounds)
        rootWindow.isHidden = false
        rootWindow.rootViewController = viewController
        _ = viewController.view
        viewController.viewWillAppear(false)
        viewController.viewDidAppear(false)
    }

    func tearDownTopLevelUI() {
        guard let rootWindow = rootWindow,
              let rootViewController = rootWindow.rootViewController as? T
        else {
            XCTFail("tearDownTopLevelUI() was called without setupTopLevelUI() being called first")
            return
        }
        rootViewController.viewWillDisappear(false)
        rootViewController.viewDidDisappear(false)
        rootWindow.rootViewController = nil
        rootWindow.isHidden = true
        self.rootWindow = nil
    }
}
