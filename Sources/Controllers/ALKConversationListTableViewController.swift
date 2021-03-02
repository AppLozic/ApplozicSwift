//
//  ConversationListTableViewController.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 29/11/18.
//

import ApplozicCore
import Foundation

/**
 A delegate used to notify the receiver of the click events in `ConversationListTableViewController`
 */
public protocol ALKConversationListTableViewDelegate: AnyObject {
    /// Tells the delegate which chat cell is tapped alongwith the position.
    func tapped(_ chat: ALKChatViewModelProtocol, at index: Int)

    /// Tells the delegate empty list cell is tapped.
    func emptyChatCellTapped()

    /// Tells the delegate that the tableview is scrolled to bottom.
    func scrolledToBottom()

    func muteNotification(conversation: ALMessage, isMuted: Bool)

    func userBlockNotification(userId: String, isBlocked: Bool)
}

/**
 The **ConversationListTableViewController** manages rendering of chat cells using the viewModel supplied to it. It also contains delegate to send callbacks when a cell is tapped.

 It uses ALKChatCell and EmptyChatCell as tableview cell and handles the swipe interaction of user with the chat cell.
 */
// swiftlint:disable:next type_name
public class ALKConversationListTableViewController: UITableViewController, Localizable {
    // MARK: - PUBLIC PROPERTIES

    public var viewModel: ALKConversationListViewModelProtocol
    public var dbService: ALMessageDBService!
    public var hideNoConversationView = false
    public lazy var dataSource = ConversationListTableViewDataSource(
        viewModel: self.viewModel,
        cellConfigurator: { message, tableCell in
            let cell = tableCell as! ALKChatCell
            cell.update(viewModel: message, identity: nil, disableSwipe: self.configuration.disableSwipeInChatCell)
            cell.chatCellDelegate = self
        }
    )
    public weak var delegate: ALKConversationListTableViewDelegate?

    // MARK: - PRIVATE PROPERTIES

    fileprivate var configuration: ALKConfiguration
    fileprivate var showSearch: Bool
    fileprivate var localizedStringFileName: String
    fileprivate var tapToDismiss: UITapGestureRecognizer!
    fileprivate let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    fileprivate var searchActive: Bool = false
    fileprivate var searchFilteredChat: [Any] = []
    fileprivate lazy var searchBar: UISearchBar = {
        var bar = UISearchBar()
        bar.autocapitalizationType = .sentences
        return bar
    }()

