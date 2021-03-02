//
//  ALKParticipantSelectionViewContoller.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import UIKit

protocol ALKSelectParticipantToAddProtocol: AnyObject {
    func selectedParticipant(selectedList: [ALKFriendViewModel], addedList: [ALKFriendViewModel])
}

protocol ALKInviteButtonProtocol: AnyObject {
    func getButtonAppearance(invitedFriendCount count: Int) -> (String, backgroundColor: UIColor, isEnabled: Bool)
}

// swiftlint:disable:next type_name
class ALKParticipantSelectionViewContoller: ALKBaseViewController, Localizable {
    // MARK: - UI Stuff

    @IBOutlet private var btnInvite: UIButton!
    @IBOutlet fileprivate var tblParticipants: UITableView!

    fileprivate var tapToDismiss: UITapGestureRecognizer?

    fileprivate let searchController = UISearchController(searchResultsController: nil)

    // MARK: - Data Stuff

    fileprivate var datasource = ALKFriendDatasource()

    fileprivate var existingFriendsInGroupStore = ParticipantStore()
    fileprivate var newFriendsInGroupStore = ParticipantStore()

//    private var friendDataService: FriendDataService?

    // MARK: - Initially Setup

    var friendsInGroup: [GroupMemberInfo]?
    weak var selectParticipantDelegate: ALKSelectParticipantToAddProtocol?

    /*
     var alphabetDict = ["A":[],"B":[],"C":[],"D":[],"E":[],"F":[],"G":[],"H":[],"I":[],"J":[],"K":[],"L":[],"M":[],"N":[],"O":[],"P":[],"Q":[],"R":[],"S":[],"T":[],"U":[],"V":[],"W":[],"X":[],"Y":[],"Z":[],"#":[]]

     var alphabetSection : Array<String> = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","#"]
     */

    lazy var localizedStringFileName: String! = configuration.localizedStringFileName

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        if let textField = searchController.searchBar.textField,
           UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
        {
            textField.textAlignment = .right
        }

        changeNewlyInvitedContact()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchFriendList()
        edgesForExtendedLayout = []
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    // MARK: - UI Setup

    private func setupUI() {
        tblParticipants.accessibilityIdentifier = "SelectParticipantTableView"
        setupInviteButton()
        setupSearchBar()
        navigationItem.title = localizedString(forKey: "AddToGroupTitle", withDefaultValue: SystemMessage.LabelName.AddToGroupTitle, fileName: localizedStringFileName)
        definesPresentationContext = true
        btnInvite.setTitle(localizedString(forKey: "InviteButton", withDefaultValue: SystemMessage.ButtonName.Invite, fileName: localizedStringFileName), for: .normal)
        tblParticipants.tableHeaderView = searchController.searchBar
    }

    private func setupInviteButton() {
        btnInvite.layer.cornerRadius = 15
        btnInvite.clipsToBounds = true
        btnInvite.setFont(font: configuration.channelDetail.button.font)
        btnInvite.setTitleColor(configuration.channelDetail.button.text, for: .normal)
        btnInvite.accessibilityIdentifier = "InviteButton"
    }

    private func setupSearchBar() {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.barTintColor = .white
        searchController.searchBar.applySearchBarStyle()
    }

    // MARK: - Overriden methods

    override func backTapped() {
        let completion = { [weak self] in
            guard let weakSelf = self else { return }
            _ = weakSelf.navigationController?.popViewController(animated: true)
        }
        if newFriendsInGroupStore.hasAtLeastOneMember() {
            let alertInformationDiscardTitle = localizedString(forKey: "DiscardChangeTitle", withDefaultValue: SystemMessage.LabelName.DiscardChangeTitle, fileName: localizedStringFileName)
            let alertInformationDiscardMessage = localizedString(forKey: "DiscardChangeMessage", withDefaultValue: SystemMessage.Warning.DiscardChange, fileName: localizedStringFileName)

            let cancelTitle = localizedString(forKey: "ButtonCancel", withDefaultValue: SystemMessage.ButtonName.Cancel, fileName: localizedStringFileName)
            let discardTitle = localizedString(forKey: "ButtonDiscard", withDefaultValue: SystemMessage.ButtonName.Discard, fileName: localizedStringFileName)

            let alert = UIAlertController.makeCancelDiscardAlert(title: alertInformationDiscardTitle,
                                                                 message: alertInformationDiscardMessage,
                                                                 cancelTitle: cancelTitle,
                                                                 discardTitle: discardTitle,
                                                                 discardAction: {
                                                                     completion()
                                                                 })
            present(alert, animated: true, completion: nil)
        } else {
            completion()
        }
    }

