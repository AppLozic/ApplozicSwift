//
//  ALChannelDBService+Extensions.swift
//  ApplozicSwift
//
//  Created by Mukesh on 19/09/19.
//

import ApplozicCore
import Foundation

extension ALChannelDBService {
    func membersInGroup(
        channelKey: NSNumber,
        completion: @escaping ((Set<ALContact>?) -> Void)
    ) {
        fetchChannelMembersAsync(withChannelKey: channelKey) { members in
            guard let members = members as? [String], !members.isEmpty else {
                completion(nil)
                return
            }
            let alContactDbService = ALContactDBService()
            let alContacts = members
                .compactMap { alContactDbService.loadContact(byKey: "userId", value: $0) }
            completion(Set(alContacts))
        }
    }
}
