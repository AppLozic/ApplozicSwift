//
//  ALKConversationListViewController.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import ContactsUI
import Foundation
import UIKit

/// The delegate of an `ALKConversationListViewController` object.
/// Provides different methods to manage chat thread selections.
public protocol ALKConversationListDelegate: AnyObject {
    func conversation(
        _ message: ALKChatViewModelProtocol,
        willSelectItemAt index: Int,
        viewController: ALKConversationListViewController
    )
}

open class ALKConversationListViewController: ALKBaseViewController, Localizable {
    public var conversationViewController: ALKConversationViewController?
    public var conversationViewModelType = ALKConversationViewModel.self
    public weak var delegate: ALKConversationListDelegate?
    public var conversationListTableViewController: ALKConversationListTableViewController

    var searchController: UISearchController!
    var searchBar: CustomSearchBar!
    let registerUserClientService = ALRegisterUserClientService()

    lazy var resultVC = ALKSearchResultViewController(configuration: configuration)

    var dbService = ALMessageDBService()
    var viewModel = ALKConversationListViewModel()

    // To check if coming from push notification
    var contactId: String?
    var channelKey: NSNumber?
    var conversationId: NSNumber?

    var tableView: UITableView

    lazy var rightBarButtonItem: UIBarButtonItem = {
        let icon = UIImage(named: "fill_214", in: Bundle.applozic, compatibleWith: nil)
        let barButton = UIBarButtonItem(
            image: icon,
            style: .plain,
            target: self, action: #selector(compose)
        )
        barButton.accessibilityIdentifier = "NewChatButton"
        return barButton
    }()

    fileprivate var tapToDismiss: UITapGestureRecognizer!
    fileprivate var alMqttConversationService: ALMQTTConversationService!
    fileprivate let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    fileprivate var localizedStringFileName: String!

    public required init(configuration: ALKConfiguration) {
        conversationListTableViewController = ALKConversationListTableViewController(
            viewModel: viewModel,
            dbService: dbService,
            configuration: configuration,
            showSearch: false
        )
        tableView = conversationListTableViewController.tableView
        super.init(configuration: configuration)
        conversationListTableViewController.delegate = self
        localizedStringFileName = configuration.localizedStringFileName
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if alMqttConversationService != nil {
            alMqttConversationService.unsubscribeToConversation()
        }
        conversationListTableViewController.remove()
    }

