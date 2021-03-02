//
//  ALKBaseViewController.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import UIKit

open class ALKBaseViewController: UIViewController, ALKConfigurable {
    public var configuration: ALKConfiguration!

    public required init(configuration: ALKConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
        addObserver()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        NSLog("🐸 \(#function) 🍀🍀 \(self) 🐥🐥🐥🐥")
        addObserver()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if navigationController?.viewControllers.first != self {
            var backImage = UIImage(named: "icon_back", in: Bundle.applozic, compatibleWith: nil)
            backImage = backImage?.imageFlippedForRightToLeftLayoutDirection()
            let backButton = UIBarButtonItem(
                image: backImage,
                style: .plain,
                target: self,
                action: #selector(backTapped)
            )
            backButton.accessibilityIdentifier = "conversationBackButton"
            navigationItem.leftBarButtonItem = backButton
        }

        if configuration.hideNavigationBarBottomLine {
            navigationController?.navigationBar.hideBottomHairline()
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        checkPricingPackage()
    }

    @objc func backTapped() {
        _ = navigationController?.popViewController(animated: true)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSLog("🐸 \(#function) 🍀🍀 \(self) 🐥🐥🐥🐥")
        addObserver()
    }

    open func addObserver() {}

    open func removeObserver() {}

    deinit {
        removeObserver()
        NSLog("💩 \(#function) ❌❌ \(self)‼️‼️‼️‼️")
    }

    func checkPricingPackage() {
        if ALApplicationInfo().isChatSuspended() {
            showAccountSuspensionView()
        }
    }

    open func showAccountSuspensionView() {}
}
