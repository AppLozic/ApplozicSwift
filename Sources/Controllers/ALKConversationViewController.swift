//  ConversationViewController.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import AVFoundation
import AVKit
import ContactsUI
import MobileCoreServices
import SafariServices
import UIKit

// swiftlint:disable:next type_body_length
open class ALKConversationViewController: ALKBaseViewController, Localizable {
    var timerTask = Timer()

    public var viewModel: ALKConversationViewModel! {
        willSet(updatedVM) {
            guard viewModel != nil else { return }
            if updatedVM.contactId == viewModel.contactId,
               updatedVM.channelKey == viewModel.channelKey,
               updatedVM.conversationProxy == viewModel.conversationProxy
            {
                isFirstTime = false
            } else {
                isFirstTime = true
            }
        }
    }

    /// Make this false if you want to use custom list view controller
    public var individualLaunch = true

    public lazy var chatBar = ALKChatBar(frame: CGRect.zero, configuration: self.configuration)
    public lazy var autocompleteManager: AutoCompleteManager = {
        let manager = AutoCompleteManager(
            textView: chatBar.textView,
            tableview: autocompletionView
        )
        manager.autocompletionDelegate = self
        return manager
    }()

    public let autocompletionView: UITableView = {
        let tableview = UITableView(frame: CGRect.zero, style: .plain)
        tableview.backgroundColor = .white
        tableview.estimatedRowHeight = 50
        tableview.rowHeight = UITableView.automaticDimension
        tableview.separatorStyle = .none
        tableview.contentInset = UIEdgeInsets(top: 0, left: -5, bottom: 0, right: 0)
        return tableview
    }()

    open lazy var navigationBar = ALKConversationNavBar(configuration: self.configuration, delegate: self)

    var contactService: ALContactService!
    let registerUserClientService = ALRegisterUserClientService()

    var loadingIndicator = ALKLoadingIndicator(frame: .zero)

    /// See configuration.
    var isGroupDetailActionEnabled = true

    /// Check if view is loaded from notification
    private var isViewLoadedFromTappingOnNotification: Bool = false

    /// See configuration.
    private var isProfileTapActionEnabled = true

    private var isFirstTime = true
    private var bottomConstraint: NSLayoutConstraint?
    private var leftMoreBarConstraint: NSLayoutConstraint?
    private var typingNoticeViewHeighConstaint: NSLayoutConstraint?
    var isJustSent: Bool = false

    // MQTT connection retry
    fileprivate var mqttRetryCount = 0
    fileprivate let maxMqttRetryCount = 3

    fileprivate var audioPlayer = ALKAudioPlayer()