    override open func addObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "newMessageNotification"), object: nil, queue: nil, using: { [weak self] notification in
            guard let weakSelf = self else { return }
            let msgArray = notification.object as? [ALMessage]
            print("new notification received: ", msgArray?.first?.message ?? "")
            guard let list = notification.object as? [Any], !list.isEmpty else { return }
            weakSelf.viewModel.addMessages(messages: list)

        })

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardDidHideNotification,
            object: nil,
            queue: nil,
            using: { [weak self] _ in
                guard let weakSelf = self else { return }

                if weakSelf.navigationController?.visibleViewController as? ALKConversationListViewController != nil, weakSelf.configuration.isMessageSearchEnabled, weakSelf.searchBar.searchBar.text == "" {
                    weakSelf.showNavigationItems()
                }
            }
        )

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "pushNotification"), object: nil, queue: nil, using: { [weak self] notification in
            print("push notification received: ", notification.object ?? "")
            guard let weakSelf = self, let object = notification.object as? String else { return }
            let components = object.components(separatedBy: ":")
            var groupId: NSNumber?
            var contactId: String?
            var conversationId: NSNumber?

            if components.count > 2 {
                let groupComponent = Int(components[1])
                groupId = NSNumber(integerLiteral: groupComponent!)
            } else if components.count == 2 {
                let conversationComponent = Int(components[1])
                conversationId = NSNumber(integerLiteral: conversationComponent!)
                contactId = components[0]
            } else {
                contactId = object
            }

            let message = ALMessage()
            message.contactIds = contactId
            message.groupId = groupId
            let info = notification.userInfo
            let alertValue = info?["alertValue"]
            guard let updateUI = info?["updateUI"] as? Int else { return }
            if updateUI == Int(APP_STATE_ACTIVE.rawValue), weakSelf.isViewLoaded, weakSelf.view.window != nil {
                guard let alert = alertValue as? String else { return }
                let alertComponents = alert.components(separatedBy: ":")
                if alertComponents.count > 1 {
                    message.message = alertComponents[1]
                } else {
                    message.message = alertComponents.first
                }
                weakSelf.viewModel.addMessages(messages: [message])
            } else if updateUI == Int(APP_STATE_INACTIVE.rawValue) {
                // Coming from background

                guard contactId != nil || groupId != nil || conversationId != nil else { return }
                weakSelf.launchChat(contactId: contactId, groupId: groupId, conversationId: conversationId)
            }
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "reloadTable"), object: nil, queue: nil, using: { [weak self] notification in
            NSLog("Reloadtable notification received")

            guard let weakSelf = self, let list = notification.object as? [Any] else { return }
            weakSelf.viewModel.updateMessageList(messages: list)
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "USER_DETAILS_UPDATE_CALL"), object: nil, queue: nil, using: { [weak self] notification in
            NSLog("update user detail notification received")

            guard let weakSelf = self, let userId = notification.object as? String else { return }
            print("update user detail")

            weakSelf.viewModel.updateUserDetail(userId: userId) { success in
                if success {
                    weakSelf.tableView.reloadData()
                }
            }

        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "UPDATE_CHANNEL_NAME"), object: nil, queue: nil, using: { [weak self] _ in
            NSLog("update group name notification received")
            guard let weakSelf = self, weakSelf.view.window != nil else { return }
            print("update group detail")
            weakSelf.tableView.reloadData()
        })
    }

    override open func removeObserver() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "pushNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "newMessageNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "reloadTable"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "USER_DETAILS_UPDATE_CALL"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UPDATE_CHANNEL_NAME"), object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification, object: nil)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        activityIndicator.center = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
        activityIndicator.color = UIColor.gray
        view.addSubview(activityIndicator)
        view.bringSubviewToFront(activityIndicator)
        viewModel.prepareController(dbService: dbService)
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        alMqttConversationService = ALMQTTConversationService.sharedInstance()
        alMqttConversationService.mqttConversationDelegate = self
        alMqttConversationService.subscribeToConversation()
        dbService.delegate = self
        viewModel.delegate = self
        setupSearchController()
        setupView()
        extendedLayoutIncludesOpaqueBars = true
    }

    override open func viewDidAppear(_: Bool) {
        print("contact id: ", contactId as Any)
        if contactId != nil || channelKey != nil || conversationId != nil {
            print("contact id present")
            launchChat(contactId: contactId, groupId: channelKey, conversationId: conversationId)
            contactId = nil
            channelKey = nil
            conversationId = nil
        }
    }

    private func setupView() {
        setupNavigationRightButtons()
        setupBackButton()
        title = localizedString(forKey: "ConversationListVCTitle", withDefaultValue: SystemMessage.ChatList.title, fileName: localizedStringFileName)

        add(conversationListTableViewController)
        conversationListTableViewController.view.frame = view.bounds
        conversationListTableViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        conversationListTableViewController.view.translatesAutoresizingMaskIntoConstraints = true
    }

    func setupBackButton() {
        let back = localizedString(forKey: "Back", withDefaultValue: SystemMessage.ChatList.leftBarBackButton, fileName: localizedStringFileName)
        let leftBarButtonItem = UIBarButtonItem(title: back, style: .plain, target: self, action: #selector(customBackAction))

        if !configuration.hideBackButtonInConversationList {
            navigationItem.leftBarButtonItem = leftBarButtonItem
        }
    }

    func setupNavigationRightButtons() {
        let navigationItems = configuration.navigationItemsForConversationList

        var rightBarButtonItems: [UIBarButtonItem] = []

        if configuration.isMessageSearchEnabled {
            let barButton = UIBarButtonItem(
                image: UIImage(named: "search", in: Bundle.applozic, compatibleWith: nil),
                style: .plain,
                target: self, action: #selector(searchTapped)
            )
            rightBarButtonItems.append(barButton)
        }

        if !configuration.hideStartChatButton {
            rightBarButtonItems.append(rightBarButtonItem)
        }

        for item in navigationItems {
            let uiBarButtonItem = item.barButton(target: self, action: #selector(customButtonEvent(_:)))

            if let barButtonItem = uiBarButtonItem {
                rightBarButtonItems.append(barButtonItem)
            }
        }
        if !rightBarButtonItems.isEmpty {
            let rightButtons = rightBarButtonItems.prefix(3)
            navigationItem.rightBarButtonItems = Array(rightButtons)
        }
    }

    func setupSearchController() {
        searchController = resultVC.setUpSearchViewController()
        searchController.searchBar.delegate = self
        searchBar = CustomSearchBar(searchBar: searchController.searchBar)
        definesPresentationContext = true
    }

    @objc private func searchTapped() {
        navigationItem.rightBarButtonItems = nil
        navigationItem.leftBarButtonItems = nil
        navigationItem.titleView = searchBar

        UIView.animate(
            withDuration: 0.5,
            animations: { self.searchBar.show(true) },
            completion: { _ in self.searchBar.becomeFirstResponder() }
        )
    }

    func launchChat(contactId: String?, groupId: NSNumber?, conversationId: NSNumber? = nil) {
        let conversationViewModel = viewModel.conversationViewModelOf(type: conversationViewModelType, contactId: contactId, channelId: groupId, conversationId: conversationId, localizedStringFileName: localizedStringFileName)

        let viewController: ALKConversationViewController!
        if conversationViewController == nil {
            viewController = ALKConversationViewController(configuration: configuration, individualLaunch: false)
            viewController.viewModel = conversationViewModel
        } else {
            viewController = conversationViewController
            viewController.viewModel.contactId = conversationViewModel.contactId
            viewController.viewModel.channelKey = conversationViewModel.channelKey
            viewController.viewModel.conversationProxy = conversationViewModel.conversationProxy
        }
        viewController.individualLaunch = false
        push(conversationVC: viewController, with: conversationViewModel)
    }

    @objc func compose() {
        let newChatVC = ALKNewChatViewController(configuration: configuration, viewModel: ALKNewChatViewModel(localizedStringFileName: configuration.localizedStringFileName))
        navigationController?.pushViewController(newChatVC, animated: true)
    }

    @objc func customButtonEvent(_ sender: AnyObject) {
        guard let identifier = sender.tag else {
            return
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: ALKNavigationItem.NSNotificationForConversationListNavigationTap), object: self, userInfo: ["identifier": identifier])
    }

    func sync(message: ALMessage) {
        if let viewController = conversationViewController,
           viewController.viewModel != nil,
           viewController.viewModel.contactId == message.contactId,
           viewController.viewModel.channelKey == message.groupId
        {
            print("Contact id matched1")
            viewController.viewModel.addMessagesToList([message])
        }
        viewModel.prepareController(dbService: dbService)
    }

    @objc func customBackAction() {
        guard let nav = navigationController else { return }
        let poppedVC = nav.popViewController(animated: true)
        if poppedVC == nil {
            dismiss(animated: true, completion: nil)
        }
    }

    override open func showAccountSuspensionView() {
        let accountVC = ALKAccountSuspensionController()
        accountVC.closePressed = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
        present(accountVC, animated: true, completion: nil)
        registerUserClientService.syncAccountStatus { response, error in
            guard error == nil, let response = response, response.isRegisteredSuccessfully() else {
                print("Failed to sync the account package status")
                return
            }
            print("Successfuly synced the account package status")
        }
    }

    fileprivate func push(conversationVC: ALKConversationViewController, with viewModel: ALKConversationViewModel) {
        if let topVC = navigationController?.topViewController as? ALKConversationViewController {
            // Update the details and refresh
            topVC.unsubscribingChannel()
            topVC.viewModel.contactId = viewModel.contactId
            topVC.viewModel.channelKey = viewModel.channelKey
            topVC.viewModel.conversationProxy = viewModel.conversationProxy
            topVC.viewWillLoadFromTappingOnNotification()
            topVC.refreshViewController()
        } else {
            // push conversation VC
            conversationVC.viewWillLoadFromTappingOnNotification()
            navigationController?.pushViewController(conversationVC, animated: true)
        }
    }

    func conversationVC() -> ALKConversationViewController? {
        return navigationController?.topViewController as? ALKConversationViewController
    }
}