    // MARK: - API Logic

    func fetchFriendList() {
        getAllFriends {
            // Get existing friends in this group
            self.tblParticipants.reloadData()
        }
    }

    func getAllFriends(completion: @escaping () -> Void) {
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
            let dbHandler = ALDBHandler.sharedInstance()

            let fetchReq = NSFetchRequest<DB_CONTACT>(entityName: "DB_CONTACT")

            var predicate = NSPredicate()
            fetchReq.returnsDistinctResults = true
            if !ALUserDefaultsHandler.getLoginUserConatactVisibility() {
                predicate = NSPredicate(format: "userId!=%@ AND deletedAtTime == nil", ALUserDefaultsHandler.getUserId())
            }

            fetchReq.predicate = predicate
            do {
                var models = [ALKFriendViewModel]()

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
                        models.append(ALKFriendViewModel(identity: contact))
                    }
                    datasource.update(datasource: models, state: .full)
                    completion()
                }

            } catch (_) {
                completion()
            }
        }
    }

    func addCategorizeContacts(channel: ALChannel?) {
        guard let alChannel = channel else {
            return
        }

        var models = [ALKFriendViewModel]()
        let contactService = ALContactService()
        let savedLoginUserId = ALUserDefaultsHandler.getUserId() as String

        for memberId in alChannel.membersId {
            if let memberIdStr = memberId as? String, memberIdStr != savedLoginUserId {
                let contact: ALContact? = contactService.loadContact(byKey: "userId", value: memberIdStr)

                if contact?.deletedAtTime == nil {
                    models.append(ALKFriendViewModel(identity: contact!))
                }
            }
        }
        datasource.update(datasource: models, state: .full)
    }

    // MARK: - Handle keyboard

    fileprivate func hideSearchKeyboard() {
        tapToDismiss = UITapGestureRecognizer(target: self, action: #selector(dismissSearchKeyboard))
        view.addGestureRecognizer(tapToDismiss!)
    }

    @objc func dismissSearchKeyboard() {
        if let text = searchController.searchBar.text, text.isEmpty == true {
            searchController.isActive = false
        }
        searchController.searchBar.endEditing(true)
        searchController.dismissKeyboard()
        view.endEditing(true)
    }

    // MARK: - IBAction

    @IBAction func invitePress(_: Any) {
        btnInvite.isEnabled = false
        var selectedFriendList = [ALKFriendViewModel]()
        // get all friends selected into a list
        for fv in datasource.getDatasource(state: .full) {
            if fv.getIsSelected() == true {
                selectedFriendList.append(fv)
            }
        }

        let addedFriendList = getAddedFriend(allFriendsInGroup: selectedFriendList)

        selectParticipantDelegate?.selectedParticipant(selectedList: selectedFriendList, addedList: addedFriendList)
    }

    // MARK: - Other

    private func getNewGroupMemberCount() -> Int {
        return datasource.getDatasource(state: .full).filter { (friendViewModel) -> Bool in
            friendViewModel.getIsSelected() == true && !isInPreviousFriendGroup(fri: friendViewModel)
        }.count
    }

    fileprivate func changeNewlyInvitedContact() {
        let count = getNewGroupMemberCount()

        let (title, background, isEnabled) = getButtonAppearance(invitedFriendCount: count)
        btnInvite.isEnabled = isEnabled
        btnInvite.backgroundColor = background
        btnInvite.setTitle(title, for: .normal)
    }

    private func getAddedFriend(allFriendsInGroup: [ALKFriendViewModel]) -> [ALKFriendViewModel] {
        var addedFriendList = [ALKFriendViewModel]()
        for friend in allFriendsInGroup {
            if !isInPreviousFriendGroup(fri: friend) {
                addedFriendList.append(friend)
            }
        }
        return addedFriendList
    }

    fileprivate func isInPreviousFriendGroup(fri: ALKFriendViewModel) -> Bool {
        guard let friendUUID = fri.friendUUID, let friendsInGroup = self.friendsInGroup else { return false }
        return !friendsInGroup
            .filter { $0.id == friendUUID }
            .isEmpty
    }
}