    fileprivate let moreBar = ALKMoreBar(frame: .zero)
    fileprivate lazy var typingNoticeView = TypingNotice(localizedStringFileName: configuration.localizedStringFileName)
    fileprivate var alMqttConversationService: ALMQTTConversationService!
    fileprivate let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)

    fileprivate var keyboardSize: CGRect?

    fileprivate var localizedStringFileName: String!
    fileprivate var profanityFilter: ProfanityFilter?
    var activeTextField: UITextField?
    var documentManager = ALKDocumentManager()
    lazy var photoPicker = ALKPhotoPicker(
        localizationFileName: localizedStringFileName,
        selectionLimit: configuration.chatBar.photosSelectionLimit
    )

    fileprivate enum ActionType: String {
        case link
        case quickReply = "quick_reply"
    }

    fileprivate enum CardTemplateActionType: String {
        case link
        case submit
        case quickReply
    }

    fileprivate enum ConstraintIdentifier {
        static let contextTitleView = "contextTitleView"
        static let replyMessageViewHeight = "replyMessageViewHeight"
    }

    fileprivate enum Padding {
        enum ContextView {
            static let height: CGFloat = 100.0
        }

        enum ReplyMessageView {
            static let height: CGFloat = 70.0
        }
    }

    let cardTemplateMargin: CGFloat = 150

    var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.separatorStyle = .none
        tv.allowsSelection = false
        tv.clipsToBounds = true
        tv.keyboardDismissMode = UIScrollView.KeyboardDismissMode.onDrag
        tv.accessibilityIdentifier = "InnerChatScreenTableView"
        tv.backgroundColor = UIColor.clear
        return tv
    }()

    let unreadScrollButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.lightText
        let image = UIImage(named: "scrollDown", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.layer.cornerRadius = 15
        return button
    }()

    open var backgroundView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.white
        return view
    }()

    open var contextTitleView: ALKContextTitleView = {
        let contextView = ALKContextTitleView(frame: CGRect.zero)
        contextView.backgroundColor = UIColor.orange
        return contextView
    }()

    open var templateView: ALKTemplateMessagesView?

    open lazy var replyMessageView: ALKReplyMessageView = {
        let view = ALKReplyMessageView(frame: CGRect.zero, configuration: configuration)
        view.backgroundColor = UIColor.gray
        return view
    }()

    var contentOffsetDictionary: [AnyHashable: AnyObject]!

    public init(configuration: ALKConfiguration,
                individualLaunch: Bool)
    {
        alMqttConversationService = ALMQTTConversationService.sharedInstance()
        self.individualLaunch = individualLaunch
        super.init(configuration: configuration)
        localizedStringFileName = configuration.localizedStringFileName
        contactService = ALContactService()
        configurePropertiesWith(configuration: configuration)
        chatBar.configuration = configuration
        typingNoticeView = TypingNotice(localizedStringFileName: configuration.localizedStringFileName)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @available(*, unavailable)
    public required init(configuration _: ALKConfiguration) {
        fatalError("init(configuration:) has not been implemented")
    }

    public func viewWillLoadFromTappingOnNotification() {
        isViewLoadedFromTappingOnNotification = true
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    override open func addObserver() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: nil,
            using: { [weak self] notification in
                print("keyboard will show")

                let keyboardFrameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                guard
                    let weakSelf = self,
                    weakSelf.chatBar.isTextViewFirstResponder,
                    let keyboardSize = (keyboardFrameValue as? NSValue)?.cgRectValue
                else {
                    self?.scrollTableViewUpForActiveField(notification: notification)
                    return
                }

                weakSelf.keyboardSize = keyboardSize

                let tableView = weakSelf.tableView

                let keyboardHeight = -1 * keyboardSize.height
                if weakSelf.bottomConstraint?.constant == keyboardHeight { return }

                weakSelf.bottomConstraint?.constant = keyboardHeight

                weakSelf.view?.layoutIfNeeded()

                if tableView.isCellVisible(section: weakSelf.viewModel.messageModels.count - 1, row: 0) {
                    tableView.scrollToBottomByOfset(animated: false)
                } else if weakSelf.viewModel.messageModels.count > 1 {
                    weakSelf.unreadScrollButton.isHidden = false
                }
            }
        )

        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: nil,
            using: { [weak self] notification in
                guard let weakSelf = self else { return }
                weakSelf.scrollTableViewDownForActiveField()

                let view = weakSelf.view
                weakSelf.bottomConstraint?.constant = 0
                let duration = (notification
                    .userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?
                    .doubleValue ?? 0.05
                UIView.animate(withDuration: duration, animations: {
                    view?.layoutIfNeeded()
                }, completion: { _ in
                    guard let viewModel = weakSelf.viewModel else { return }
                    viewModel.sendKeyboardDoneTyping()
                })
            }
        )

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "newMessageNotification"), object: nil, queue: nil, using: { [weak self]
            notification in
            guard let weakSelf = self, weakSelf.viewModel != nil else { return }
            let msgArray = notification.object as? [ALMessage]
            print("new notification received: ", msgArray?.first?.message as Any, msgArray?.count ?? "")
            guard let list = notification.object as? [Any], !list.isEmpty, weakSelf.isViewLoaded else { return }
            weakSelf.viewModel.addMessagesToList(list)
            //            weakSelf.handlePushNotification = false
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "notificationIndividualChat"), object: nil, queue: nil, using: {
            _ in
            print("notification individual chat received")
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "report_DELIVERED"), object: nil, queue: nil, using: { [weak self]
            notification in
            guard
                let weakSelf = self,
                weakSelf.viewModel != nil,
                let key = notification.object as? String
            else { return }
            weakSelf.viewModel.updateDeliveryReport(messageKey: key, status: Int32(DELIVERED.rawValue))
            print("report delievered notification received")
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "report_DELIVERED_READ"), object: nil, queue: nil, using: { [weak self]
            notification in
            guard
                let weakSelf = self,
                weakSelf.viewModel != nil,
                let key = notification.object as? String
            else { return }
            weakSelf.viewModel.updateDeliveryReport(messageKey: key, status: Int32(DELIVERED_AND_READ.rawValue))
            print("report delievered and read notification received")
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "report_CONVERSATION_DELIVERED_READ"), object: nil, queue: nil, using: { [weak self]
            notification in
            guard
                let weakSelf = self,
                weakSelf.viewModel != nil,
                let key = notification.object as? String
            else { return }
            weakSelf.viewModel.updateStatusReportForConversation(contactId: key, status: Int32(DELIVERED_AND_READ.rawValue))
            print("report conversation delievered and read notification received")
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "UPDATE_MESSAGE_SEND_STATUS"), object: nil, queue: nil, using: { [weak self]
            notification in
            print("Message sent notification received")
            guard
                let weakSelf = self,
                weakSelf.viewModel != nil,
                let message = notification.object as? ALMessage
            else { return }
            weakSelf.viewModel.updateSendStatus(message: message)
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "USER_DETAILS_UPDATE_CALL"), object: nil, queue: nil, using: { [weak self] notification in
            NSLog("update user detail notification received")
            guard
                let weakSelf = self,
                weakSelf.viewModel != nil,
                let userId = notification.object as? String
            else { return }
            weakSelf.updateUserDetail(userId)
        })

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "UPDATE_CHANNEL_NAME"), object: nil, queue: nil, using: { [weak self] _ in
            NSLog("update group name notification received")
            guard let weakSelf = self, weakSelf.viewModel != nil else { return }
            print("update group detail")
            guard weakSelf.viewModel.isGroup else { return }
            let alChannelService = ALChannelService()
            guard let key = weakSelf.viewModel.channelKey,
                  let channel = alChannelService.getChannelByKey(key),
                  channel.name != nil
            else {
                return
            }
            let profile = weakSelf.viewModel.conversationProfileFrom(contact: nil, channel: channel)
            weakSelf.navigationBar.updateView(profile: profile)
            weakSelf.newMessagesAdded()
        })

        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            guard let weakSelf = self, weakSelf.viewModel != nil else { return }
            weakSelf.viewModel.currentConversationProfile(completion: { profile in
                guard let profile = profile else { return }
                weakSelf.navigationBar.updateView(profile: profile)
            })
        }

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            guard let weakSelf = self, weakSelf.viewModel != nil else { return }
            weakSelf.viewModel.sendKeyboardDoneTyping()
        }

        if individualLaunch {
            NotificationCenter.default.addObserver(self, selector: #selector(pushNotification(notification:)), name: Notification.Name("pushNotification"), object: nil)
        }
    }

    override open func removeObserver() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "newMessageNotification"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "notificationIndividualChat"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "report_DELIVERED"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "report_DELIVERED_READ"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "report_CONVERSATION_DELIVERED_READ"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UPDATE_MESSAGE_SEND_STATUS"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "USER_DETAILS_UPDATE_CALL"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "UPDATE_CHANNEL_NAME"), object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            tableView.semanticContentAttribute = UISemanticContentAttribute.forceRightToLeft
        }
        edgesForExtendedLayout = []
        activityIndicator.center = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
        activityIndicator.color = UIColor.lightGray
        tableView.addSubview(activityIndicator)
        setUpRightNavigationButtons()
        setupNavigation()
        if individualLaunch {
            alMqttConversationService.mqttConversationDelegate = self
            alMqttConversationService.subscribeToConversation()
        }

        if viewModel.isGroup == true {
            let dispName = localizedString(forKey: "Somebody", withDefaultValue: SystemMessage.Chat.somebody, fileName: localizedStringFileName)
            setTypingNoticeDisplayName(displayName: dispName)
        } else {
            setTypingNoticeDisplayName(displayName: title ?? "")
        }

        viewModel.delegate = self
        refreshViewController()

        if let templates = viewModel.getMessageTemplates() {
            templateView = ALKTemplateMessagesView(frame: CGRect.zero, viewModel: ALKTemplateMessagesViewModel(messageTemplates: templates))
        }
        templateView?.messageSelected = { [weak self] template in
            self?.viewModel.selected(template: template, metadata: self?.configuration.messageMetadata)
        }
        if isFirstTime {
            setupView()
        } else {
            tableView.reloadData()
        }
        contentOffsetDictionary = [NSObject: AnyObject]()
        print("id: ", viewModel.messageModels.first?.contactId as Any)
    }

    override open func viewDidAppear(_: Bool) {}

    override open func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
        setRichMessageKitTheme()
        setupProfanityFilter()
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if isFirstTime, tableView.isCellVisible(section: 0, row: 0) {
            tableView.scrollToBottomByOfset(animated: false)
            isFirstTime = false
        }
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAudioPlayer()
        chatBar.stopRecording()
        if individualLaunch {
            if alMqttConversationService != nil {
                alMqttConversationService.unsubscribeToConversation()
            }
        }
        unsubscribingChannel()
    }

    override func backTapped() {
        view.endEditing(true)
        viewModel.sendKeyboardDoneTyping()
        let popVC = navigationController?.popViewController(animated: true)
        if popVC == nil {
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
            print("Successfuly synced the account  package status")
        }
    }

    func setupView() {
        unreadScrollButton.isHidden = true
        unreadScrollButton.addTarget(self, action: #selector(unreadScrollDownAction(_:)), for: .touchUpInside)

        backgroundView.backgroundColor = configuration.backgroundColor
        prepareTable()
        prepareMoreBar()
        prepareChatBar()
        setupMemberMention()
        replyMessageView.closeButtonTapped = { [weak self] _ in
            self?.hideReplyMessageView()
        }
        replyMessageView.displayNames = { [weak self] userIds in
            self?.viewModel.displayNames(ofUserIds: userIds)
        }
    }

    open func checkUserBlock() {
        guard !viewModel.isGroup, let contactId = viewModel.contactId else { return }
        ALUserService().getUserDetail(contactId) { contact in
            guard let contact = contact, contact.block else {
                self.chatBar.enableChat()
                return
            }
            self.chatBar.disableChat(
                message: self.localizedString(
                    forKey: "UnblockToEnableChat",
                    withDefaultValue: SystemMessage.Information.UnblockToEnableChat,
                    fileName: self.configuration.localizedStringFileName
                )
            )
        }
    }

    open func isChannelLeft() {
        guard let channelKey = viewModel.channelKey, let channel = ALChannelService().getChannelByKey(channelKey) else {
            return
        }
        // TODO: This returns nil sometimes. Find a better way.
        guard let members = ALChannelService().getListOfAllUsers(inChannel: channelKey) as? [String] else {
            return
        }
        if channel.type != 6 && channel.type != 10 && !members.contains(ALUserDefaultsHandler.getUserId()) {
            chatBar.disableChat(message: localizedString(forKey: "NotPartOfGroup", withDefaultValue: SystemMessage.Information.NotPartOfGroup, fileName: configuration.localizedStringFileName))
        } else {
            chatBar.enableChat()
        }
        // Disable group details for support group, open group and when user is not a member.
        navigationBar.disableTitleAction = channel.type == 10 || channel.type == 6 || !members.contains(ALUserDefaultsHandler.getUserId())
    }

    func prepareContextView() {
        guard viewModel.isContextBasedChat else {
            toggleVisibilityOfContextTitleView(false)
            return
        }
        guard let topicDetail = viewModel.getContextTitleData() else {
            toggleVisibilityOfContextTitleView(false)
            return
        }
        contextTitleView.configureWith(value: topicDetail)
        toggleVisibilityOfContextTitleView(true)
    }

    private func toggleVisibilityOfContextTitleView(_ show: Bool) {
        contextTitleView.isHidden = !show
        let height: CGFloat = show ? Padding.ContextView.height : 0
        contextTitleView.constraint(
            withIdentifier: ConstraintIdentifier.contextTitleView
        )?
            .constant = height
    }

    private func setupConstraints() {
        var allViews = [backgroundView, contextTitleView, tableView, autocompletionView, moreBar, chatBar, typingNoticeView, unreadScrollButton, replyMessageView]
        if let templateView = templateView {
            allViews.append(templateView)
        }
        view.addViewsForAutolayout(views: allViews)

        backgroundView.topAnchor.constraint(equalTo: contextTitleView.bottomAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: chatBar.topAnchor).isActive = true
        let contextViewTopCons = contextTitleView.topAnchor.constraint(equalTo: view.topAnchor)
        contextViewTopCons.priority = .init(rawValue: 750)
        contextViewTopCons.isActive = true
        contextTitleView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        contextTitleView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        contextTitleView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.contextTitleView).isActive = true

        templateView?.bottomAnchor.constraint(equalTo: typingNoticeView.topAnchor, constant: -5.0).isActive = true
        templateView?.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5.0).isActive = true
        templateView?.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -10.0).isActive = true
        templateView?.heightAnchor.constraint(equalToConstant: 45).isActive = true

        tableView.topAnchor.constraint(equalTo: contextTitleView.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: (templateView != nil) ? templateView!.topAnchor : typingNoticeView.topAnchor).isActive = true

        autocompletionView.bottomAnchor
            .constraint(equalTo: typingNoticeView.topAnchor).isActive = true
        autocompletionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        autocompletionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        typingNoticeViewHeighConstaint = typingNoticeView.heightAnchor.constraint(equalToConstant: 0)
        typingNoticeViewHeighConstaint?.isActive = true

        typingNoticeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
        typingNoticeView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12).isActive = true
        typingNoticeView.bottomAnchor.constraint(equalTo: replyMessageView.topAnchor).isActive = true

        chatBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        chatBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        bottomConstraint = chatBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        bottomConstraint?.isActive = true

        replyMessageView.leadingAnchor.constraint(
            equalTo: view.leadingAnchor
        ).isActive = true
        replyMessageView.trailingAnchor.constraint(
            equalTo: view.trailingAnchor
        ).isActive = true
        replyMessageView.heightAnchor.constraintEqualToAnchor(
            constant: 0,
            identifier: ConstraintIdentifier.replyMessageViewHeight
        )
        .isActive = true
        replyMessageView.bottomAnchor.constraint(
            equalTo: chatBar.topAnchor,
            constant: 0
        ).isActive = true

        unreadScrollButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        unreadScrollButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        unreadScrollButton.trailingAnchor.constraint(equalTo: tableView.trailingAnchor, constant: -10).isActive = true
        unreadScrollButton.bottomAnchor.constraint(equalTo: replyMessageView.topAnchor, constant: -10).isActive = true

        leftMoreBarConstraint = moreBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 56)
        leftMoreBarConstraint?.isActive = true
    }

    private func setupNavigation() {
        if let navBar = navigationController?.navigationBar {
            let titleColor = navBar.titleTextAttributes?[.foregroundColor] as? UIColor ?? .black
            loadingIndicator.set(titleColor)
            navigationBar.setupAppearance(navBar)
        }
        var items: [UIBarButtonItem] = navigationItem.leftBarButtonItems ?? []
        guard !items.contains(where: { $0.customView == navigationBar }) else { return }
        items.append(UIBarButtonItem(customView: navigationBar))
        navigationItem.leftBarButtonItems = items
    }

    private func prepareTable() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(tableTapped(gesture:)))
        gesture.numberOfTapsRequired = 1
        tableView.addGestureRecognizer(gesture)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsSelection = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        tableView.sectionHeaderHeight = 0.0
        tableView.sectionFooterHeight = 0.0
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.size.width, height: 0.1))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: tableView.bounds.size.width, height: 8))

        automaticallyAdjustsScrollViewInsets = false

        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        }
        tableView.estimatedRowHeight = 0

        tableView.register(ALKMyMessageCell.self)
        tableView.register(ALKFriendMessageCell.self)
        tableView.register(ALKMyPhotoPortalCell.self)
        tableView.register(ALKMyPhotoLandscapeCell.self)

        tableView.register(ALKFriendPhotoPortalCell.self)
        tableView.register(ALKFriendPhotoLandscapeCell.self)

        tableView.register(ALKMyVoiceCell.self)
        tableView.register(ALKFriendVoiceCell.self)
        tableView.register(ALKInformationCell.self)
        tableView.register(ALKMyLocationCell.self)
        tableView.register(ALKFriendLocationCell.self)
        tableView.register(ALKMyVideoCell.self)
        tableView.register(ALKFriendVideoCell.self)
        tableView.register(ALKMyGenericCardMessageCell.self)
        tableView.register(ALKFriendGenericCardMessageCell.self)
        tableView.register(ALKFriendMessageQuickReplyCell.self)
        tableView.register(ALKMyMessageQuickReplyCell.self)
        tableView.register(ALKMyMessageButtonCell.self)
        tableView.register(ALKFriendMessageButtonCell.self)
        tableView.register(ALKMyMessageListTemplateCell.self)
        tableView.register(ALKFriendMessageListTemplateCell.self)
        tableView.register(ALKMyDocumentCell.self)
        tableView.register(ALKFriendDocumentCell.self)
        tableView.register(ALKMyContactMessageCell.self)
        tableView.register(ALKFriendContactMessageCell.self)
        tableView.register(SentImageMessageCell.self)
        tableView.register(ReceivedImageMessageCell.self)
        tableView.register(ReceivedFAQMessageCell.self)
        tableView.register(SentFAQMessageCell.self)
        tableView.register(SentButtonsCell.self)
        tableView.register(ReceivedButtonsCell.self)

        tableView.register(ALKMyLinkPreviewCell.self)
        tableView.register(ALKFriendLinkPreviewCell.self)
        tableView.register(ALKMyFormCell.self)
        tableView.register(ALKFriendFormCell.self)
    }

    private func prepareMoreBar() {
        moreBar.bottomAnchor.constraint(equalTo: chatBar.topAnchor).isActive = true
        moreBar.isHidden = true
        moreBar.setHandleAction { [weak self] _ in
            self?.hideMoreBar()
        }
    }

    public func configureChatBar() {
        chatBar.setDefaultText(viewModel.prefilledMessage ?? "")
        if viewModel.isOpenGroup {
            chatBar.updateMediaViewVisibility(hide: true)
            chatBar.hideMicButton()
        } else {
            chatBar.updateMediaViewVisibility()
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func prepareChatBar() {
        // Update ChatBar's top view which contains send button and the text view.
        chatBar.grayView.backgroundColor = configuration.backgroundColor

        // Update background view's color which contains all the attachment options.
        chatBar.bottomBackgroundColor = configuration.chatBarAttachmentViewBackgroundColor

        chatBar.poweredByMessageTextView.hyperLink(mutableAttributedString: NSMutableAttributedString(string: "Powered by Applozic"),
                                                   url: URL(string: "https://Applozic.com")!,
                                                   clickString: "Applozic")

        if viewModel.showPoweredByMessage() { chatBar.showPoweredByMessage() }
        chatBar.accessibilityIdentifier = "chatBar"
        chatBar.setComingSoonDelegate(delegate: view)
        documentManager.delegate = self
        photoPicker.delegate = self
        chatBar.action = { [weak self] action in

            guard let weakSelf = self else {
                return
            }

            if case .more = action {
                if weakSelf.moreBar.isHidden == true {
                    weakSelf.showMoreBar()
                } else {
                    weakSelf.hideMoreBar()
                }

                return
            }

            weakSelf.hideMoreBar()

            switch action {
            case let .sendText(button, message):
                let message = message
                    .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if message.string.count < 1 {
                    return
                }

                button.isUserInteractionEnabled = false
                weakSelf.viewModel.sendKeyboardDoneTyping()

                weakSelf.chatBar.clear()
                weakSelf.autocompleteManager.cancelAndHide()

                if let profanityFilter = weakSelf.profanityFilter, profanityFilter.containsRestrictedWords(text: message.string) {
                    let profanityTitle = weakSelf.localizedString(
                        forKey: "profaneWordsTitle",
                        withDefaultValue: SystemMessage.Warning.profaneWordsTitle,
                        fileName: weakSelf.localizedStringFileName
                    )
                    let profanityMessage = weakSelf.localizedString(
                        forKey: "profaneWordsMessage",
                        withDefaultValue: SystemMessage.Warning.profaneWordsMessage,
                        fileName: weakSelf.localizedStringFileName
                    )
                    let okButtonTitle = weakSelf.localizedString(
                        forKey: "OkMessage",
                        withDefaultValue: SystemMessage.ButtonName.ok,
                        fileName: weakSelf.localizedStringFileName
                    )
                    let alert = UIAlertController(
                        title: profanityTitle,
                        message: profanityMessage,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(
                        title: okButtonTitle,
                        style: .cancel,
                        handler: nil
                    ))
                    weakSelf.present(alert, animated: true, completion: nil)
                    button.isUserInteractionEnabled = true
                    return
                }

                var messageMetadata = self?.configuration.messageMetadata
                let mentionHandler = MessageMentionEncoder(message: message)
                var messageToSend = message.string
                if mentionHandler.containsMentions {
                    messageToSend = mentionHandler.replaceMentionsWithKeys().string
                    let metadataForMentions = mentionHandler.metadataForMentions() ?? [:]
                    // In case of a key match using the value set in config
                    messageMetadata = (messageMetadata ?? [:])
                        .merging(metadataForMentions) { current, _ in current }
                }
                weakSelf.isJustSent = true
                print("About to send this message: ", messageToSend)
                weakSelf.viewModel.send(message: messageToSend, isOpenGroup: weakSelf.viewModel.isOpenGroup, metadata: messageMetadata)
                button.isUserInteractionEnabled = true
            case .chatBarTextChange:

                weakSelf.viewModel.sendKeyboardBeginTyping()

                UIView.animate(withDuration: 0.05, animations: { () in
                    weakSelf.view.layoutIfNeeded()
                }, completion: { [weak self] _ in

                    guard let weakSelf = self else {
                        return
                    }

                    if weakSelf.tableView.isAtBottom == true, weakSelf.isJustSent == false {
                        weakSelf.tableView.scrollToBottomByOfset(animated: false)
                    }
                })
            case let .sendVoice(voice):
                weakSelf.viewModel.send(voiceMessage: voice as Data, metadata: self?.configuration.messageMetadata)

            case .startVideoRecord:
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
                        granted in
                        DispatchQueue.main.async {
                            if granted {
                                let imagePicker = UIImagePickerController()
                                imagePicker.delegate = self
                                imagePicker.allowsEditing = true
                                imagePicker.sourceType = .camera
                                imagePicker.mediaTypes = [kUTTypeMovie as String]
                                UIViewController.topViewController()?.present(imagePicker, animated: true, completion: nil)
                            } else {
                                let msg = weakSelf.localizedString(
                                    forKey: "EnableCameraPermissionMessage",
                                    withDefaultValue: SystemMessage.Camera.cameraPermission,
                                    fileName: weakSelf.localizedStringFileName
                                )
                                let title = weakSelf.localizedString(forKey: "Settings", withDefaultValue: SystemMessage.LabelName.Settings, fileName: weakSelf.localizedStringFileName)
                                weakSelf.showAlertForApplicationSettings(title: title, message: msg)
                            }
                        }
                    })
                } else {
                    let msg = weakSelf.localizedString(forKey: "CameraNotAvailableMessage", withDefaultValue: SystemMessage.Camera.CamNotAvailable, fileName: weakSelf.localizedStringFileName)
                    let title = weakSelf.localizedString(forKey: "CameraNotAvailableTitle", withDefaultValue: SystemMessage.Camera.camNotAvailableTitle, fileName: weakSelf.localizedStringFileName)
                    weakSelf.showAlertForApplicationSettings(title: title, message: msg)
                }
            case .showImagePicker:
                if #available(iOS 14, *), weakSelf.configuration.isNewSystemPhotosUIEnabled {
                    weakSelf.photoPicker.openGallery(from: weakSelf)
                } else {
                    guard let vc = ALKCustomPickerViewController.makeInstanceWith(delegate: weakSelf, and: weakSelf.configuration)
                    else {
                        return
                    }
                    weakSelf.present(vc, animated: true, completion: nil)
                }
            case .showLocation:
                let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.mapView, bundle: Bundle.applozic)

                guard let nav = storyboard.instantiateInitialViewController() as? ALKBaseNavigationViewController else { return }
                guard let mapViewVC = nav.viewControllers.first as? ALKMapViewController else { return }
                mapViewVC.delegate = self
                mapViewVC.setConfiguration(weakSelf.configuration)
                self?.present(nav, animated: true, completion: {})
            case let .cameraButtonClicked(button):
                guard let vc = ALKCustomCameraViewController.makeInstanceWith(delegate: weakSelf, and: weakSelf.configuration)
                else {
                    button.isUserInteractionEnabled = true
                    return
                }
                weakSelf.present(vc, animated: true, completion: nil)
                button.isUserInteractionEnabled = true

            case .shareContact:
                weakSelf.shareContact()
            case .showDocumentPicker:
                weakSelf.documentManager.showPicker(from: weakSelf)
            default:
                print("Not available")
            }
        }
    }

    private func setupProfanityFilter() {
        func makeProfanityFilter(
            withRegexPattern pattern: String,
            andFileName filename: String
        ) throws -> ProfanityFilter? {
            switch (pattern, filename) {
            case ("", ""):
                return nil
            case let (pattern, ""):
                return (try ProfanityFilter(restrictedMessageRegex: pattern))
            case let ("", filename):
                return (try ProfanityFilter(fileName: filename))
            case let (pattern, filename):
                return (try ProfanityFilter(fileName: filename, restrictedMessageRegex: pattern))
            }
        }

        do {
            profanityFilter = try makeProfanityFilter(
                withRegexPattern: configuration.restrictedMessageRegexPattern,
                andFileName: configuration.restrictedWordsFileName
            )
        } catch {
            print("Error while setting up profanity filter: \(error.localizedDescription)")
        }
    }

    private func setupMemberMention() {
        if configuration.isMemberMentionEnabled {
            autocompleteManager.registerPrefix(
                prefix: MessageMention.Prefix,
                configuration: AutoCompleteItemConfiguration.memberMention,
                cellType: MentionAutoCompleteCell.self
            )
        }
    }

    // MARK: public Control Typing notification

    func setTypingNoticeDisplayName(displayName: String) {
        typingNoticeView.setDisplayName(displayName: displayName)
    }

    @objc func tableTapped(gesture _: UITapGestureRecognizer) {
        hideMoreBar()
        view.endEditing(true)
    }

    /// Call this method after proper viewModel initialization
    open func refreshViewController() {
        clearAndReloadTable()
        updateConversationProfile()
        prepareContextView()
        configureChatBar()
        // Check for group left
        isChannelLeft()
        checkUserBlock()
        subscribeChannelToMqtt()
        viewModel.prepareController()
    }

    @objc open func pushNotification(notification: NSNotification) {
        print("Push notification received in ALKConversationViewController: ", notification.object ?? "")
        let (notifData, _) = NotificationHelper().notificationInfo(notification as Notification)
        guard
            isViewLoaded,
            view.window != nil,
            let notificationData = notifData,
            !NotificationHelper().isNotificationForActiveThread(notificationData)
        else { return }
        unsubscribingChannel()
        viewModel.contactId = notificationData.userId
        viewModel.channelKey = notificationData.groupId
        var convProxy: ALConversationProxy?
        if let convId = notificationData.conversationId,
           let conversationProxy = ALConversationService().getConversationByKey(convId)
        {
            convProxy = conversationProxy
        }
        viewModel.conversationProxy = convProxy
        viewModel.prefilledMessage = nil
        viewWillLoadFromTappingOnNotification()
        refreshViewController()
    }

    /// Call this before changing viewModel contents
    public func unsubscribingChannel() {
        guard viewModel != nil, alMqttConversationService != nil else { return }
        if !viewModel.isOpenGroup {
            alMqttConversationService.sendTypingStatus(
                ALUserDefaultsHandler.getApplicationKey(),
                userID: viewModel.contactId,
                andChannelKey: viewModel.channelKey,
                typing: false
            )
            alMqttConversationService.unSubscribe(toChannelConversation: viewModel.channelKey)
        } else {
            alMqttConversationService.unSubscribe(toOpenChannel: viewModel.channelKey)
        }
    }

    public func scrollViewWillBeginDecelerating(_: UIScrollView) {
        UIMenuController.shared.setMenuVisible(false, animated: true)
        hideMoreBar()
    }

    // Called from the parent VC
    public func showTypingLabel(status: Bool, userId: String) {
        /// Don't show typing status when contact is blocked
        guard
            let contact = ALContactService().loadContact(byKey: "userId", value: userId),
            !contact.block,
            !contact.blockBy
        else {
            return
        }

        if status {
            timerTask = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(invalidateTimerAndUpdateHeightConstraint(_:)), userInfo: nil, repeats: false)
        } else {
            timerTask.invalidate()
        }

        typingNoticeViewHeighConstaint?.constant = status ? 30 : 0
        view.layoutIfNeeded()
        if tableView.isAtBottom {
            tableView.scrollToBottomByOfset(animated: false)
        }

        if configuration.showNameWhenUserTypesInGroup {
            guard let name = nameForTypingStatusUsing(userId: userId) else {
                return
            }
            setTypingNoticeDisplayName(displayName: name)
        } else {
            let name = defaultNameForTypingStatus()
            setTypingNoticeDisplayName(displayName: name)
        }
    }

    @objc public func invalidateTimerAndUpdateHeightConstraint(_: Timer?) {
        timerTask.invalidate()
        typingNoticeViewHeighConstaint?.constant = 0
    }

    public func sync(message: ALMessage) {
        /// Return if message is sent by loggedin user
        guard !message.isSentMessage() else { return }
        guard !viewModel.isOpenGroup else {
            viewModel.syncOpenGroup(message: message)
            return
        }
        guard !configuration.isInAppNotificationBannerDisabled else {
            return
        }
        guard message.conversationId == nil || message.conversationId != viewModel.conversationProxy?.id else {
            return
        }
        if let groupId = message.groupId, groupId != viewModel.channelKey {
            let notificationView = ALNotificationView(alMessage: message, withAlertMessage: message.message)
            notificationView?.showNativeNotificationWithcompletionHandler {
                _ in

                self.viewModel.contactId = nil
                self.viewModel.prefilledMessage = nil
                self.viewModel.channelKey = groupId
                self.viewModel.isFirstTime = true
                self.refreshViewController()
            }
        } else if message.groupId == nil, let contactId = message.contactId, contactId != viewModel.contactId {
            let notificationView = ALNotificationView(alMessage: message, withAlertMessage: message.message)
            notificationView?.showNativeNotificationWithcompletionHandler {
                _ in
                self.viewModel.contactId = contactId
                self.viewModel.channelKey = nil
                self.viewModel.prefilledMessage = nil
                self.viewModel.isFirstTime = true
                self.refreshViewController()
            }
        }
    }

    public func updateDeliveryReport(messageKey: String?, contactId _: String?, status: Int32?) {
        guard let key = messageKey, let status = status else {
            return
        }
        viewModel.updateDeliveryReport(messageKey: key, status: status)
    }

    public func updateStatusReport(contactId: String?, status: Int32?) {
        guard let id = contactId, let status = status else {
            return
        }
        viewModel.updateStatusReportForConversation(contactId: id, status: status)
    }

    private func defaultNameForTypingStatus() -> String {
        if viewModel.isGroup == true {
            return "Somebody"
        } else {
            return title ?? ""
        }
    }

    private func nameForTypingStatusUsing(userId: String) -> String? {
        guard let contact = contactService.loadContact(byKey: "userId", value: userId) else {
            return nil
        }
        if contact.block || contact.blockBy {
            return nil
        }
        return contact.getDisplayName()
    }

    public func subscribeChannelToMqtt() {
        guard viewModel != nil, alMqttConversationService != nil else { return }
        let channelService = ALChannelService()
        if viewModel.isGroup, let groupId = viewModel.channelKey, !channelService.isChannelLeft(groupId), !ALChannelService.isChannelDeleted(groupId) {
            if !viewModel.isOpenGroup {
                alMqttConversationService.subscribe(toChannelConversation: groupId)
            } else {
                alMqttConversationService.subscribe(toOpenChannel: groupId)
            }
        } else if !viewModel.isGroup {
            alMqttConversationService.subscribe(toChannelConversation: nil)
        }
        if viewModel.isGroup, ALUserDefaultsHandler.isUserLoggedInUserSubscribedMQTT() {
            alMqttConversationService.unSubscribe(toChannelConversation: nil)
        }
    }

    @objc func unreadScrollDownAction(_: UIButton) {
        tableView.scrollToBottom()
        unreadScrollButton.isHidden = true
    }

    func attachmentViewDidTapDownload(view: UIView, indexPath: IndexPath) {
        guard let message = viewModel.messageForRow(indexPath: indexPath) else { return }
        viewModel.downloadAttachment(message: message, view: view)
    }

    func attachmentViewDidTapUpload(view: UIView, indexPath: IndexPath) {
        guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
            let notificationView = ALNotificationView()
            notificationView.noDataConnectionNotificationView()
            return
        }
        viewModel.uploadImage(view: view, indexPath: indexPath)
    }

    func attachmentUploadDidCompleteWith(response: Any?, indexPath: IndexPath) {
        viewModel.uploadAttachmentCompleted(responseDict: response, indexPath: indexPath)
    }

    func isCellVisible(identifier: String) -> Bool {
        guard let index = viewModel.sectionFor(identifier: identifier) else { return false }
        let cell = tableView.cellForRow(at: IndexPath(row: 0, section: index)) as? ALKChatBaseCell<ALKMessageViewModel>
        return cell != nil
    }

    func messageAvatarViewDidTap(messageVM: ALKMessageViewModel, indexPath _: IndexPath) {
        // Open chat thread
        guard viewModel.isGroup, isProfileTapActionEnabled else { return }

        // Get the user id of that user
        guard let receiverId = messageVM.receiverId else { return }

        let vm = ALKConversationViewModel(contactId: receiverId, channelKey: nil, localizedStringFileName: configuration.localizedStringFileName)
        let conversationVC = ALKConversationViewController(configuration: configuration, individualLaunch: true)
        conversationVC.viewModel = vm
        navigationController?.pushViewController(conversationVC, animated: true)
    }

    func showReplyMessageView() {
        replyMessageView.constraint(
            withIdentifier: ConstraintIdentifier.replyMessageViewHeight
        )?
            .constant = Padding.ReplyMessageView.height
    }

    func hideReplyMessageView() {
        replyMessageView.constraint(
            withIdentifier: ConstraintIdentifier.replyMessageViewHeight
        )?
            .constant = 0
    }

    func scrollTo(message: ALKMessageViewModel) {
        guard
            let metadata = message.metadata,
            let replyId = metadata[AL_MESSAGE_REPLY_KEY] as? String
        else {
            return
        }
        let messageService = ALMessageService()
        let actualMessage = messageService.getALMessage(byKey: replyId).messageModel
        guard let indexPath = viewModel.getIndexpathFor(message: actualMessage)
        else {
            let controller = ALKReplyController(messageKey: replyId, configuration: configuration)
            controller.modalPresentationStyle = .overCurrentContext
            present(controller, animated: true, completion: nil)
            return
        }
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }

    func quickReplySelected(
        index: Int,
        title: String,
        template: [[String: Any]],
        message: ALKMessageViewModel,
        isButtonClickDisabled: Bool
    ) {
        print("\(title), \(index) quick reply button selected")
        sendNotification(withName: "QuickReplyButtonSelected", buttonName: title, buttonIndex: index, template: template, messageKey: message.identifier)

        guard !isButtonClickDisabled else { return }

        /// Get message to send
        guard index < template.count, index >= 0 else { return }
        let dict = template[index]
        let metadata = dict["replyMetadata"] as? [String: Any]
        let languageCode = dict["updateLanguage"] as? String
        /// Use metadata
        sendQuickReply(title, metadata: metadata, languageCode: languageCode)
    }

    func richButtonSelected(index: Int,
                            title: String,
                            message: ALKMessageViewModel,
                            isButtonClickDisabled: Bool)
    {
        guard !isButtonClickDisabled else {
            return
        }
        guard let payload = message.payloadFromMetadata()?[index],
              let action = payload["action"] as? [String: Any],
              let type = action["type"] as? String
        else {
            return
        }
        switch type {
        case "link":
            linkButtonSelected(action)
        case "submit":
            let ackMessage = action["message"] as? String ?? title
            submitButtonSelected(metadata: action, text: ackMessage)
        case "quickReply":
            let ackMessage = action["message"] as? String ?? title
            let languageCode = action["updateLanguage"] as? String
            sendQuickReply(ackMessage, metadata: payload["replyMetadata"] as? [String: Any], languageCode: languageCode)
        default:
            print("Do nothing")
        }
    }

    func messageButtonSelected(
        index: Int,
        title: String,
        message: ALKMessageViewModel,
        isButtonClickDisabled: Bool
    ) {
        guard !isButtonClickDisabled,
              let selectedButton = message.payloadFromMetadata()?[index],
              let buttonTitle = selectedButton["name"] as? String,
              buttonTitle == title
        else {
            return
        }

        guard
            let type = selectedButton["type"] as? String,
            type == "link"
        else {
            /// Submit Button
            let text = selectedButton["replyText"] as? String ?? selectedButton["name"] as! String
            submitButtonSelected(metadata: message.metadata!, text: text)
            return
        }
        linkButtonSelected(selectedButton)
    }

    func listTemplateSelected(defaultText: String?, action: ListTemplate.Action) {
        guard !configuration.disableRichMessageButtonAction else { return }
        guard let type = action.type else {
            print("Type not defined for action")
            return
        }

        switch type {
        case ActionType.link.rawValue:
            guard let urlString = action.url, let url = URL(string: urlString) else { return }
            openLink(url)

        case ActionType.quickReply.rawValue:
            let text = action.text ?? defaultText
            guard let msg = text else { return }
            let languageCode = action.updateLanguage
            sendQuickReply(msg, metadata: nil, languageCode: languageCode)
        default:
            print("Action type is neither \"link\" nor \"quick_reply\"")
            var infoDict = [String: Any]()
            infoDict["action"] = action
            infoDict["userId"] = viewModel.contactId
            NotificationCenter.default.post(name: Notification.Name(rawValue: "ListTemplateSelected"), object: infoDict)
        }
    }

    func cardTemplateSelected(tag: Int, title: String, template: CardTemplate, message: ALKMessageViewModel) {
        guard
            message.isMyMessage == false,
            configuration.disableRichMessageButtonAction == false
        else {
            return
        }

        guard
            let buttons = template.buttons, tag < buttons.count,
            let action = buttons[tag].action,
            let payload = action.payload
        else {
            print("\(tag) Button for this card is nil unexpectedly :: \(template)")
            return
        }

        switch action.type {
        case CardTemplateActionType.link.rawValue:
            guard let urlString = payload.url, let url = URL(string: urlString) else { return }
            openLink(url)
        case CardTemplateActionType.submit.rawValue:
            var dict = [String: Any]()
            dict["formData"] = payload.formData?.dictionary
            dict["formAction"] = payload.formAction
            dict["requestType"] = payload.requestType
            submitButtonSelected(metadata: dict, text: payload.text ?? "")
        case CardTemplateActionType.quickReply.rawValue:
            let text = buttons[tag].action?.payload?.message ?? buttons[tag].name
            let languageCode = buttons[tag].action?.payload?.updateLanguage
            sendQuickReply(text, metadata: nil, languageCode: languageCode)
        default:
            /// Action not defined. Post notification outside.
            sendNotification(withName: "GenericRichCardButtonSelected", buttonName: title, buttonIndex: tag, template: message.payloadFromMetadata() ?? [], messageKey: message.identifier)
        }
    }

    @objc func dismissContact() {
        ALPushAssist().topViewController.dismiss(animated: true, completion: nil)
    }

    func openContact(_ contact: CNContact) {
        CNContactStore().requestAccess(for: .contacts) { [weak self] granted, _ in
            guard let weakSelf = self else {
                return
            }
            if granted {
                let vc = CNContactViewController(forUnknownContact: contact)
                vc.contactStore = CNContactStore()
                let nav = UINavigationController(rootViewController: vc)
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: weakSelf, action: #selector(self?.dismissContact))
                weakSelf.present(nav, animated: true, completion: nil)
            } else {
                let title = weakSelf.localizedString(forKey: "Settings", withDefaultValue: SystemMessage.LabelName.Settings, fileName: weakSelf.localizedStringFileName)

                let message = weakSelf.localizedString(
                    forKey: "EnableContactPermissionMessage",
                    withDefaultValue: SystemMessage.Contact.permissionMessage,
                    fileName: weakSelf.localizedStringFileName
                )
                weakSelf.showAlertForApplicationSettings(title: title, message: message)
            }
        }
    }

    func openRichMessageImageView(imageUrl: URL) {
        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.previewImage, bundle: Bundle.applozic)
        guard let nav = storyboard.instantiateInitialViewController() as? ALKBaseNavigationViewController,
              let vc = nav.viewControllers.first as? ALKPreviewImageViewController
        else {
            return
        }
        vc.configuration = configuration
        vc.viewModel = ALKPreviewImageViewModel(imageUrl: imageUrl, localizedStringFileName: configuration.localizedStringFileName)
        UIViewController.topViewController()?.present(nav, animated: true, completion: nil)
    }

    func collectionViewOffsetFromIndex(_ index: Int) -> CGFloat {
        let value = contentOffsetDictionary[index]
        let horizontalOffset = CGFloat(value != nil ? value!.floatValue : 0)
        return horizontalOffset
    }

    private func showMoreBar() {
        moreBar.isHidden = false
        leftMoreBarConstraint?.constant = 0

        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] () in
            self?.view.layoutIfNeeded()
        }, completion: { [weak self] _ in

            guard let strongSelf = self else { return }

            strongSelf.view.bringSubviewToFront(strongSelf.moreBar)
            strongSelf.view.sendSubviewToBack(strongSelf.tableView)
        })
    }

    private func sendNotification(withName: String, buttonName: String, buttonIndex: Int, template: [[String: Any]], messageKey: String) {
        var infoDict = [String: Any]()
        infoDict["buttonName"] = buttonName
        infoDict["buttonIndex"] = buttonIndex
        infoDict["template"] = template
        infoDict["messageKey"] = messageKey
        infoDict["userId"] = viewModel.contactId
        NotificationCenter.default.post(name: Notification.Name(rawValue: withName), object: infoDict)
    }

    private func hideMoreBar() {
        if leftMoreBarConstraint?.constant == 0 {
            leftMoreBarConstraint?.constant = 56

            UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] () in
                self?.view.layoutIfNeeded()
            }, completion: { [weak self] _ in
                self?.moreBar.isHidden = true
            })
        }
    }

    func showParticipantListChat() {
        guard let channelKey = viewModel.channelKey else { return }
        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.createGroupChat, bundle: Bundle.applozic)
        if let vc = storyboard.instantiateViewController(withIdentifier: "ALKCreateGroupViewController") as? ALKCreateGroupViewController {
            vc.configuration = configuration
            vc.setCurrentGroupSelected(
                groupId: channelKey,
                groupProfile: viewModel.groupProfileImgUrl(),
                delegate: self
            )
            vc.addContactMode = .existingChat
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func configurePropertiesWith(configuration: ALKConfiguration) {
        isGroupDetailActionEnabled = configuration.isTapOnNavigationBarEnabled
        isProfileTapActionEnabled = configuration.isProfileTapActionEnabled
    }

    open func sendQuickReply(_ text: String, metadata: [String: Any]?, languageCode _: String?) {
        var customMetadata = metadata ?? [String: Any]()

        guard let messageMetadata = configuration.messageMetadata as? [String: Any] else {
            viewModel.send(message: text, metadata: customMetadata)
            return
        }
        customMetadata.merge(messageMetadata) { $1 }
        viewModel.send(message: text, metadata: customMetadata)
    }

    private func postRequestUsing(url: URL, data: Data) -> URLRequest? {
        var request = URLRequest(url: url)
        request.timeoutInterval = 600
        request.httpMethod = "POST"
        request.httpBody = data
        let contentLength = String(format: "%lu", UInt(data.count))
        request.setValue(contentLength, forHTTPHeaderField: "Content-Length")
        return request
    }

    private func requestHandler(_ request: URLRequest, _ completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            print("Response is \(String(describing: response)) and error is \(String(describing: error))")
            completion(data, response, error)
        }
        task.resume()
    }

    private func openLink(_ url: URL) {
        UIApplication.shared.open(url)
    }

    private func linkButtonSelected(_ selectedButton: [String: Any]) {
        guard
            let urlString = selectedButton["url"] as? String,
            let url = URL(string: urlString)
        else {
            return
        }
        openLink(url)
    }

    private func submitButtonResponse(request: URLRequest) {
        activityIndicator.startAnimating()
        let group = DispatchGroup()
        group.enter()
        var responseData: String?
        var responseUrl: URL?
        requestHandler(request) { dat, response, error in
            guard error == nil, let data = dat, let url = response?.url else {
                print("Error while making submit button request: \(error?.localizedDescription ?? "")")
                group.leave()
                return
            }
            responseData = String(data: data, encoding: .utf8)
            responseUrl = url
            group.leave()
        }
        group.notify(queue: .main) {
            self.activityIndicator.stopAnimating()
            guard let data = responseData, let url = responseUrl else {
                return
            }
            let vc = ALKWebViewController(htmlString: data, url: url, title: "")
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    /// For templateId 3, formData is a string.
    /// But for templateId 11, formData is a dictionary.
    private func submitButtonSelected(metadata: [String: Any], text: String) {
        guard
            let urlString = metadata["formAction"] as? String,
            let url = URL(string: urlString)
        else {
            return
        }
        var request: URLRequest!
        if let formData = metadata["formData"] as? String {
            guard
                let data = formData.data(using: .utf8),
                let urlRequest = postRequestUsing(url: url, data: data)
            else { return }
            request = urlRequest
        } else if let formData = metadata["formData"] as? [String: Any] {
            guard
                let data = ALUtilityClass.generateJsonString(from: formData)?.data(using: .utf8),
                let urlRequest = postRequestUsing(url: url, data: data)
            else { return }
            request = urlRequest
        } else {
            return
        }
        viewModel.send(message: text, metadata: nil)
        if let type = metadata["requestType"] as? String, type == "json" {
            let contentType = "application/json"
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
            requestHandler(request) { _, _, _ in }
        } else {
            let contentType = "application/x-www-form-urlencoded"
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
            submitButtonResponse(request: request)
        }
    }

    func formSubmitButtonSelected(formSubmitData: FormDataSubmit?, messageModel: ALKMessageViewModel, isButtonClickDisabled: Bool) {
        guard let formData = formSubmitData,
              !formData.multiSelectFields.isEmpty ||
              !formData.textFields.isEmpty ||
              !formData.singleSelectFields.isEmpty ||
              !formData.dateFields.isEmpty
        else {
            print("Invalid empty form data for submit")
            return
        }

        guard !isButtonClickDisabled,
              let formTemplate = messageModel.formTemplate()
        else {
            return
        }
        var postFormData = [String: Any]()
        var requestType: String?
        var formAction: String?
        var message: String?

        for element in formTemplate.elements {
            if element.contentType == .hidden,
               let elementData = element.data,
               let hiddenName = elementData.name,
               let hiddenValue = elementData.value
            {
                postFormData[hiddenName] = hiddenValue
            }

            if element.contentType == .submit,
               let elementData = element.data,
               let action = elementData.action
            {
                if let formTemplateRequest = action.requestType {
                    requestType = formTemplateRequest
                }

                if let formTemplateAction = action.formAction {
                    formAction = formTemplateAction
                }
                if let formTemplateMessage = action.message {
                    message = formTemplateMessage
                }
            }
        }

        let viewModelItems = formTemplate.viewModeItems
        for (pos, text) in formData.textFields {
            let element = viewModelItems[pos]
            switch element.type {
            case .text:
                if let textModel = element as? FormViewModelTextItem {
                    postFormData[textModel.label] = text
                }
            case .password:
                if let passwordModel = element as? FormViewModelPasswordItem {
                    postFormData[passwordModel.label] = text
                }
            default:
                break
            }
        }

        for (section, pos) in formData.singleSelectFields {
            guard let singleSelectModel = viewModelItems[section] as? FormViewModelSingleselectItem else {
                return
            }
            let value = singleSelectModel.options[pos].value
            postFormData[singleSelectModel.name] = value
        }

        for (section, pos) in formData.multiSelectFields {
            guard let multiSelect = viewModelItems[section] as? FormViewModelMultiselectItem else {
                return
            }
            var selectedArray = [String]()
            for selectedPos in pos {
                let value = multiSelect.options[selectedPos].value
                selectedArray.append(value)
            }

            let data = json(from: selectedArray)
            postFormData[multiSelect.name] = data
        }

        for (position, timeInMillSecs) in formData.dateFields {
            let element = viewModelItems[position]
            switch element.type {
            case .time:
                if let formViewModelTimeItem = element as? FormViewModelTimeItem {
                    postFormData[formViewModelTimeItem.label] = String(timeInMillSecs)
                }
            case .date:
                if let formViewModelDateItem = element as? FormViewModelDateItem {
                    postFormData[formViewModelDateItem.label] = String(timeInMillSecs)
                }
            case .dateTimeLocal:
                if let formViewModelDateTimeLocalItem = element as? FormViewModelDateTimeLocalItem {
                    postFormData[formViewModelDateTimeLocalItem.label] = String(timeInMillSecs)
                }
            default:
                break
            }
        }

        guard let formJsonValue = ALUtilityClass.generateJsonString(from: postFormData) else {
            print("Failed to convert the formdata to json")
            return
        }

        var formJsonData = [String: Any]()
        formJsonData["formData"] = formJsonValue

        guard let chatContextData = getUpdateMessageMetadata(with: formJsonData) else {
            print("Failed to convert the chat context data to json")
            return
        }

        if let type = requestType,
           type == "postBackToBotPlatform"
        {
            if let messageString = message {
                viewModel.send(message: messageString, metadata: chatContextData)
            }
        } else {
            if let messageString = message {
                viewModel.send(message: messageString, metadata: chatContextData)
            }
            guard
                let urlString = formAction,
                let url = URL(string: urlString)
            else {
                print("URL for posting is not valid")
                return
            }
            var request: URLRequest!
            guard let jsonData = try? JSONSerialization.data(withJSONObject: chatContextData),
                  let jsonString = String(data: jsonData, encoding: .utf8),
                  let data = jsonString.data(using: .utf8),
                  let urlRequest = postRequestUsing(url: url, data: data)
            else { return }

            request = urlRequest
            if requestType == "json" {
                let contentType = "application/json"
                request.addValue(contentType, forHTTPHeaderField: "Content-Type")
                requestHandler(request) { _, _, _ in }
            } else {
                let contentType = "application/x-www-form-urlencoded"
                request.addValue(contentType, forHTTPHeaderField: "Content-Type")
                submitButtonResponse(request: request)
            }
        }
    }

    func getUpdateMessageMetadata(with info: [String: Any]) -> [String: Any]? {
        var metadata = [String: Any]()
        do {
            let messageInfoData = try JSONSerialization
                .data(withJSONObject: info, options: .prettyPrinted)
            let messageInfoString = String(data: messageInfoData, encoding: .utf8) ?? ""
            metadata["KM_CHAT_CONTEXT"] = messageInfoString

        } catch {
            print("Failed to convert json ")
        }
        return metadata
    }

    func json(from object: Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }

    private func shareContact() {
        CNContactStore().requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    let vc = CNContactPickerViewController()
                    vc.delegate = self
                    self.present(vc, animated: true, completion: nil)
                } else {
                    let title = self.localizedString(forKey: "Settings", withDefaultValue: SystemMessage.LabelName.Settings, fileName: self.localizedStringFileName)

                    let message = self.localizedString(
                        forKey: "EnableContactPermissionMessage",
                        withDefaultValue: SystemMessage.Contact.permissionMessage,
                        fileName: self.localizedStringFileName
                    )
                    self.showAlertForApplicationSettings(title: title, message: message)
                }
            }
        }
    }

    func setRichMessageKitTheme() {
        let appSettingsUserDefaults = ALKAppSettingsUserDefaults()
        let sentMessageBackgroundColor = appSettingsUserDefaults.getSentMessageBackgroundColor()
        let receivedMessageBackgroundColor = appSettingsUserDefaults.getReceivedMessageBackgroundColor()

        ImageBubbleTheme.sentMessage.bubble.color = sentMessageBackgroundColor
        ImageBubbleTheme.sentMessage.bubble.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
        ImageBubbleTheme.receivedMessage.bubble.color = receivedMessageBackgroundColor
        ImageBubbleTheme.receivedMessage.bubble.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius

        MessageTheme.sentMessage.message = ALKMessageStyle.sentMessage
        MessageTheme.sentMessage.bubble.color = sentMessageBackgroundColor
        MessageTheme.sentMessage.bubble.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
        MessageTheme.receivedMessage.message = ALKMessageStyle.receivedMessage
        MessageTheme.receivedMessage.bubble.color = receivedMessageBackgroundColor
        MessageTheme.receivedMessage.bubble.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius

        MessageTheme.receivedMessage.displayName = ALKMessageStyle.displayName
        MessageTheme.receivedMessage.time = ALKMessageStyle.time
        MessageTheme.sentMessage.time = ALKMessageStyle.time
        setSentMessageStatus()

        /// Rich Message button primary color
        ALKRichMessageStyle.primaryColor = appSettingsUserDefaults.getButtonPrimaryColor()
    }

    func setSentMessageStatus() {
        let messageStatus = ALKMessageStyle.messageStatus
        for (status, icon) in messageStatus.statusIcons {
            setStatus(statusIcon: icon, status: status)
        }
    }

    func setStatus(statusIcon: ALKMessageStyle.StatusIcon, status: MessageStatus) {
        switch statusIcon {
        case let .templateImageWithTint(image, tintColor):
            MessageTheme.messageStatus.set(icon: .templateImageWithTint(image: image, tintColor: tintColor), for: status)
        case let .normalImage(image):
            MessageTheme.messageStatus.set(icon: .normalImage(image: image), for: status)
        case .none:
            MessageTheme.messageStatus.set(icon: .none, for: status)
        }
    }

    func reloadIfFormMessage(message: ALKMessageModel, indexPath: IndexPath) {
        guard message.messageType == .form else { return }
        updateMessageAt(indexPath: indexPath)
    }

    func showDatePickerController(delegate: ALKDatePickerButtonClickProtocol,
                                  identifier: String,
                                  position: Int,
                                  datePickerMode: UIDatePicker.Mode,
                                  localizedStringFileName: String)
    {
        let datePickerVC = ALKFormDatePickerViewController(delegate: delegate,
                                                           messageKey: identifier,
                                                           position: position,
                                                           datePickerMode: datePickerMode,
                                                           localizedStringFileName: localizedStringFileName)
        datePickerVC.modalPresentationStyle = .overCurrentContext
        present(datePickerVC, animated: true, completion: nil)
    }

    private func showAlertForApplicationSettings(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let settingsTitle = localizedString(forKey: "Settings", withDefaultValue: SystemMessage.LabelName.Settings, fileName: localizedStringFileName)
        let settingsAction = UIAlertAction(title: settingsTitle, style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
        alertController.addAction(settingsAction)
        let cancelTitle = localizedString(forKey: "Cancel", withDefaultValue: SystemMessage.LabelName.Cancel, fileName: localizedStringFileName)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .default, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension ALKConversationViewController: CNContactPickerDelegate {
    public func contactPicker(_: CNContactPickerViewController, didSelect contact: CNContact) {
        viewModel.send(contact: contact, metadata: configuration.messageMetadata)
    }
}

extension ALKConversationViewController: ALKConversationViewModelDelegate {
    @objc open func loadingStarted() {
        activityIndicator.startAnimating()
    }

    @objc open func loadingFinished(error _: Error?) {
        activityIndicator.stopAnimating()
        let oldSectionCount = tableView.numberOfSections
        tableView.reloadData()
        let newSectionCount = tableView.numberOfSections
        if newSectionCount > oldSectionCount {
            let offset = newSectionCount - oldSectionCount - 1
            tableView.scrollToRow(at: IndexPath(row: 0, section: offset), at: .none, animated: false)
        }
        print("loading finished")
        DispatchQueue.main.async {
            if self.viewModel.isFirstTime {
                self.tableView.scrollToBottom(animated: false)
                self.viewModel.isFirstTime = false
            }
        }
        guard !viewModel.isOpenGroup else { return }
        viewModel.markConversationRead()
    }

    public func messageUpdated() {
        if activityIndicator.isAnimating {
            activityIndicator.stopAnimating()
        }
        tableView.reloadData()
    }

    public func updateMessageAt(indexPath: IndexPath) {
        DispatchQueue.main.async {
            guard indexPath.section < self.tableView.numberOfSections else {
                print("Message(section) can't be updated due to incorrect index")
                return
            }
            self.tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        }
    }

    // This is a temporary workaround for the issue that messages are not scrolling to bottom when opened from notification
    // This issue is happening because table view has different cells of different heights so it cannot go to the bottom of cell when using function scrollToBottom
    // And thats why when we check whether last cell is visible or not, it gives false result since the last cell is sometimes not fully visible.
    // This is a known apple bug and has a thread in stackoverflow: https://stackoverflow.com/questions/25686490/ios-8-auto-cell-height-cant-scroll-to-last-row
    private func moveTableViewToBottom(indexPath: IndexPath) {
        guard indexPath.section >= 0 else {
            return
        }
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let sectionCount = self.tableView.numberOfSections
            if indexPath.section <= sectionCount {
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
            }
        }
    }

    func updateTableView() {
        let oldCount = tableView.numberOfSections
        let newCount = viewModel.numberOfSections()
        guard newCount >= oldCount else {
            tableView.reloadData()
            print("😱Tableview shouldn't have more number of sections than viewModel😱")
            return
        }
        let indexSet = IndexSet(integersIn: oldCount ..< newCount)

        tableView.beginUpdates()
        tableView.insertSections(indexSet, with: .automatic)
        tableView.endUpdates()
    }

    @objc open func newMessagesAdded() {
        updateTableView()
        // Check if current user is removed from the group
        isChannelLeft()

        if isViewLoadedFromTappingOnNotification {
            let indexPath = IndexPath(row: 0, section: viewModel.messageModels.count - 1)
            if let lastMessage = viewModel.messageModels.last {
                reloadIfFormMessage(message: lastMessage, indexPath: indexPath)
            }
            moveTableViewToBottom(indexPath: indexPath)
            isViewLoadedFromTappingOnNotification = false
        } else {
            if tableView.isCellVisible(section: viewModel.messageModels.count - 2, row: 0) { // 1 for recent added msg and 1 because it starts with 0
                let indexPath = IndexPath(row: 0, section: viewModel.messageModels.count - 1)
                if let lastMessage = viewModel.messageModels.last {
                    reloadIfFormMessage(message: lastMessage, indexPath: indexPath)
                }
                moveTableViewToBottom(indexPath: indexPath)
            } else if viewModel.messageModels.count > 1 { // Check if the function is called before message is added. It happens when user is added in the group.
                unreadScrollButton.isHidden = false
            }
        }
        guard isViewLoaded, view.window != nil, !viewModel.isOpenGroup else {
            return
        }
        viewModel.markConversationRead()
    }

    public func messageSent(at indexPath: IndexPath) {
        NSLog("current indexpath: %i and tableview section %i", indexPath.section, tableView.numberOfSections)
        guard indexPath.section >= tableView.numberOfSections else {
            NSLog("rejected indexpath: %i and tableview and section %i", indexPath.section, tableView.numberOfSections)
            return
        }
        tableView.beginUpdates()
        tableView.insertSections(IndexSet(integer: indexPath.section), with: .automatic)
        tableView.endUpdates()
        moveTableViewToBottom(indexPath: indexPath)
    }

    public func updateDisplay(contact: ALContact?, channel: ALChannel?) {
        let profile = viewModel.conversationProfileFrom(contact: contact, channel: channel)
        navigationBar.updateView(profile: profile)
    }

    // Call this if the last message is not fully visible.
    // This happens when chatbar's header height increases later on.
    public func showLastMessage() {
        if tableView.isCellVisible(section: viewModel.messageModels.count - 2, row: 0) {
            let indexPath = IndexPath(row: 0, section: viewModel.messageModels.count - 1)
            moveTableViewToBottom(indexPath: indexPath)
        }
    }

    func rightNavbarButton() -> UIBarButtonItem? {
        guard !configuration.hideRightNavBarButtonForConversationView else {
            return nil
        }
        var button: UIBarButtonItem

        let notificationSelector = #selector(ALKConversationViewController.sendRightNavBarButtonSelectionNotification(_:))

        var selector = notificationSelector
        if configuration.rightNavBarSystemIconForConversationView == .refresh {
            selector = #selector(ALKConversationViewController.refreshButtonAction(_:))
        }

        button = UIBarButtonItem(
            barButtonSystemItem: configuration.rightNavBarSystemIconForConversationView,
            target: self,
            action: selector
        )
        return button
    }

    func setUpRightNavigationButtons() {
        let navigationItems = configuration.navigationItemsForConversationView
        var rightBarButtonItems: [UIBarButtonItem] = []

        if configuration.isRefreshButtonEnabled, let refreshButton = rightNavbarButton() {
            rightBarButtonItems.append(refreshButton)
        }
        for item in navigationItems {
            let uiBarButtonItem = item.barButton(target: self, action: #selector(customButtonEvent(_:)))

            if let barButtonItem = uiBarButtonItem {
                rightBarButtonItems.append(barButtonItem)
            }
        }
        if !rightBarButtonItems.isEmpty {
            navigationItem.rightBarButtonItems = rightBarButtonItems
        }
    }

    @objc func customButtonEvent(_ sender: AnyObject) {
        guard let identifier = sender.tag else {
            return
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: ALKNavigationItem.NSNotificationForConversationViewNavigationTap), object: self, userInfo: ["identifier": identifier])
    }

    @objc func refreshButtonAction(_: UIBarButtonItem) {
        viewModel.refresh()
    }

    @objc func sendRightNavBarButtonSelectionNotification(_: UIBarButtonItem) {
        let channelId = (viewModel.channelKey != nil) ? String(describing: viewModel.channelKey!) : ""
        let contactId = viewModel.contactId ?? ""
        let info: [String: Any] = ["ChannelId": channelId, "ContactId": contactId, "ConversationVC": self]

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "RightNavBarConversationViewAction"), object: info)
    }

    public func willSendMessage() {
        // Clear reply message and the view
        viewModel.clearSelectedMessageToReply()
        hideReplyMessageView()
    }

    public func updateTyingStatus(status: Bool, userId: String) {
        showTypingLabel(status: status, userId: userId)
    }

    public func clearAndReloadTable() {
        viewModel.clearViewModel()
        tableView.reloadData()
        audioPlayer.stopAudio()
        audioPlayer = ALKAudioPlayer()
    }

    public func updateConversationProfile() {
        navigationItem.titleView = loadingIndicator
        loadingIndicator.startLoading(localizationFileName: configuration.localizedStringFileName)
        viewModel.currentConversationProfile { profile in
            guard let profile = profile else { return }
            self.loadingIndicator.stopLoading()
            self.navigationBar.updateView(profile: profile)
        }
    }
}