    /**
     Creates a ConversationListTableViewController object.

     - Parameters:
     - viewModel: A view model containing the message list to be rendered. It must conform to `ConversationListViewModelProtocol`
     - dbService: `ALMessageDBService` object. Ensure that this object confirms to `ALMessageDBDelegate`
     - configuration: A configuration to be used by this controller to configure different settings.
     - delegate: A delegate used to receive callbacks when chat cell is tapped.
     */
    public init(viewModel: ALKConversationListViewModelProtocol,
                dbService: ALMessageDBService,
                configuration: ALKConfiguration,
                showSearch: Bool)
    {
        self.viewModel = viewModel
        self.configuration = configuration
        self.showSearch = showSearch
        localizedStringFileName = configuration.localizedStringFileName
        self.dbService = dbService
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// This method is used to replace current viewModel with a new one and then refresh the tableView.
    /// - Parameter viewModel: The new viewModel that needs to be updated in tableView
    public func replaceViewModel(_ viewModel: ALKConversationListViewModelProtocol) {
        self.viewModel = viewModel
        dataSource.viewModel = viewModel
        tableView.reloadData()
    }

    // MARK: - VIEW LIFE CYCLE

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ALKChatCell.self, forCellReuseIdentifier: "cell")
        tableView.register(
            ALKEmptyView.nib,
            forHeaderFooterViewReuseIdentifier:
            ALKEmptyView.reuseIdentifier
        )
        tableView.estimatedRowHeight = 0
    }

    override public func viewWillDisappear(_: Bool) {
        if let text = searchBar.text, !text.isEmpty {
            searchBar.text = ""
        }
        searchBar.endEditing(true)
        searchActive = false
        tableView.reloadData()
    }

    // MARK: - TABLE VIEW DATA SOURCE METHODS

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.numberOfSections(in: tableView)
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchActive {
            return searchFilteredChat.count
        }
        return dataSource.tableView(tableView, numberOfRowsInSection: section)
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchActive {
            guard let chat = searchFilteredChat[indexPath.row] as? ALMessage else {
                return UITableViewCell()
            }
            let cell: ALKChatCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ALKChatCell
            cell.update(viewModel: chat, identity: nil, disableSwipe: configuration.disableSwipeInChatCell)
            cell.chatCellDelegate = self
            return cell
        }
        return dataSource.tableView(tableView, cellForRowAt: indexPath)
    }

    override public func tableView(_: UITableView, canEditRowAt _: IndexPath) -> Bool {
        return true
    }

    // MARK: - TABLE VIEW DELEGATE METHODS

    override public func tableView(_: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchActive {
            guard let message = searchFilteredChat[indexPath.row] as? ALMessage else {
                return
            }
            delegate?.tapped(message, at: indexPath.row)
        } else {
            guard let message = viewModel.chatFor(indexPath: indexPath) else {
                return
            }
            delegate?.tapped(message, at: indexPath.row)
        }
    }

    override public func tableView(_: UITableView, viewForHeaderInSection _: Int) -> UIView? {
        return searchBar
    }

    override public func tableView(_: UITableView, heightForHeaderInSection _: Int) -> CGFloat {
        return showSearch ? 50 : 0
    }

    override public func tableView(_: UITableView, viewForFooterInSection _: Int) -> UIView? {
        guard !hideNoConversationView,
              let emptyCellView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ALKEmptyView.reuseIdentifier) as? ALKEmptyView
        else {
            return nil
        }
        let noConversationLabelText = localizedString(forKey: "NoConversationsLabelText", withDefaultValue: SystemMessage.ChatList.NoConversationsLabelText, fileName: localizedStringFileName)
        emptyCellView.conversationLabel.text = noConversationLabelText
        emptyCellView.startNewConversationButtonIcon.isHidden = configuration.hideEmptyStateStartNewButtonInConversationList
        emptyCellView.contentView.backgroundColor = .white

        if !configuration.hideEmptyStateStartNewButtonInConversationList {
            if let tap = emptyCellView.gestureRecognizers?.first {
                emptyCellView.removeGestureRecognizer(tap)
            }

            let tap = UITapGestureRecognizer(target: self, action: #selector(compose))
            tap.numberOfTapsRequired = 1

            emptyCellView.addGestureRecognizer(tap)
        }

        return emptyCellView
    }

    override public func tableView(_: UITableView, heightForFooterInSection _: Int) -> CGFloat {
        guard !hideNoConversationView else {
            return 0
        }
        return viewModel.numberOfRowsInSection(0) == 0 ? 325 : 0
    }

    // MARK: - HANDLE KEYBOARD

    override func hideKeyboard() {
        tapToDismiss = UITapGestureRecognizer(
            target: self,
            action: #selector(UIViewController.dismissKeyboard)
        )
        view.addGestureRecognizer(tapToDismiss)
    }

    override func dismissKeyboard() {
        searchBar.endEditing(true)
        view.endEditing(true)
    }

    @objc func compose() {
        delegate?.emptyChatCellTapped()
    }

    // MARK: - PRIVATE METHODS

    private func setupView() {
        tableView.estimatedRowHeight = 75
        tableView.rowHeight = 75
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.white
        tableView.keyboardDismissMode = .onDrag
        tableView.accessibilityIdentifier = "OuterChatScreenTableView"

        activityIndicator.center = CGPoint(x: view.bounds.size.width / 2,
                                           y: view.bounds.size.height / 2)
        activityIndicator.color = UIColor.gray
        view.addSubview(activityIndicator)
        view.bringSubviewToFront(activityIndicator)
    }
}

// MARK: - SEARCH BAR DELEGATE

