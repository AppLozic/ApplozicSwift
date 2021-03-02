//
//  ALContactServiceMock.swift
//  ApplozicSwiftDemoTests
//
//  Created by Shivam Pokhriyal on 24/10/18.
//  Copyright © 2018 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation

class ALContactServiceMock: ALContactService {
    override func loadContact(byKey _: String!, value _: String!) -> ALContact! {
        let contact = ALContact()
        contact.displayName = "demoDisplayName"
        return contact
    }
}
