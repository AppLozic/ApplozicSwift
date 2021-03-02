//
//  ALKNewChatViewModel.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation

public final class ALKNewChatViewModel {
    private var localizedStringFileName: String!

    var friendList = [ALKContactProtocol]() // For UI presentation
    var bufferFriendList = [ALKContactProtocol]() {
        didSet {
            friendList = bufferFriendList
        }
    }

    var applozicSettings: ALApplozicSettings.Type = ALApplozicSettings.self

    // MARK: - Intialization

    public init(localizedStringFileName: String) {
        self.localizedStringFileName = localizedStringFileName
    }

    // MARK: Internal

    func filter(keyword: String) {
        if keyword.isEmpty {
            friendList = bufferFriendList
        } else {
            friendList = bufferFriendList.filter { ($0.friendProfileName != nil) ? $0.friendProfileName!.lowercased().contains(keyword.lowercased()) : false }
        }
    }

    func getContacts(userService: ALUserService = ALUserService(), completion: @escaping () -> Void) {
        if ALApplozicSettings.isContactsGroupEnabled() {
            ALChannelService.getMembersFromContactGroupOfType(ALApplozicSettings.getContactsGroupId(), withGroupType: 9) { _, channel in

                guard let alChannel = channel else {
                    completion()
                    return
                }
                self.addCategorizeContacts(channel: alChannel)
                completion()
            }

        } else {
            if applozicSettings.getFilterContactsStatus() {
                userService.getListOfRegisteredUsers(completion: { _ in
                    self.bufferFriendList = self.fetchContactsFromDB() ?? []
                    completion()
                })
            } else {
                bufferFriendList = fetchContactsFromDB() ?? []
                completion()
            }
        }
    }

    func addCategorizeContacts(channel: ALChannel?) {
        guard let alChannel = channel else {
            return
        }

        var friendList = [ALKContactProtocol]()
        let contactService = ALContactService()
        let savedLoginUserId = ALUserDefaultsHandler.getUserId() as String

        for memberId in alChannel.membersId {
            if let memberIdStr = memberId as? String, memberIdStr != savedLoginUserId {
                let contact: ALContact? = contactService.loadContact(byKey: "userId", value: memberIdStr)

                if contact?.deletedAtTime == nil {
                    friendList.append(contact!)
                }
            }
        }

        bufferFriendList = friendList
    }

    func fetchContactsFromDB() -> [ALKContactProtocol]? {
        let dbHandler = ALDBHandler.sharedInstance()
        let fetchReq = NSFetchRequest<DB_CONTACT>(entityName: "DB_CONTACT")
        var predicate = NSPredicate()
        fetchReq.returnsDistinctResults = true

        if !ALUserDefaultsHandler.getLoginUserConatactVisibility() {
            predicate = NSPredicate(format: "userId!=%@ AND deletedAtTime == nil", ALUserDefaultsHandler.getUserId() ?? "")
        }
        fetchReq.predicate = predicate
        var contactList = [ALKContactProtocol]()
        do {
            if let fetchedContacts = try dbHandler?.execute(fetchReq as? NSFetchRequest<NSFetchRequestResult>) as? [DB_CONTACT] {
                for dbContact in fetchedContacts {
                    let contact = ALContact()
                    contact.userId = dbContact.userId
                    contact.fullName = dbContact.fullName
                    contact.contactNumber = dbContact.contactNumber
                    contact.displayName = dbContact.displayName
                    contact.contactImageUrl = dbContact.contactImageUrl
                    contact.email = dbContact.email
                    contact.localImageResourceName = dbContact.localImageResourceName
                    contact.contactType = dbContact.contactType
                    contactList.append(contact)
                }
                return contactList
            }
        } catch {
            NSLog(error.localizedDescription)
            return nil
        }
        return nil
    }

    func numberOfSection() -> Int {
        return 2
    }

    func numberOfRowsInSection(section _: Int) -> Int {
        return friendList.count
    }

    func friendForRow(indexPath: IndexPath) -> ALKContactProtocol {
        return friendList[indexPath.row]
    }

    // Internal class
    final class CreateGroup: ALKContactProtocol, Localizable {
        var localizedStringFileName: String!

        lazy var friendProfileName: String? = {
            let text = localizedString(forKey: "CreateGroupTitle", withDefaultValue: SystemMessage.NavbarTitle.createGroupTitle, fileName: localizedStringFileName)
            return text
        }()

        var friendUUID: String? = ""
        var friendMood: String? = ""
        var friendDisplayImgURL: URL?

        init(localizedStringFileName: String) {
            self.localizedStringFileName = localizedStringFileName
        }
    }

    func createGroupCell() -> ALKContactProtocol {
        return CreateGroup(localizedStringFileName: localizedStringFileName)
    }
}