extension ALKConversationViewController: ALKCreateGroupChatAddFriendProtocol {
    func createGroupGetFriendInGroupList(friendsSelected _: [ALKFriendViewModel], groupName: String, groupImgUrl: String?, friendsAdded: [ALKFriendViewModel]) {
        if viewModel.isGroup {
            viewModel.updateGroup(groupName: groupName, groupImage: groupImgUrl, friendsAdded: friendsAdded)
            _ = navigationController?.popToViewController(self, animated: true)
        }
    }
}

extension ALKConversationViewController: ALKShareLocationViewControllerDelegate {
    func locationDidSelected(geocode: Geocode, image _: UIImage) {
        let (message, indexPath) = viewModel.add(geocode: geocode, metadata: configuration.messageMetadata)
        guard let newMessage = message, let newIndexPath = indexPath else {
            return
        }
        tableView.beginUpdates()
        tableView.insertSections(IndexSet(integer: newIndexPath.section), with: .automatic)
        tableView.endUpdates()

        // Not scrolling down without the delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.tableView.scrollToBottom(animated: false)
        }
        viewModel.sendGeocode(message: newMessage, indexPath: newIndexPath)
    }
}

extension ALKConversationViewController: ALKLocationCellDelegate {
    func displayLocation(location: ALKLocationPreviewViewModel) {
        let latLonString = String(format: "%f,%f", location.coordinate.latitude, location.coordinate.longitude)
        let locationString = String(format: "https://maps.google.com/maps?q=%@", latLonString)
        guard let locationUrl = URL(string: locationString) else { return }
        UIApplication.shared.open(locationUrl)
    }
}

