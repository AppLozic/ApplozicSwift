//
//  ALMessageArrayWrapper+Extension.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 20/03/19.
//

import ApplozicCore

extension ALMessageArrayWrapper {
    func contains(message: ALMessage) -> Bool {
        guard let messages = messageArray as? [ALMessage] else {
            return false
        }
        return messages.contains(message)
    }
}
