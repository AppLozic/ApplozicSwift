//
//  ALKConversationListViewControllerMock.swift
//  ApplozicSwiftDemoTests
//
//  Created by Mukesh on 31/12/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation
@testable import ApplozicSwift

class ALKConversationListViewControllerMock: ALKConversationListViewController, Muteable {
    var isMuteCalled: Bool = false
    var onDeinitialized: (() -> Void)?

    required init(configuration: ALKConfiguration) {
        super.init(configuration: configuration)
    }

    deinit {
        onDeinitialized?()
    }

    func mute(conversation _: ALMessage, forTime _: Int64, atIndexPath _: IndexPath) {
        isMuteCalled = true
    }
}