extension ALKConversationViewController: ALKAudioPlayerProtocol, ALKVoiceCellProtocol {
    func reloadVoiceCell() {
        for cell in tableView.visibleCells {
            guard let indexPath = tableView.indexPath(for: cell) else { return }
            if let message = viewModel.messageForRow(indexPath: indexPath) {
                if message.messageType == .voice, message.identifier == audioPlayer.getCurrentAudioTrack() {
                    print("voice cell reloaded with row: ", indexPath.row, indexPath.section)
                    tableView.reloadSections([indexPath.section], with: .none)
                    break
                }
            }
        }
    }

    // MAKR: Voice and Audio Delegate
    func playAudioPress(identifier: String) {
        DispatchQueue.main.async { [weak self] in
            NSLog("play audio pressed")
            guard let weakSelf = self else { return }

            // if we have previously play audio, stop it first
            if !weakSelf.audioPlayer.getCurrentAudioTrack().isEmpty, weakSelf.audioPlayer.getCurrentAudioTrack() != identifier {
                // pause
                NSLog("already playing, change it to pause")
                guard var lastMessage = weakSelf.viewModel.messageForRow(identifier: weakSelf.audioPlayer.getCurrentAudioTrack()) else { return }

                if Int(lastMessage.voiceCurrentDuration) > 0 {
                    lastMessage.voiceCurrentState = .pause
                    lastMessage.voiceCurrentDuration = weakSelf.audioPlayer.secLeft
                } else {
                    let lastMessageCopy = lastMessage
                    lastMessage.voiceCurrentDuration = lastMessageCopy.voiceTotalDuration
                    lastMessage.voiceCurrentState = .stop
                }
                weakSelf.audioPlayer.pauseAudio()
            }
            NSLog("now it will be played")
            // now play
            guard
                var currentVoice = weakSelf.viewModel.messageForRow(identifier: identifier),
                let section = weakSelf.viewModel.sectionFor(identifier: identifier)
            else { return }
            if currentVoice.voiceCurrentState == .playing {
                currentVoice.voiceCurrentState = .pause
                currentVoice.voiceCurrentDuration = weakSelf.audioPlayer.secLeft
                weakSelf.audioPlayer.pauseAudio()
                weakSelf.tableView.reloadSections([section], with: .none)
            } else {
                NSLog("reset time to total duration")
                // reset time to total duration
                if currentVoice.voiceCurrentState == .stop || currentVoice.voiceCurrentDuration < 1 {
                    let currentVoiceCopy = currentVoice
                    currentVoice.voiceCurrentDuration = currentVoiceCopy.voiceTotalDuration
                }

                if let data = currentVoice.voiceData {
                    let voice = data as NSData
                    // start playing
                    NSLog("Start playing")
                    weakSelf.audioPlayer.setAudioFile(data: voice, delegate: weakSelf, playFrom: currentVoice.voiceCurrentDuration, lastPlayTrack: currentVoice.identifier)
                    currentVoice.voiceCurrentState = .playing
                    weakSelf.tableView.reloadSections([section], with: .none)
                }
            }
        }
    }

