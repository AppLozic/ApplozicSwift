//
//  ALBaseNavigationController.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

public class ALKBaseNavigationViewController: UINavigationController {
    static var statusBarStyle: UIStatusBarStyle = .lightContent

    public override func viewDidLoad() {
        super.viewDidLoad()

        setNeedsStatusBarAppearanceUpdate()
        setupAppearance()
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return ALKBaseNavigationViewController.statusBarStyle
    }

    private func setupAppearance() {
        let navigationBarProxy = UINavigationBar.appearance(whenContainedInInstancesOf: [ALKBaseNavigationViewController.self])
        navigationBarProxy.tintColor = navigationBarProxy.tintColor ?? UIColor.navigationTextOceanBlue()
        navigationBarProxy.titleTextAttributes =
            navigationBarProxy.titleTextAttributes ?? [NSAttributedString.Key.foregroundColor: UIColor.black]

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = navigationBarProxy.barTintColor
            appearance.titleTextAttributes = navigationBarProxy.titleTextAttributes ?? [:]
            navigationBarProxy.scrollEdgeAppearance = appearance
            navigationBarProxy.compactAppearance = appearance
            navigationBarProxy.standardAppearance = appearance
        }
    }
}