extension ALKParticipantSelectionViewContoller: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in _: UITableView) -> Int {
        return 1
    }

    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        let state = ALKDatasourceState(isInUsed: searchController.isActiveAndContainText())
        return datasource.count(state: state)

//        let array = alphabetDict[alphabetSection[section]]
//        return (array?.count)!
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ALKFriendContactCell", for: indexPath) as? ALKFriendContactCell {
            let state = ALKDatasourceState(isInUsed: searchController.isActiveAndContainText())

            guard let fri = datasource.getItem(atIndex: indexPath.row, state: state) else {
                return UITableViewCell()
            }

            let isExistingFriendInGroup = isInPreviousFriendGroup(fri: fri)

            cell.update(viewModel: fri, isExistingFriend: isExistingFriendInGroup)

            return cell
        }

        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let state = ALKDatasourceState(isInUsed: searchController.isActiveAndContainText())

        guard let fri = datasource.getItem(atIndex: indexPath.row, state: state) else { return }

        handleTappingContact(friendViewModel: fri)

        datasource.updateItem(item: fri, atIndex: indexPath.row, state: state)

        if !isInPreviousFriendGroup(fri: fri) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                tableView.deselectRow(at: indexPath, animated: true)
                tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.fade)
            }
        }
    }

    private func keepTrackTappingNewlySelectedContact(fri: ALKFriendViewModel) {
        if let friendUUID = fri.friendUUID {
            if !fri.isSelected {
                newFriendsInGroupStore.storeParticipantID(idString: friendUUID)
            } else {
                newFriendsInGroupStore.removeParticipantID(idString: friendUUID)
            }
        }
    }

    private func handleTappingContact(friendViewModel: ALKFriendViewModel) {
        if isInPreviousFriendGroup(fri: friendViewModel) { return }

        keepTrackTappingNewlySelectedContact(fri: friendViewModel)

        friendViewModel.setIsSelected(select: !friendViewModel.isSelected)

        changeNewlyInvitedContact()
    }

    /*
     func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
     return 30
     }

     func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
     let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 30)) //set these values as necessary
     //returnedView.backgroundColor = UIColor(red: 224.0, green: 9.0, blue: 9.0, alpha: 1)

     let label = InsetLabel(frame: CGRect(x: 0, y: 0, width: returnedView.frame.size.width, height: returnedView.frame.size.height))
     label.text = alphabetSection[section]
     label.backgroundColor = UIColor(netHex:0xFBE6E6)
     returnedView.addSubview(label)
     return returnedView
     }

     func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
     return alphabetSection[section]
     }
     */
}

extension ALKParticipantSelectionViewContoller: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }

    func searchBarTextDidBeginEditing(_: UISearchBar) {
        hideSearchKeyboard()
    }

    func searchBarTextDidEndEditing(_: UISearchBar) {
        if let tab = tapToDismiss {
            view.removeGestureRecognizer(tab)
            tapToDismiss = nil
        }
    }

    private func filterContentForSearchText(searchText: String, scope _: String = "All") {
        let filteredList = datasource.getDatasource(state: .full).filter { friendViewModel in
            friendViewModel.getFriendDisplayName().lowercased().contains(searchText.lowercased())
        }
        datasource.update(datasource: filteredList, state: .filtered)
        tblParticipants.reloadData()
    }
}

extension ALKParticipantSelectionViewContoller: ALKInviteButtonProtocol {
    func getButtonAppearance(invitedFriendCount friendCount: Int) -> (String, backgroundColor: UIColor, isEnabled: Bool) {
        let isEnabled = (friendCount > 0) ? true : false
        let background = (isEnabled ? configuration.channelDetail.button.background : UIColor.disabledButton())
        let newMember = friendCount > 0 ? " (\(friendCount))" : ""
        let inviteMessage = localizedString(
            forKey: "InviteMessage",
            withDefaultValue: SystemMessage.LabelName.InviteMessage,
            fileName: localizedStringFileName
        )
        let title = "\(inviteMessage) \(newMember)"
        return (title, background, isEnabled)
    }
}

class ParticipantStore {
    private var participants = [String]()

    func storeParticipantID(idString: String) {
        participants.append(idString)
    }

    func removeParticipantID(idString: String) {
        participants.remove(object: idString)
    }

    func hasAtLeastOneMember() -> Bool {
        return !participants.isEmpty
    }
}

extension UISearchController {
    func isActiveAndContainText() -> Bool {
        return isActive && searchBar.text != ""
    }
}