    func audioPlaying(maxDuratation _: CGFloat, atSec: CGFloat, lastPlayTrack: String) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            guard var currentVoice = weakSelf.viewModel.messageForRow(identifier: lastPlayTrack) else { return }
            if currentVoice.messageType == .voice {
                if currentVoice.identifier == lastPlayTrack {
                    if atSec <= 0 {
                        currentVoice.voiceCurrentState = .stop
                        currentVoice.voiceCurrentDuration = 0
                    } else {
                        currentVoice.voiceCurrentState = .playing
                        currentVoice.voiceCurrentDuration = atSec
                    }
                }
                print("audio playing id: ", currentVoice.identifier)
                weakSelf.reloadVoiceCell()
            }
        }
    }

    func audioStop(maxDuratation _: CGFloat, lastPlayTrack: String) {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }

            guard var currentVoice = weakSelf.viewModel.messageForRow(identifier: lastPlayTrack) else { return }
            if currentVoice.messageType == .voice {
                if currentVoice.identifier == lastPlayTrack {
                    currentVoice.voiceCurrentState = .stop
                    currentVoice.voiceCurrentDuration = 0.0
                }
            }
            guard let section = weakSelf.viewModel.sectionFor(identifier: lastPlayTrack) else { return }
            weakSelf.tableView.reloadSections([section], with: .none)
        }
    }

    func audioPause(maxDuration _: CGFloat, atSec: CGFloat, identifier: String) {
        DispatchQueue.main.async { [weak self] in
            guard
                let weakSelf = self,
                var currentVoice = weakSelf.viewModel.messageForRow(identifier: identifier),
                currentVoice.messageType == .voice,
                let section = weakSelf.viewModel.sectionFor(identifier: identifier)
            else { return }
            currentVoice.voiceCurrentState = .pause
            currentVoice.voiceCurrentDuration = atSec
            weakSelf.tableView.reloadSections([section], with: .none)
        }
    }

    func stopAudioPlayer() {
        DispatchQueue.main.async { [weak self] in
            guard let weakSelf = self else { return }
            if var lastMessage = weakSelf.viewModel.messageForRow(identifier: weakSelf.audioPlayer.getCurrentAudioTrack()) {
                if lastMessage.voiceCurrentState == .playing {
                    weakSelf.audioPlayer.pauseAudio()
                    lastMessage.voiceCurrentState = .pause
                    weakSelf.reloadVoiceCell()
                }
            }
        }
    }
}

