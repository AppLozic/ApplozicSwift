//
//  ALKBaseViewController.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit
import Applozic

open class ALKBaseViewController: UIViewController, ALKConfigurable {

    var configuration: ALKConfiguration!

    required public init(configuration: ALKConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        NSLog("🐸 \(#function) 🍀🍀 \(self) 🐥🐥🐥🐥")
        self.addObserver()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.barTintColor = UIColor.navigationOceanBlue()
        self.navigationController?.navigationBar.tintColor = UIColor.navigationTextOceanBlue()
        self.navigationController?.navigationBar.isTranslucent = false
        if self.navigationController?.viewControllers.first != self {
            var backImage = UIImage.init(named: "icon_back", in: Bundle.applozic, compatibleWith: nil)
            backImage = backImage?.imageFlippedForRightToLeftLayoutDirection()
            self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: backImage, style: .plain, target: self , action: #selector(backTapped))
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        checkPricingPackage()
    }
    
    @objc func backTapped() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        NSLog("🐸 \(#function) 🍀🍀 \(self) 🐥🐥🐥🐥")
        self.addObserver()
    }
    
    func addObserver() {
        
    }
    
    func removeObserver() {
        
    }
    
    deinit {
        
        removeObserver()
        NSLog("💩 \(#function) ❌❌ \(self)‼️‼️‼️‼️")
    }

    func checkPricingPackage() {
        if ALApplicationInfo().isChatSuspended() {
            showAccountSuspensionView()
        }
    }

    func showAccountSuspensionView() {}
}