// MARK: ALMessagesDelegate

extension ALKConversationListViewController: ALMessagesDelegate {
    public func getMessagesArray(_ messagesArray: NSMutableArray!) {
        guard let messages = messagesArray as? [Any] else {
            return
        }
        print("Messages loaded: \(messages)")
        viewModel.updateMessageList(messages: messages)
    }

    public func updateMessageList(_ messagesArray: NSMutableArray!) {
        print("updated message array is: ", messagesArray ?? "empty")
    }
}

extension ALKConversationListViewController: ALKConversationListViewModelDelegate {
    open func startedLoading() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
            self.tableView.isUserInteractionEnabled = false
        }
    }

    open func listUpdated() {
        DispatchQueue.main.async {
            print("Number of rows \(self.tableView.numberOfRows(inSection: 0))")
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
            self.tableView.isUserInteractionEnabled = true
        }
    }

    open func rowUpdatedAt(position: Int) {
        tableView.reloadRows(at: [IndexPath(row: position, section: 0)], with: .automatic)
    }
}

extension ALKConversationListViewController: ALMQTTConversationDelegate {
    open func mqttDidConnected() {
        if let viewController = navigationController?.visibleViewController as? ALKConversationViewController {
            viewController.subscribeChannelToMqtt()
        }
        print("MQTT did connected")
    }