extension ALKConversationViewController: ALMQTTConversationDelegate {
    public func mqttDidConnected() {
        if individualLaunch {
            subscribeChannelToMqtt()
        }
    }

    public func syncCall(_ alMessage: ALMessage!, andMessageList _: NSMutableArray!) {
        guard let message = alMessage else { return }
        sync(message: message)
    }

    public func delivered(_ messageKey: String!, contactId: String!, withStatus status: Int32) {
        updateDeliveryReport(messageKey: messageKey, contactId: contactId, status: status)
    }

    public func updateStatus(forContact contactId: String!, withStatus status: Int32) {
        updateStatusReport(contactId: contactId, status: status)
    }

    public func updateTypingStatus(_: String!, userId: String!, status: Bool) {
        print("Typing status is", status)
        guard viewModel.contactId == userId || viewModel.channelKey != nil else {
            return
        }
        print("Contact id matched")
        showTypingLabel(status: status, userId: userId)
    }

    public func updateLastSeen(atStatus alUserDetail: ALUserDetail!) {
        print("Last seen updated")
        guard let contact = contactService.loadContact(byKey: "userId", value: alUserDetail.userId) else {
            return
        }
        guard contact.userId == viewModel.contactId, !viewModel.isGroup else { return }
        navigationBar.updateStatus(isOnline: contact.connected, lastSeenAt: contact.lastSeenAt)
    }

