//
//  CreateGroupViewModel.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation

protocol ALKCreateGroupViewModelDelegate: AnyObject {
    func membersFetched()
    func remove(at index: Int)
    func makeAdmin(at index: Int)
    func dismissAdmin(at index: Int)
    func sendMessage(at index: Int)
    func info(at index: Int)
}

enum Options: String, Localizable {
    case remove
    case makeAdmin
    case dismissAdmin
    case sendMessage
    case info
    case cancel

    func value(
        localizationFileName: String,
        index: Int,
        delegate: ALKCreateGroupViewModelDelegate
    ) -> UIAlertAction {
        switch self {
        case .remove:
            let title = localizedString(forKey: "RemoveUser", withDefaultValue: SystemMessage.GroupDetails.RemoveUser, fileName: localizationFileName)
            return UIAlertAction(title: title, style: .destructive, handler: { _ in
                delegate.remove(at: index)
            })
        case .makeAdmin:
            let title = localizedString(forKey: "MakeAdmin", withDefaultValue: SystemMessage.GroupDetails.MakeAdmin, fileName: localizationFileName)
            return UIAlertAction(title: title, style: .default, handler: { _ in
                delegate.makeAdmin(at: index)
            })
        case .dismissAdmin:
            let title = localizedString(forKey: "DismissAdmin", withDefaultValue: SystemMessage.GroupDetails.DismissAdmin, fileName: localizationFileName)
            return UIAlertAction(title: title, style: .default, handler: { _ in
                delegate.dismissAdmin(at: index)
            })
        case .sendMessage:
            let title = localizedString(forKey: "SendMessage", withDefaultValue: SystemMessage.GroupDetails.SendMessage, fileName: localizationFileName)
            return UIAlertAction(title: title, style: .default, handler: { _ in
                delegate.sendMessage(at: index)
            })
        case .info:
            let title = localizedString(forKey: "Info", withDefaultValue: SystemMessage.GroupDetails.Info, fileName: localizationFileName)
            return UIAlertAction(title: title, style: .default, handler: { _ in
                delegate.info(at: index)
            })
        case .cancel:
            let title = localizedString(forKey: "Cancel", withDefaultValue: SystemMessage.LabelName.Cancel, fileName: localizationFileName)
            return UIAlertAction(title: title, style: .cancel)
        }
    }
}

class ALKCreateGroupViewModel: Localizable {
    var groupName: String = ""
    var originalGroupName: String = ""
    var groupId: NSNumber
    lazy var adminText: String = localizedString(forKey: "Admin", withDefaultValue: SystemMessage.LabelName.Admin, fileName: localizationFileName)

    var membersInfo = [GroupMemberInfo]()

    weak var delegate: ALKCreateGroupViewModelDelegate?

    lazy var isAddAllowed: Bool = {
        guard let channel = ALChannelDBService().loadChannel(byKey: groupId) else {
            return true /// Allow adding participants while creating group.
        }
        return channel.type == PUBLIC.rawValue || isAdmin(userId: ALUserDefaultsHandler.getUserId())
    }()

    let localizationFileName: String
    let shouldShowInfoOption: Bool

    init(
        groupName name: String,
        groupId: NSNumber,
        delegate: ALKCreateGroupViewModelDelegate,
        localizationFileName: String,
        shouldShowInfoOption: Bool = false
    ) {
        groupName = name
        originalGroupName = name
        self.groupId = groupId
        self.delegate = delegate
        self.localizationFileName = localizationFileName
        self.shouldShowInfoOption = shouldShowInfoOption
    }

    func isAddParticipantButtonEnabled() -> Bool {
        let name = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !name.isEmpty
    }

    func fetchParticipants() {
        ALChannelDBService().fetchChannelMembersAsync(withChannelKey: groupId) { members in
            guard let members = members as? [String], !members.isEmpty else {
                return
            }
            let alContactDbService = ALContactDBService()
            let alContacts = members.map {
                alContactDbService.loadContact(byKey: "userId", value: $0)
            }

            self.membersInfo =
                alContacts
                    .filter { $0 != nil && $0?.userId != ALUserDefaultsHandler.getUserId() }
                    .map {
                        let user = $0!
                        return GroupMemberInfo(
                            id: user.userId ?? "",
                            name: user.getDisplayName() ?? "",
                            image: user.contactImageUrl,
                            isAdmin: self.isAdmin(userId: user.userId!),
                            addCell: false,
                            adminText: self.adminText
                        )
                    }
            self.membersInfo.insert(self.getCurrentUserInfo(), at: 0)
            DispatchQueue.main.async {
                self.delegate?.membersFetched()
            }
        }
    }

    func numberOfRows() -> Int {
        return membersInfo.count
    }

    func rowAt(index: Int) -> GroupMemberInfo {
        return membersInfo[index]
    }

    func removeAt(index: Int) {
        membersInfo.remove(at: index)
    }

    func updateRoleAt(index: Int) {
        var member = membersInfo[index]
        member.isAdmin = isAdmin(userId: member.id)
        membersInfo[index] = member
    }

    func optionsForCell(at index: Int) -> [Options]? {
        /// Pressed on 'You'
        if index == 0 {
            return nil
        }
        /// Pressed on user
        var options: [Options] = shouldShowInfoOption ? [.info, .sendMessage] : [.sendMessage]

        if isAdmin(userId: ALUserDefaultsHandler.getUserId()) {
            membersInfo[index].isAdmin ? options.append(.dismissAdmin) : options.append(.makeAdmin)
            options.append(.remove)
            options.append(.cancel)
            return options
        }
        options.append(.cancel)
        return options
    }

    private func isAdmin(userId: String) -> Bool {
        return ALChannelDBService()
            .loadChannelUserX(
                byUserId: groupId,
                andUserId: userId
            )?.isAdminUser() ?? false
    }

    private func getCurrentUserInfo() -> GroupMemberInfo {
        let currentUser = ALContactDBService().loadContact(byKey: "userId", value: ALUserDefaultsHandler.getUserId())!
        let name = localizedString(forKey: "You", withDefaultValue: SystemMessage.LabelName.You, fileName: localizationFileName)
        return GroupMemberInfo(
            id: currentUser.userId,
            name: name,
            image: currentUser.contactImageUrl,
            isAdmin: isAdmin(userId: ALUserDefaultsHandler.getUserId()),
            addCell: false,
            adminText: adminText
        )
    }
}