    open func updateUserDetail(_ userId: String!) {
        guard let userId = userId else { return }
        print("update user detail")
        viewModel.updateUserDetail(userId: userId) { updated in
            if updated {
                self.tableView.reloadData()
            }
        }
    }

    func isNewMessageForActiveThread(alMessage: ALMessage, vm: ALKConversationViewModel) -> Bool {
        let isGroupMessage = alMessage.groupId != nil && alMessage.groupId == vm.channelKey
        let isOneToOneMessage = alMessage.groupId == nil && vm.channelKey == nil && alMessage.contactId == vm.contactId
        if isGroupMessage || isOneToOneMessage {
            return true
        }
        return false
    }

    func isMessageSentByLoggedInUser(alMessage: ALMessage) -> Bool {
        if alMessage.isSentMessage() {
            return true
        }
        return false
    }

    open func syncCall(_ alMessage: ALMessage!, andMessageList _: NSMutableArray!) {
        print("sync call: ", alMessage.message ?? "empty")
        guard let message = alMessage else { return }
        let viewController = navigationController?.visibleViewController as? ALKConversationViewController
        if let vm = viewController?.viewModel, vm.contactId != nil || vm.channelKey != nil,
           let visibleController = navigationController?.visibleViewController,
           visibleController.isKind(of: ALKConversationViewController.self),
           isNewMessageForActiveThread(alMessage: alMessage, vm: vm)
        {
            viewModel.syncCall(viewController: viewController, message: message, isChatOpen: true)

        } else if !isMessageSentByLoggedInUser(alMessage: alMessage) {
            guard !configuration.isInAppNotificationBannerDisabled else {
                return
            }
            let notificationView = ALNotificationView(alMessage: message, withAlertMessage: message.message)
            notificationView?.showNativeNotificationWithcompletionHandler {
                _ in
                self.launchChat(contactId: message.contactId, groupId: message.groupId, conversationId: message.conversationId)
            }
        }
        if let visibleController = navigationController?.visibleViewController,
           visibleController.isKind(of: ALKConversationListViewController.self)
        {
            sync(message: alMessage)
        }
    }