extension ALKConversationListTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func filterContentForSearchText(searchText: String, scope _: String = "All") {
        searchFilteredChat = viewModel.getChatList().filter { (chatViewModel) -> Bool in
            guard let conversation = chatViewModel as? ALMessage else {
                return false
            }
            if conversation.isGroupChat {
                return conversation.groupName.lowercased().isCompose(of: searchText.lowercased())
            } else {
                let conversationName = !conversation.name.isEmpty ?
                    conversation.name : localizedString(
                        forKey: "NoNameMessage",
                        withDefaultValue: SystemMessage.NoData.NoName,
                        fileName: localizedStringFileName
                    )
                return conversationName.lowercased().isCompose(of: searchText.lowercased())
            }
        }
        tableView.reloadData()
    }

    public func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }

    public func searchBar(_: UISearchBar, textDidChange searchText: String) {
        searchFilteredChat = viewModel.getChatList().filter { (chatViewModel) -> Bool in
            guard let conversation = chatViewModel as? ALMessage else {
                return false
            }
            if conversation.isGroupChat {
                return conversation.groupName.lowercased().isCompose(of: searchText.lowercased())
            } else {
                let conversationName = !conversation.name.isEmpty ? conversation.name : localizedString(
                    forKey: "NoNameMessage",
                    withDefaultValue: SystemMessage.NoData.NoName,
                    fileName: localizedStringFileName
                )
                return conversationName.lowercased().isCompose(of: searchText.lowercased())
            }
        }
        searchActive = !searchText.isEmpty
        tableView.reloadData()
    }

    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        hideKeyboard()

        if (searchBar.text?.isEmpty)! {
            tableView.reloadData()
        }
    }

    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        view.removeGestureRecognizer(tapToDismiss)

        guard let text = searchBar.text else { return }

        if text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            if searchActive {
                searchActive = false
            }
            tableView.reloadData()
        }
    }

    public func searchBarCancelButtonClicked(_: UISearchBar) {
        searchActive = false
        tableView.reloadData()
    }

    public func searchBarSearchButtonClicked(_: UISearchBar) {
        tableView.reloadData()
    }
}

// MARK: - ALKChatCell DELEGATE

