//
//  ALMessageDBServiceMock.swift
//  ApplozicSwiftDemoTests
//
//  Created by Mukesh Thawani on 25/09/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation

class ALMessageDBServiceMock: ALMessageDBService {
    static var lastMessage: ALMessage! = MockMessage().message

    override func getMessages(_: NSMutableArray!) {
        delegate.getMessagesArray([ALMessageDBServiceMock.lastMessage as Any])
    }
}