    public func mqttConnectionClosed() {
        if viewModel.isOpenGroup, mqttRetryCount < maxMqttRetryCount {
            subscribeChannelToMqtt()
        }
        print("ALKConversationVC mqtt connection closed.")
        alMqttConversationService.retryConnection()
    }

    public func reloadData(forUserBlockNotification _: String!, andBlockFlag _: Bool) {
        print("reload data")
        checkUserBlock()
    }

    public func updateUserDetail(_ userId: String!) {
        guard let userId = userId else { return }
        print("update user detail")
        viewModel.updateUserDetail(userId)
    }
}

extension ALKConversationViewController: ALKCustomPickerDelegate {
    func filesSelected(images: [UIImage], videos: [String]) {
        let fileCount = images.count + videos.count
        for index in 0 ..< fileCount {
            if index < images.count {
                let image = images[index]
                let (message, indexPath) = viewModel.send(
                    photo: image,
                    metadata: configuration.messageMetadata
                )
                guard message != nil, let newIndexPath = indexPath else { return }
                //            DispatchQueue.main.async {
                tableView.beginUpdates()
                tableView.insertSections(IndexSet(integer: newIndexPath.section), with: .automatic)
                tableView.endUpdates()
                tableView.scrollToBottom(animated: false)
                //            }
                guard let cell = tableView.cellForRow(at: newIndexPath) as? ALKMyPhotoPortalCell else { return }
                guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                    let notificationView = ALNotificationView()
                    notificationView.noDataConnectionNotificationView()
                    return
                }
                viewModel.uploadImage(view: cell, indexPath: newIndexPath)
            } else {
                let path = videos[index - images.count]
                guard let indexPath = viewModel.sendVideo(
                    atPath: path,
                    sourceType: .photoLibrary,
                    metadata: configuration.messageMetadata
                ).1
                else { continue }
                tableView.beginUpdates()
                tableView.insertSections(IndexSet(integer: indexPath.section), with: .automatic)
                tableView.endUpdates()
                tableView.scrollToBottom(animated: false)
                guard let cell = tableView.cellForRow(at: indexPath) as? ALKMyVideoCell else { return }
                guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                    let notificationView = ALNotificationView()
                    notificationView.noDataConnectionNotificationView()
                    return
                }
                viewModel.uploadVideo(view: cell, indexPath: indexPath)
            }
        }
    }
}