extension ALKConversationListTableViewController: ALKChatCellDelegate {
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public func chatCell(cell: ALKChatCell, action: ALKChatCellAction, viewModel _: ALKChatViewModelProtocol) {
        switch action {
        case .delete:

            guard let indexPath = tableView.indexPath(for: cell) else { return }

            if searchActive {
                guard let conversation = searchFilteredChat[indexPath.row] as? ALMessage else { return }

                let (prefixText, buttonTitle) = prefixAndButtonTitleForDeletePopup(conversation: conversation)
                let conversationName = !conversation.name.isEmpty ?
                    conversation.name : localizedString(
                        forKey: "NoNameMessage",
                        withDefaultValue: SystemMessage.NoData.NoName,
                        fileName: localizedStringFileName
                    )
                let name = conversation.isGroupChat ? conversation.groupName : conversationName
                let text = "\(prefixText) \(name)?"
                let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)

                let cancelButton = UIAlertAction(
                    title: localizedString(
                        forKey: "ButtonCancel",
                        withDefaultValue: SystemMessage.ButtonName.Cancel,
                        fileName: localizedStringFileName
                    ),
                    style: .cancel,
                    handler: nil
                )
                let deleteButton = UIAlertAction(title: buttonTitle, style: .destructive, handler: { [weak self] _ in
                    guard let weakSelf = self, ALDataNetworkConnection.checkDataNetworkAvailable() else { return }
                    self?.startLoadingIndicator()
                    if conversation.isGroupChat {
                        let channelService = ALChannelService()
                        if channelService.isChannelLeft(conversation.groupId) {
                            ALMessageService.deleteMessageThread(nil, orChannelKey: conversation.groupId, withCompletion: {
                                _, error in
                                self?.stopLoadingIndicator()
                                guard error == nil else { return }
                                ALChannelService.setUnreadCountZeroForGroupID(conversation.groupId)
                                weakSelf.viewModel.remove(message: conversation)
                                weakSelf.tableView.reloadData()
                                return
                            })
                        } else if ALChannelService.isChannelDeleted(conversation.groupId) {
                            let channelDbService = ALChannelDBService()
                            channelDbService.deleteChannel(conversation.groupId)
                            weakSelf.searchFilteredChat.remove(at: indexPath.row)
                            weakSelf.viewModel.remove(message: conversation)
                            weakSelf.tableView.reloadData()
                        } else {
                            channelService.leaveChannel(conversation.groupId, andUserId: ALUserDefaultsHandler.getUserId(), orClientChannelKey: nil, withCompletion: {
                                error in
                                self?.stopLoadingIndicator()
                                guard error == nil else {
                                    print("Failed to leave the channel : \(String(describing: conversation.groupId))")
                                    return
                                }
                                weakSelf.tableView.reloadData()
                            })
                        }
                    } else {
                        ALMessageService.deleteMessageThread(conversation.contactIds, orChannelKey: nil, withCompletion: {
                            _, error in
                            self?.stopLoadingIndicator()
                            guard error == nil else { return }
                            weakSelf.viewModel.remove(message: conversation)
                            weakSelf.tableView.reloadData()
                        })
                    }
                })
                alert.addAction(cancelButton)
                alert.addAction(deleteButton)
                present(alert, animated: true, completion: nil)
            } else if viewModel.chatFor(indexPath: indexPath) != nil, let conversation = viewModel.getChatList()[indexPath.row] as? ALMessage {
                let (prefixText, buttonTitle) = prefixAndButtonTitleForDeletePopup(conversation: conversation)

                let name = conversation.isGroupChat ? conversation.groupName : conversation.name
                let text = "\(prefixText) \(name)?"
                let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
                let cancelButton = UIAlertAction(
                    title: localizedString(
                        forKey: "ButtonCancel",
                        withDefaultValue: SystemMessage.ButtonName.Cancel,
                        fileName: localizedStringFileName
                    ),
                    style: .cancel,
                    handler: nil
                )
                let deleteButton = UIAlertAction(title: buttonTitle, style: .destructive, handler: { [weak self] _ in
                    guard let weakSelf = self else { return }
                    self?.startLoadingIndicator()
                    if conversation.isGroupChat {
                        let channelService = ALChannelService()
                        if channelService.isChannelLeft(conversation.groupId) {
                            ALMessageService.deleteMessageThread(nil, orChannelKey: conversation.groupId, withCompletion: {
                                _, error in
                                self?.stopLoadingIndicator()
                                guard error == nil else { return }
                                ALChannelService.setUnreadCountZeroForGroupID(conversation.groupId)
                                weakSelf.viewModel.remove(message: conversation)
                                weakSelf.tableView.reloadData()
                                return
                            })
                        } else if ALChannelService.isChannelDeleted(conversation.groupId) {
                            let channelDbService = ALChannelDBService()
                            channelDbService.deleteChannel(conversation.groupId)
                            weakSelf.viewModel.remove(message: conversation)
                            weakSelf.tableView.reloadData()
                        } else {
                            channelService.leaveChannel(conversation.groupId, andUserId: ALUserDefaultsHandler.getUserId(), orClientChannelKey: nil, withCompletion: {
                                error in
                                self?.stopLoadingIndicator()
                                guard error == nil else {
                                    print("Failed to leave the channel : \(String(describing: conversation.groupId))")
                                    return
                                }
                                weakSelf.tableView.reloadData()
                            })
                        }
                    } else {
                        ALMessageService.deleteMessageThread(conversation.contactIds, orChannelKey: nil, withCompletion: {
                            _, error in
                            self?.stopLoadingIndicator()
                            guard error == nil else { return }
                            weakSelf.viewModel.remove(message: conversation)
                            weakSelf.tableView.reloadData()
                        })
                    }
                })
                alert.addAction(cancelButton)
                alert.addAction(deleteButton)
                present(alert, animated: true, completion: nil)
            }

        case .mute:
            guard let indexPath = tableView.indexPath(for: cell) else {
                return
            }

            if searchActive {
                guard let conversation = searchFilteredChat[indexPath.row] as? ALMessage else {
                    return
                }
                handleMuteActionFor(conversation: conversation, atIndexPath: indexPath)
            } else if viewModel.chatFor(indexPath: indexPath) != nil, let conversation = viewModel.getChatList()[indexPath.row] as? ALMessage {
                handleMuteActionFor(conversation: conversation, atIndexPath: indexPath)
            }

        case .unmute:
            guard let indexPath = tableView.indexPath(for: cell) else {
                return
            }
            if searchActive {
                guard let conversation = searchFilteredChat[indexPath.row] as? ALMessage else {
                    return
                }
                handleUnmuteActionFor(conversation: conversation, atIndexPath: indexPath)
            } else if viewModel.chatFor(indexPath: indexPath) != nil, let conversation = viewModel.getChatList()[indexPath.row] as? ALMessage {
                handleUnmuteActionFor(conversation: conversation, atIndexPath: indexPath)
            }
        case .block:
            guard
                let indexPath = tableView.indexPath(for: cell),
                let conversation = messageFor(indexPath: indexPath),
                let contact = ALContactService().loadContact(byKey: "userId", value: conversation.contactIds)
            else {
                return
            }
            let alertFormat = localizedString(forKey: "BlockUser", withDefaultValue: SystemMessage.Block.BlockUser, fileName: localizedStringFileName)
            let alertMessage = String(format: alertFormat, contact.getDisplayName())
            let blockTitle = localizedString(forKey: "BlockTitle", withDefaultValue: SystemMessage.Block.BlockTitle, fileName: localizedStringFileName)
            let cancelTitle = localizedString(forKey: "Cancel", withDefaultValue: SystemMessage.LabelName.Cancel, fileName: localizedStringFileName)

            let alert = UIAlertController(title: nil, message: alertMessage, preferredStyle: .alert)
            let cancelButton = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
            let blockButton = UIAlertAction(title: blockTitle, style: .destructive, handler: { [weak self] _ in
                guard let weakSelf = self else { return }
                weakSelf.blockUser(in: conversation, at: indexPath)
            })
            alert.addAction(cancelButton)
            alert.addAction(blockButton)
            present(alert, animated: true, completion: nil)

        case .unblock:
            guard
                let indexPath = tableView.indexPath(for: cell),
                let conversation = messageFor(indexPath: indexPath),
                let contact = ALContactService().loadContact(byKey: "userId", value: conversation.contactIds)
            else {
                return
            }
            let alertFormat = localizedString(forKey: "UnblockUser", withDefaultValue: SystemMessage.Block.UnblockUser, fileName: localizedStringFileName)
            let alertMessage = String(format: alertFormat, contact.getDisplayName())
            let blockTitle = localizedString(forKey: "UnblockTitle", withDefaultValue: SystemMessage.Block.UnblockTitle, fileName: localizedStringFileName)
            let cancelTitle = localizedString(forKey: "Cancel", withDefaultValue: SystemMessage.LabelName.Cancel, fileName: localizedStringFileName)

            let alert = UIAlertController(title: nil, message: alertMessage, preferredStyle: .alert)
            let cancelButton = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
            let unblockButton = UIAlertAction(title: blockTitle, style: .destructive, handler: { [weak self] _ in
                guard let weakSelf = self else { return }
                weakSelf.unblockUser(in: conversation, at: indexPath)
            })
            alert.addAction(cancelButton)
            alert.addAction(unblockButton)
            present(alert, animated: true, completion: nil)

        default:
            print("not present")
        }
    }

    private func startLoadingIndicator() {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
    }

    private func stopLoadingIndicator() {
        activityIndicator.stopAnimating()
        view.isUserInteractionEnabled = true
    }

    private func confirmationAlert(with message: String) {
        let okTitle = localizedString(forKey: "OkMessage", withDefaultValue: SystemMessage.Block.OkMessage, fileName: localizedStringFileName)
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okButton = UIAlertAction(title: okTitle, style: .default, handler: nil)
        alert.addAction(okButton)
        present(alert, animated: true, completion: nil)
    }

    private func unblockUser(in conversation: ALMessage, at indexPath: IndexPath) {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        viewModel.unblock(conversation: conversation) { _, response in
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
            guard response == true else {
                let errorMessage = self.localizedString(forKey: "ErrorMessage", withDefaultValue: SystemMessage.Block.ErrorMessage, fileName: self.localizedStringFileName)
                self.confirmationAlert(with: errorMessage)
                return
            }
            self.delegate?.userBlockNotification(userId: conversation.contactIds, isBlocked: false)
            let successMessage = self.localizedString(forKey: "UnblockSuccess", withDefaultValue: SystemMessage.Block.UnblockSuccess, fileName: self.localizedStringFileName)
            self.confirmationAlert(with: successMessage)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    private func blockUser(in conversation: ALMessage, at indexPath: IndexPath) {
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        viewModel.block(conversation: conversation) { _, response in
            self.activityIndicator.stopAnimating()
            self.view.isUserInteractionEnabled = true
            guard response == true else {
                let errorMessage = self.localizedString(forKey: "ErrorMessage", withDefaultValue: SystemMessage.Block.ErrorMessage, fileName: self.localizedStringFileName)
                self.confirmationAlert(with: errorMessage)
                return
            }
            self.delegate?.userBlockNotification(userId: conversation.contactIds, isBlocked: true)
            let successMessage = self.localizedString(forKey: "BlockSuccess", withDefaultValue: SystemMessage.Block.BlockSuccess, fileName: self.localizedStringFileName)
            self.confirmationAlert(with: successMessage)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
    }

    private func messageFor(indexPath: IndexPath) -> ALMessage? {
        if searchActive {
            guard let conversation = searchFilteredChat[indexPath.row] as? ALMessage else {
                return nil
            }
            return conversation
        } else {
            guard let conversation = viewModel.getChatList()[indexPath.row] as? ALMessage else {
                return nil
            }
            return conversation
        }
    }

    private func prefixAndButtonTitleForDeletePopup(conversation: ALMessage) -> (String, String) {
        let deleteGroupPopupMessage = localizedString(
            forKey: "DeleteGroupConversation",
            withDefaultValue: SystemMessage.Warning.DeleteGroupConversation,
            fileName: localizedStringFileName
        )
        let leaveGroupPopupMessage = localizedString(
            forKey: "LeaveGroupConversation",
            withDefaultValue: SystemMessage.Warning.LeaveGroupConoversation,
            fileName: localizedStringFileName
        )
        let deleteSingleConversationPopupMessage = localizedString(
            forKey: "DeleteSingleConversation",
            withDefaultValue: SystemMessage.Warning.DeleteSingleConversation,
            fileName: localizedStringFileName
        )
        let removeButtonText = localizedString(
            forKey: "ButtonRemove",
            withDefaultValue: SystemMessage.ButtonName.Remove,
            fileName: localizedStringFileName
        )
        let leaveButtonText = localizedString(
            forKey: "ButtonLeave",
            withDefaultValue: SystemMessage.ButtonName.Leave,
            fileName: localizedStringFileName
        )

        let isChannelLeft = ALChannelService().isChannelLeft(conversation.groupId)

        let popupMessageForChannel = isChannelLeft ? deleteGroupPopupMessage : leaveGroupPopupMessage
        let prefixTextForPopupMessage = conversation.isGroupChat ?
            popupMessageForChannel : deleteSingleConversationPopupMessage
        let buttonTitleForChannel = isChannelLeft ? removeButtonText : leaveButtonText
        let buttonTitleForPopupMessage = conversation.isGroupChat ?
            buttonTitleForChannel : removeButtonText

        return (prefixTextForPopupMessage, buttonTitleForPopupMessage)
    }

    private func alertMessageAndButtonTitleToUnmute(conversation: ALMessage) -> (String?, String?) {
        let unmuteButton = localizedString(
            forKey: "UnmuteButton",
            withDefaultValue: SystemMessage.Mute.UnmuteButton,
            fileName: localizedStringFileName
        )

        if conversation.isGroupChat, let channel = ALChannelService().getChannelByKey(conversation.groupId) {
            let unmuteChannelFormat = localizedString(
                forKey: "UnmuteChannel",
                withDefaultValue: SystemMessage.Mute.UnmuteChannel,
                fileName: localizedStringFileName
            )
            let unmuteChannelMessage = String(format: unmuteChannelFormat, channel.name)
            return (unmuteChannelMessage, unmuteButton)
        } else if let contact = ALContactService().loadContact(byKey: "userId", value: conversation.contactId) {
            let unmuteUserFormat = localizedString(
                forKey: "UnmuteUser",
                withDefaultValue: SystemMessage.Mute.UnmuteUser,
                fileName: localizedStringFileName
            )
            let unmuteUserMessage = String(format: unmuteUserFormat, contact.getDisplayName())
            return (unmuteUserMessage, unmuteButton)
        } else {
            return (nil, nil)
        }
    }

    private func sendUnmuteRequestFor(conversation: ALMessage, atIndexPath: IndexPath) {
        // Start activity indicator
        activityIndicator.startAnimating()

        viewModel.sendUnmuteRequestFor(message: conversation, withCompletion: { [weak self] success in
            guard let weakSelf = self else { return }
            // Stop activity indicator
            weakSelf.activityIndicator.stopAnimating()

            guard success == true else {
                return
            }

            weakSelf.delegate?.muteNotification(conversation: conversation, isMuted: false)
            if weakSelf.tableView.isValid(indexPath: atIndexPath) {
                weakSelf.tableView.reloadRows(at: [atIndexPath], with: .none)
            }
        })
    }

    private func handleUnmuteActionFor(conversation: ALMessage, atIndexPath: IndexPath) {
        let (message, buttonTitle) = alertMessageAndButtonTitleToUnmute(conversation: conversation)
        guard message != nil, buttonTitle != nil else {
            return
        }

        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelButtonText = localizedString(forKey: "ButtonCancel", withDefaultValue: SystemMessage.ButtonName.Cancel, fileName: configuration.localizedStringFileName)
        let cancelButton = UIAlertAction(title: cancelButtonText, style: .cancel, handler: nil)

        let unmuteButton = UIAlertAction(title: buttonTitle, style: .destructive, handler: { [weak self] _ in
            guard let weakSelf = self else { return }
            weakSelf.sendUnmuteRequestFor(conversation: conversation, atIndexPath: atIndexPath)
        })
        alert.addAction(cancelButton)
        alert.addAction(unmuteButton)
        present(alert, animated: true, completion: nil)
    }

    private func popupTitleToMute(conversation: ALMessage) -> String? {
        if conversation.isGroupChat, let channel = ALChannelService().getChannelByKey(conversation.groupId) {
            let muteChannelFormat = localizedString(forKey: "MuteChannel", withDefaultValue: SystemMessage.Mute.MuteChannel, fileName: localizedStringFileName)
            return String(format: muteChannelFormat, channel.name)
        } else if let contact = ALContactService().loadContact(byKey: "userId", value: conversation.contactId) {
            let muteUserFormat = localizedString(forKey: "MuteUser", withDefaultValue: SystemMessage.Mute.MuteUser, fileName: localizedStringFileName)
            return String(format: muteUserFormat, contact.getDisplayName())
        } else {
            return nil
        }
    }

    private func handleMuteActionFor(conversation: ALMessage, atIndexPath: IndexPath) {
        guard let title = popupTitleToMute(conversation: conversation) else {
            return
        }
        let muteConversationVC = MuteConversationViewController(delegate: self, conversation: conversation, atIndexPath: atIndexPath, configuration: configuration)
        muteConversationVC.updateTitle(title)
        muteConversationVC.modalPresentationStyle = .overCurrentContext
        present(muteConversationVC, animated: true, completion: nil)
    }
}

// MARK: - MUTE DELEGATE

extension ALKConversationListTableViewController: Muteable {
    @objc func mute(conversation: ALMessage, forTime: Int64, atIndexPath: IndexPath) {
        // Start activity indicator
        activityIndicator.startAnimating()

        let time = (Int64(Date().timeIntervalSince1970) * 1000) + forTime

        viewModel.sendMuteRequestFor(message: conversation, tillTime: NSNumber(value: time)) { [weak self] success in
            guard let weakSelf = self else { return }
            // Stop activity indicator
            weakSelf.activityIndicator.stopAnimating()

            // Update indexPath
            guard success == true else {
                return
            }

            weakSelf.delegate?.muteNotification(conversation: conversation, isMuted: true)
            if weakSelf.tableView.isValid(indexPath: atIndexPath) {
                weakSelf.tableView.reloadRows(at: [atIndexPath], with: .none)
            }
        }
    }
}

// MARK: - SCROLL VIEW DELEGATE

public extension ALKConversationListTableViewController {
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let reloadDistance: CGFloat = 40.0 // Added this so that loading starts 40 points before the end
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset - reloadDistance
        if distanceFromBottom < height {
            delegate?.scrolledToBottom()
        }
    }
}
