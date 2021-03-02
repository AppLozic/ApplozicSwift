//
//  ALMessageDBService+Extension.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 13/05/19.
//

import ApplozicCore

extension ALMessageDBService {
    func updateDbMessageWith(key: String, value: String, filePath: String) {
        let alHandler = ALDBHandler.sharedInstance()
        guard let dbMessage = getMessageByKey(key, value: value) as? DB_Message else {
            print("Can't find message with key \(key) and value \(value)")
            return
        }
        dbMessage.filePath = filePath
        let error = alHandler?.saveContext()
        if error != nil {
            print("Not saved due to error \(String(describing: error))")
        }
    }
}