    open func delivered(_ messageKey: String!, contactId: String!, withStatus status: Int32) {
        guard let viewController = conversationViewController ?? conversationVC(), viewController.viewModel != nil else {
            return
        }

        viewModel.updateDeliveryReport(convVC: viewController, messageKey: messageKey, contactId: contactId, status: status)
    }

    open func updateStatus(forContact contactId: String!, withStatus status: Int32) {
        guard let viewController = conversationViewController ?? conversationVC(), viewController.viewModel != nil else {
            return
        }

        viewModel.updateStatusReport(convVC: viewController, forContact: contactId, status: status)
    }

    open func updateTypingStatus(_: String!, userId: String!, status: Bool) {
        print("Typing status is", status)

        guard let viewController = conversationViewController ?? conversationVC(), let vm = viewController.viewModel else { return
        }
        guard (vm.contactId != nil && vm.contactId == userId) || vm.channelKey != nil else {
            return
        }
        print("Contact id matched")
        viewModel.updateTypingStatus(in: viewController, userId: userId, status: status)
    }

    open func reloadData(forUserBlockNotification userId: String!, andBlockFlag _: Bool) {
        print("reload data")
        let userDetail = ALUserDetail()
        userDetail.userId = userId
        viewModel.updateStatusFor(userDetail: userDetail)
        guard let viewController = navigationController?.visibleViewController as? ALKConversationViewController else {
            return
        }
        viewController.checkUserBlock()
    }

    open func updateLastSeen(atStatus alUserDetail: ALUserDetail!) {
        print("Last seen updated")
        viewModel.updateStatusFor(userDetail: alUserDetail)
        guard let viewController = navigationController?.visibleViewController as? ALKConversationViewController else {
            return
        }
        viewController.updateLastSeen(atStatus: alUserDetail)
    }

    open func mqttConnectionClosed() {
        print("ALKConversationListVC mqtt connection closed.")
        alMqttConversationService.retryConnection()
    }
}

extension ALKConversationListViewController: ALKConversationListTableViewDelegate {
    public func tapped(_ chat: ALKChatViewModelProtocol, at index: Int) {
        delegate?.conversation(
            chat,
            willSelectItemAt: index,
            viewController: self
        )
        let convViewModel = conversationViewModelType.init(contactId: chat.contactId, channelKey: chat.channelKey, localizedStringFileName: configuration.localizedStringFileName)
        let convService = ALConversationService()
        if let convId = chat.conversationId, let convProxy = convService.getConversationByKey(convId) {
            convViewModel.conversationProxy = convProxy
        }
        let viewController = conversationViewController ?? ALKConversationViewController(configuration: configuration, individualLaunch: false)
        viewController.viewModel = convViewModel
        viewController.individualLaunch = false
        navigationController?.pushViewController(viewController, animated: true)
    }

    public func emptyChatCellTapped() {
        compose()
    }

    public func scrolledToBottom() {
        viewModel.fetchMoreMessages(dbService: dbService)
    }

    public func userBlockNotification(userId: String, isBlocked: Bool) {
        viewModel.userBlockNotification(userId: userId, isBlocked: isBlocked)
    }

    public func muteNotification(conversation: ALMessage, isMuted: Bool) {
        viewModel.muteNotification(conversation: conversation, isMuted: isMuted)
    }

    func showNavigationItems() {
        searchBar.show(false)
        searchBar.resignFirstResponder()
        navigationItem.titleView = nil
        setupBackButton()
        setupNavigationRightButtons()
    }
}

extension ALKConversationListViewController: UISearchBarDelegate {
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchKey = searchBar.text, !searchKey.isEmpty else {
            return
        }
        resultVC.search(key: searchKey)
    }

    public func searchBar(_: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            resultVC.clearAndReload()
        }
    }

    public func searchBarCancelButtonClicked(_: UISearchBar) {
        showNavigationItems()
        resultVC.clear()
    }
}
