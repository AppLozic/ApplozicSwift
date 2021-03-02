//
//  ALKConversationViewModel.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import AVFoundation
import Contacts
import Foundation
import MobileCoreServices

public protocol ALKConversationViewModelDelegate: AnyObject {
    func loadingStarted()
    func loadingFinished(error: Error?)
    func messageUpdated()
    func updateMessageAt(indexPath: IndexPath)
    func newMessagesAdded()
    func messageSent(at: IndexPath)
    func updateDisplay(contact: ALContact?, channel: ALChannel?)
    func willSendMessage()
    func updateTyingStatus(status: Bool, userId: String)
}

// swiftlint:disable:next type_body_length
open class ALKConversationViewModel: NSObject, Localizable {
    fileprivate var localizedStringFileName: String!

    // MARK: - Inputs

    open var contactId: String? {
        didSet {
            if contactId != nil {
                chatId = contactId
            }
        }
    }

    open var channelKey: NSNumber? {
        didSet {
            if channelKey != nil {
                chatId = channelKey?.stringValue
            }
        }
    }

    open var isSearch: Bool = false

    // For topic based chat
    open var conversationProxy: ALConversationProxy? {
        didSet {
            if conversationProxy != nil {
                chatId = conversationProxy?.id?.stringValue
            }
        }
    }

    public weak var delegate: ALKConversationViewModelDelegate?

    // MARK: - Outputs

    open var isFirstTime = true

    open var isGroup: Bool {
        guard channelKey != nil else {
            return false
        }
        return true
    }

    // Prefilled message for chatbox.
    open var prefilledMessage: String?

    open var isContextBasedChat: Bool {
        guard conversationProxy == nil else { return true }
        guard
            let channelKey = channelKey,
            let alChannel = ALChannelService().getChannelByKey(channelKey),
            let metadata = alChannel.metadata,
            let contextBased = metadata["AL_CONTEXT_BASED_CHAT"] as? String
        else {
            return false
        }
        return contextBased.lowercased() == "true"
    }

    open var messageModels: [ALKMessageModel] = []

    open var richMessages: [String: Any] = [:]

    open var isOpenGroup: Bool {
        let alChannelService = ALChannelService()
        guard let channelKey = channelKey,
              let alchannel = alChannelService.getChannelByKey(channelKey)
        else {
            return false
        }
        return alchannel.type == 6
    }

    private var conversationId: NSNumber? {
        return conversationProxy?.id
    }

    private lazy var chatId: String? = conversationId?.stringValue ?? channelKey?.stringValue ?? contactId

    private let maxWidth = UIScreen.main.bounds.width
    private var alMessageWrapper = ALMessageArrayWrapper()

    private var alMessages: [ALMessage] = []

    private let mqttObject = ALMQTTConversationService.sharedInstance()

    /// Message on which reply was tapped.
    private var selectedMessageForReply: ALKMessageViewModel?

    private var shouldSendTyping: Bool = true

    private var typingTimerTask = Timer()
    private var groupMembers: Set<ALContact>?

    // MARK: - Initializer

    public required init(
        contactId: String?,
        channelKey: NSNumber?,
        conversationProxy: ALConversationProxy? = nil,
        localizedStringFileName: String!,
        prefilledMessage: String? = nil
    ) {
        self.contactId = contactId
        self.channelKey = channelKey
        self.conversationProxy = conversationProxy
        self.localizedStringFileName = localizedStringFileName
        self.prefilledMessage = prefilledMessage
    }

    // MARK: - Public methods

    public func prepareController() {
        if isSearch {
            delegate?.loadingStarted()
            loadSearchMessages()
            return
        }
        // Load messages from server in case of open group
        guard !isOpenGroup else {
            delegate?.loadingStarted()
            loadOpenGroupMessages()
            return
        }

        if ALUserDefaultsHandler.isServerCallDone(forMSGList: chatId) {
            delegate?.loadingStarted()
            loadMessagesFromDB()
        } else {
            delegate?.loadingStarted()
            loadMessages()
        }
    }

    public func addToWrapper(message: ALMessage) {
        guard !alMessageWrapper.contains(message: message) else { return }
        alMessageWrapper.addALMessage(toMessageArray: message)
        alMessages.append(message)
        messageModels.append(message.messageModel)
    }

    func clearViewModel() {
        isFirstTime = true
        messageModels.removeAll()
        alMessages.removeAll()
        richMessages.removeAll()
        alMessageWrapper = ALMessageArrayWrapper()
        groupMembers = nil
    }

    open func groupProfileImgUrl() -> String {
        guard let message = alMessages.last, let imageUrl = message.avatarGroupImageUrl else {
            return ""
        }
        return imageUrl
    }

    open func groupName() -> String {
        guard let message = alMessages.last else {
            return ""
        }
        _ = alMessages.first?.createdAt
        return message.groupName
    }

    open func groupKey() -> NSNumber? {
        guard let message = alMessages.last else {
            return nil
        }
        return message.groupId
    }

    open func friends() -> [ALKFriendViewModel] {
        let alChannelService = ALChannelService()

        // TODO: This is a workaround as other method uses closure.
        // Later replace this with:
        // alChannelService.getChannelInformation(, orClientChannelKey: , withCompletion: )
        guard let message = alMessages.last, let alChannel = alChannelService.getChannelByKey(message.groupId) else {
            return []
        }

        guard let members = alChannel.membersId else { return [] }
        let membersId = members.map { ($0 as? String) }
        let alContactDbService = ALContactDBService()
        let alContacts = membersId.map { alContactDbService.loadContact(byKey: "userId", value: $0) }
        let models = alContacts.filter { $0?.userId != ALUserDefaultsHandler.getUserId() }.map { ALKFriendViewModel(identity: $0!) }
        print("all models: ", models.count)
        return models
    }

    open func numberOfSections() -> Int {
        return messageModels.count
    }

    open func numberOfRows(section _: Int) -> Int {
        return 1
    }

    open func messageForRow(indexPath: IndexPath) -> ALKMessageViewModel? {
        guard indexPath.section < messageModels.count, indexPath.section >= 0 else { return nil }
        return messageModels[indexPath.section]
    }

    open func quickReplyDictionary(message: ALKMessageViewModel?, indexRow row: Int) -> [String: Any]? {
        guard let metadata = message?.metadata else {
            return [String: Any]()
        }

        let payload = metadata["payload"] as? String

        let data = payload?.data
        var jsonArray: [[String: Any]]?

        do {
            jsonArray = (try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [[String: Any]])
            return jsonArray?[row]
        } catch let error as NSError {
            print(error)
        }
        return [String: Any]()
    }

    open func getSizeForItemAt(row _: Int, withData: [String: Any]) -> CGSize {
        let size = (withData["title"] as? String)?.size(withAttributes: [NSAttributedString.Key.font: Font.normal(size: 14.0).font()])
        let newSize = CGSize(width: (size?.width)! + 46.0, height: 50.0)
        return newSize
    }

    open func messageForRow(identifier: String) -> ALKMessageViewModel? {
        guard let messageModel = messageModels.filter({ $0.identifier == identifier }).first else { return nil }
        return messageModel
    }

    func sectionFor(identifier: String) -> Int? {
        return messageModels.firstIndex { $0.identifier == identifier }
    }

    open func heightForRow(indexPath: IndexPath, cellFrame _: CGRect, configuration: ALKConfiguration) -> CGFloat {
        let messageModel = messageModels[indexPath.section]
        let cacheIdentifier = (messageModel.isMyMessage ? "s-" : "r-") + messageModel.identifier
        if let height = HeightCache.shared.getHeight(for: cacheIdentifier) {
            return height
        }
        switch messageModel.messageType {
        case .text, .html, .email:
            guard !configuration.isLinkPreviewDisabled, messageModel.messageType == .text, ALKLinkPreviewManager.extractURLAndAddInCache(from: messageModel.message, identifier: messageModel.identifier) != nil else {
                if messageModel.isMyMessage {
                    let height = ALKMyMessageCell.rowHeigh(viewModel: messageModel, width: maxWidth, displayNames: { userIds in
                        self.displayNames(ofUserIds: userIds)
                    })
                    return height.cached(with: cacheIdentifier)
                } else {
                    let height = ALKFriendMessageCell.rowHeigh(viewModel: messageModel, width: maxWidth, displayNames: { userIds in
                        self.displayNames(ofUserIds: userIds)
                    })
                    return height.cached(with: cacheIdentifier)
                }
            }
            if messageModel.isMyMessage {
                let height = ALKMyLinkPreviewCell.rowHeigh(viewModel: messageModel, width: maxWidth, displayNames: { userIds in
                    self.displayNames(ofUserIds: userIds)
                })
                return height.cached(with: cacheIdentifier)
            } else {
                let height = ALKFriendLinkPreviewCell.rowHeigh(viewModel: messageModel, width: maxWidth, displayNames: { userIds in
                    self.displayNames(ofUserIds: userIds)
                })
                return height.cached(with: cacheIdentifier)
            }

        case .photo:
            if messageModel.isMyMessage {
                if messageModel.ratio < 1 {
                    let heigh = ALKMyPhotoPortalCell.rowHeigh(viewModel: messageModel, width: maxWidth)
                    return heigh.cached(with: cacheIdentifier)
                } else {
                    let heigh = ALKMyPhotoLandscapeCell.rowHeigh(viewModel: messageModel, width: maxWidth)
                    return heigh.cached(with: cacheIdentifier)
                }
            } else {
                if messageModel.ratio < 1 {
                    let heigh = ALKFriendPhotoPortalCell.rowHeigh(viewModel: messageModel, width: maxWidth)
                    return heigh.cached(with: cacheIdentifier)
                } else {
                    let heigh = ALKFriendPhotoLandscapeCell.rowHeigh(viewModel: messageModel, width: maxWidth)
                    return heigh.cached(with: cacheIdentifier)
                }
            }
        case .voice:
            var height: CGFloat = 0
            if messageModel.isMyMessage {
                height = ALKVoiceCell.rowHeigh(viewModel: messageModel, width: maxWidth)
            } else {
                height = ALKFriendVoiceCell.rowHeigh(viewModel: messageModel, width: maxWidth)
            }
            return height.cached(with: cacheIdentifier)
        case .information:
            let height = ALKInformationCell.rowHeigh(viewModel: messageModel, width: maxWidth)
            return height.cached(with: cacheIdentifier)
        case .location:
            return (messageModel.isMyMessage ? ALKMyLocationCell.rowHeigh(viewModel: messageModel, width: maxWidth).cached(with: cacheIdentifier) : ALKFriendLocationCell.rowHeigh(viewModel: messageModel, width: maxWidth)).cached(with: cacheIdentifier)
        case .video:
            var height: CGFloat = 0
            if messageModel.isMyMessage {
                height = ALKMyVideoCell.rowHeigh(viewModel: messageModel, width: maxWidth)
            } else {
                height = ALKFriendVideoCell.rowHeigh(viewModel: messageModel, width: maxWidth)
            }
            return height.cached(with: cacheIdentifier)
        case .cardTemplate:
            if messageModel.isMyMessage {
                return
                    ALKMyGenericCardMessageCell
                        .rowHeigh(viewModel: messageModel, width: maxWidth)
                        .cached(with: cacheIdentifier)
            } else {
                return
                    ALKFriendGenericCardMessageCell
                        .rowHeigh(viewModel: messageModel, width: maxWidth)
                        .cached(with: cacheIdentifier)
            }
        case .faqTemplate:
            guard let faqMessage = messageModel.faqMessage() else { return 0 }
            if messageModel.isMyMessage {
                return SentFAQMessageCell.rowHeight(model: faqMessage).cached(with: cacheIdentifier)
            } else {
                return ReceivedFAQMessageCell.rowHeight(model: faqMessage).cached(with: cacheIdentifier)
            }

        case .quickReply:
            if messageModel.isMyMessage {
                return
                    ALKMyMessageQuickReplyCell
                        .rowHeight(viewModel: messageModel, maxWidth: UIScreen.main.bounds.width)
                        .cached(with: cacheIdentifier)
            } else {
                return
                    ALKFriendMessageQuickReplyCell
                        .rowHeight(viewModel: messageModel, maxWidth: UIScreen.main.bounds.width)
                        .cached(with: cacheIdentifier)
            }
        case .button:
            if messageModel.isMyMessage {
                return
                    ALKMyMessageButtonCell
                        .rowHeigh(viewModel: messageModel, width: UIScreen.main.bounds.width)
                        .cached(with: cacheIdentifier)
            } else {
                return
                    ALKFriendMessageButtonCell
                        .rowHeigh(viewModel: messageModel, width: UIScreen.main.bounds.width)
                        .cached(with: cacheIdentifier)
            }
        case .listTemplate:
            if messageModel.isMyMessage {
                return
                    ALKMyMessageListTemplateCell
                        .rowHeight(viewModel: messageModel, maxWidth: UIScreen.main.bounds.width)
                        .cached(with: cacheIdentifier)
            } else {
                return
                    ALKFriendMessageListTemplateCell
                        .rowHeight(viewModel: messageModel, maxWidth: UIScreen.main.bounds.width)
                        .cached(with: cacheIdentifier)
            }
        case .document:
            if messageModel.isMyMessage {
                return
                    ALKMyDocumentCell
                        .rowHeigh(viewModel: messageModel, width: maxWidth)
                        .cached(with: cacheIdentifier)
            } else {
                return
                    ALKFriendDocumentCell
                        .rowHeigh(viewModel: messageModel, width: maxWidth)
                        .cached(with: cacheIdentifier)
            }
        case .contact:
            if messageModel.isMyMessage {
                return
                    ALKMyContactMessageCell
                        .rowHeight()
                        .cached(with: cacheIdentifier)
            } else {
                return
                    ALKFriendContactMessageCell
                        .rowHeight()
                        .cached(with: cacheIdentifier)
            }
        case .imageMessage:
            guard let imageMessage = messageModel.imageMessage() else { return 0 }
            if messageModel.isMyMessage {
                return
                    SentImageMessageCell
                        .rowHeight(model: imageMessage)
                        .cached(with: cacheIdentifier)
            } else {
                return
                    ReceivedImageMessageCell
                        .rowHeight(model: imageMessage)
                        .cached(with: cacheIdentifier)
            }
        case .allButtons:
            guard let model = messageModel.allButtons() else { return 0 }
            if messageModel.isMyMessage {
                return
                    SentButtonsCell
                        .rowHeight(model: model)
                        .cached(with: cacheIdentifier)
            } else {
                return
                    ReceivedButtonsCell
                        .rowHeight(model: model)
                        .cached(with: cacheIdentifier)
            }
        case .form:
            return 0
        }
    }

    open func nextPage() {
        if isSearch {
            loadSearchMessages()
            return
        }
        guard !isOpenGroup else {
            loadOpenGroupMessages()
            return
        }
        guard ALUserDefaultsHandler.isShowLoadEarlierOption(chatId), ALUserDefaultsHandler.isServerCallDone(forMSGList: chatId) else {
            return
        }
        loadEarlierMessages()
    }

    open func getContextTitleData() -> ALKContextTitleDataType? {
        guard isContextBasedChat else { return nil }
        if let proxy = conversationProxy, let topicDetail = proxy.getTopicDetail() {
            return topicDetail
        } else {
            guard let metadata = ALChannelService().getChannelByKey(channelKey)?.metadata else { return nil }
            let topicDetail = ALTopicDetail()
            topicDetail.title = metadata["title"] as? String
            topicDetail.subtitle = metadata["price"] as? String
            topicDetail.link = metadata["link"] as? String
            return topicDetail
        }
    }

    open func getMessageTemplates() -> [ALKTemplateMessageModel]? {
        // Get the json from the root folder, parse it and map it.
        let bundle = Bundle.main
        guard let jsonPath = bundle.path(forResource: "message_template", ofType: "json")
        else {
            return nil
        }
        do {
            let fileUrl = URL(fileURLWithPath: jsonPath)
            let data = try Data(contentsOf: fileUrl, options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            if let json = jsonResult as? [String: Any],
               let templates = json["templates"] as? [Any]
            {
                NSLog("Template json: ", json.description)
                var templateModels: [ALKTemplateMessageModel] = []
                for element in templates {
                    if let template = element as? [String: Any],
                       let model = ALKTemplateMessageModel(json: template)
                    {
                        templateModels.append(model)
                    }
                }
                return templateModels
            }
        } catch {
            NSLog("Error while fetching template json: \(error.localizedDescription)")
            return nil
        }
        return nil
    }

    open func downloadAttachment(message: ALKMessageViewModel, view: UIView) {
        guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
            let notificationView = ALNotificationView()
            notificationView.noDataConnectionNotificationView()
            return
        }
        // if ALApplozicSettings.isS3StorageServiceEnabled or ALApplozicSettings.isGoogleCloudServiceEnabled is true its private url we wont be able to download it directly.
        let serviceEnabled = ALApplozicSettings.isS3StorageServiceEnabled() || ALApplozicSettings.isGoogleCloudServiceEnabled()

        if let url = message.fileMetaInfo?.url,
           !serviceEnabled
        {
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = view as? ALKHTTPManagerDownloadDelegate
            let task = ALKDownloadTask(downloadUrl: url, fileName: message.fileMetaInfo?.name)
            task.identifier = message.identifier
            task.totalBytesExpectedToDownload = message.size
            httpManager.downloadImage(task: task)
            httpManager.downloadCompleted = { [weak self] task in
                guard let weakSelf = self, let identifier = task.identifier else { return }
                var msg = weakSelf.messageForRow(identifier: identifier)
                if ThumbnailIdentifier.hasPrefix(in: identifier) {
                    msg?.fileMetaInfo?.thumbnailFilePath = task.filePath
                } else {
                    msg?.filePath = task.filePath
                }
            }
            return
        }
        ALMessageClientService().downloadImageUrl(message.fileMetaInfo?.blobKey) { fileUrl, error in
            guard error == nil, let fileUrl = fileUrl else {
                print("Error downloading attachment :: \(String(describing: error))")
                return
            }
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = view as? ALKHTTPManagerDownloadDelegate
            let task = ALKDownloadTask(downloadUrl: fileUrl, fileName: message.fileMetaInfo?.name)
            task.identifier = message.identifier
            task.totalBytesExpectedToDownload = message.size
            httpManager.downloadAttachment(task: task)
            httpManager.downloadCompleted = { [weak self] task in
                guard let weakSelf = self, let identifier = task.identifier else { return }
                var msg = weakSelf.messageForRow(identifier: identifier)
                if ThumbnailIdentifier.hasPrefix(in: identifier) {
                    msg?.fileMetaInfo?.thumbnailFilePath = task.filePath
                } else {
                    msg?.filePath = task.filePath
                }
            }
        }
    }

    /// Received from notification
    open func addMessagesToList(_ messageList: [Any]) {
        guard let messages = messageList as? [ALMessage] else { return }

        var filteredArray = [ALMessage]()

        for message in messages {
            if channelKey != nil, channelKey == message.groupId {
                filteredArray.append(message)
                delegate?.updateTyingStatus(status: false, userId: message.to)
            } else if message.channelKey == nil, channelKey == nil, contactId == message.to {
                filteredArray.append(message)
                delegate?.updateTyingStatus(status: false, userId: message.to)
            }
        }

        var sortedArray = filteredArray.filter {
            !alMessageWrapper.contains(message: $0)
        }
        if sortedArray.count > 1 {
            sortedArray.sort { Int(truncating: $0.createdAtTime) < Int(truncating: $1.createdAtTime) }
        }
        guard !sortedArray.isEmpty else { return }

        _ = sortedArray.map { self.alMessageWrapper.addALMessage(toMessageArray: $0) }
        alMessages.append(contentsOf: sortedArray)
        let models = sortedArray.map { $0.messageModel }
        messageModels.append(contentsOf: models)
        //        print("new messages: ", models.map { $0.message })
        delegate?.newMessagesAdded()
    }

    open func markConversationRead() {
        if let channelKey = channelKey {
            print("mark read1")
            ALChannelService.sharedInstance().markConversation(asRead: channelKey, withCompletion: {
                _, error in
                print("mark read")
                if let error = error {
                    NSLog("error while marking conversation read: \(error)")
                }
            })
        } else if let contactId = contactId {
            ALUserService.sharedInstance().markConversation(asRead: contactId, withCompletion: {
                _, error in
                if let error = error {
                    NSLog("error while marking conversation read: \(error)")
                }
            })
        }
    }

    open func updateGroup(groupName: String, groupImage: String?, friendsAdded: [ALKFriendViewModel]) {
        if !groupName.isEmpty || groupImage != nil {
            updateGroupInfo(groupName: groupName, groupImage: groupImage, completion: { success in
                self.updateInfo()
                guard success, !friendsAdded.isEmpty else { return }
                self.addMembersToGroup(users: friendsAdded, completion: { _ in
                    print("group addition was succesful")
                })
            })
        } else {
            updateInfo()
            guard !friendsAdded.isEmpty else { return }
            addMembersToGroup(users: friendsAdded, completion: { _ in
                print("group addition was succesful")
            })
        }
    }

    open func updateDeliveryReport(messageKey: String, status: Int32) {
        let mesgArray = alMessages
        guard !mesgArray.isEmpty else { return }
        let filteredList = mesgArray.filter { ($0.key != nil) ? $0.key == messageKey : false }
        if !filteredList.isEmpty {
            updateMessageStatus(filteredList: filteredList, status: status)
        } else {
            guard let mesgFromService = ALMessageService
                .getMessagefromKeyValuePair("key", andValue: messageKey),
                let objectId = mesgFromService.msgDBObjectId else { return }
            let newFilteredList = mesgArray
                .filter { ($0.msgDBObjectId != nil) ? $0.msgDBObjectId == objectId : false }
            updateMessageStatus(filteredList: newFilteredList, status: status)
        }
    }

    open func updateStatusReportForConversation(contactId: String, status: Int32) {
        guard let id = self.contactId, id == contactId else { return }
        let mesgArray = alMessages
        guard !mesgArray.isEmpty else { return }
        for index in 0 ..< mesgArray.count {
            let mesg = mesgArray[index]
            if mesg.status != nil, mesg.status != NSNumber(value: status), mesg.sentToServer == true {
                mesg.status = status as NSNumber
                alMessages[index] = mesg
                messageModels[index] = mesg.messageModel
                delegate?.updateMessageAt(indexPath: IndexPath(row: 0, section: index))
            }
            guard index < messageModels.count else { return }
        }
    }

    open func updateSendStatus(message: ALMessage) {
        let filteredList = alMessages.filter { $0 == message }
        if let alMessage = filteredList.first, let index = alMessages.firstIndex(of: alMessage) {
            alMessage.sentToServer = true
            alMessages[index] = alMessage
            messageModels[index] = alMessage.messageModel
            delegate?.updateMessageAt(indexPath: IndexPath(row: 0, section: index))
        } else {
            loadMessagesFromDB()
        }
    }

    open func send(message: String, isOpenGroup: Bool = false, metadata: [AnyHashable: Any]?) {
        let alMessage = getMessageToPost(isTextMessage: true)
        alMessage.message = message
        alMessage.metadata = modfiedMessageMetadata(alMessage: alMessage, metadata: metadata)

        addToWrapper(message: alMessage)
        let indexPath = IndexPath(row: 0, section: messageModels.count - 1)
        delegate?.messageSent(at: indexPath)
        if isOpenGroup {
            let messageClientService = ALMessageClientService()
            messageClientService.sendMessage(alMessage.dictionary(), withCompletionHandler: { _, error in
                guard error == nil, indexPath.section < self.messageModels.count else { return }
                NSLog("No errors while sending the message in open group")
                alMessage.status = NSNumber(integerLiteral: Int(SENT.rawValue))
                self.messageModels[indexPath.section] = alMessage.messageModel
                self.delegate?.updateMessageAt(indexPath: indexPath)
                return
            })
        } else {
            ALMessageService.sharedInstance().sendMessages(alMessage, withCompletion: { _, error in
                NSLog("Message sent section: \(indexPath.section), \(String(describing: alMessage.message))")
                guard error == nil, indexPath.section < self.messageModels.count else { return }
                NSLog("No errors while sending the message")
                alMessage.status = NSNumber(integerLiteral: Int(SENT.rawValue))
                self.messageModels[indexPath.section] = alMessage.messageModel
                self.delegate?.updateMessageAt(indexPath: indexPath)
            })
        }
    }

    func modfiedMessageMetadata(alMessage: ALMessage, metadata: [AnyHashable: Any]?) -> NSMutableDictionary {
        var metaData = NSMutableDictionary()

        if alMessage.metadata != nil {
            metaData = alMessage.metadata
        }

        if let messageMetadata = metadata, !messageMetadata.isEmpty {
            metaData.addEntries(from: messageMetadata)
        }
        for (key, value) in metaData {
            guard let value = value as? [AnyHashable: Any] else { continue }
            metaData[key] = ALUtilityClass.generateJsonString(from: value)
        }
        return metaData
    }

    open func send(photo: UIImage, metadata: [AnyHashable: Any]?) -> (ALMessage?, IndexPath?) {
        print("image is:  ", photo)
        let filePath = ALKFileUtils().saveImageToDocDirectory(image: photo)
        print("filepath:: \(String(describing: filePath))")
        guard let path = filePath, let url = URL(string: path) else { return (nil, nil) }
        guard let alMessage = processAttachment(
            filePath: url,
            text: "",
            contentType: Int(ALMESSAGE_CONTENT_ATTACHMENT),
            metadata: metadata
        ) else {
            return (nil, nil)
        }
        addToWrapper(message: alMessage)
        return (alMessage, IndexPath(row: 0, section: messageModels.count - 1))
    }

    open func send(contact: CNContact, metadata: [AnyHashable: Any]?) {
        guard
            let path = ALKFileUtils().saveContact(toDocDirectory: contact),
            let url = URL(string: path)
        else {
            print("Error while saving contact")
            return
        }
        guard let alMessage = processAttachment(
            filePath: url,
            text: "",
            contentType: Int(ALMESSAGE_CONTENT_VCARD),
            metadata: metadata
        ) else { return }
        addToWrapper(message: alMessage)
        delegate?.messageSent(at: IndexPath(row: 0, section: messageModels.count - 1))
        uploadAudio(alMessage: alMessage, indexPath: IndexPath(row: 0, section: messageModels.count - 1))
    }

    open func send(voiceMessage: Data, metadata: [AnyHashable: Any]?) {
        print("voice data received: ", voiceMessage.count)
        let fileName = String(format: "AUD-%f.m4a", Date().timeIntervalSince1970 * 1000)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fullPath = documentsURL.appendingPathComponent(fileName)
        do {
            try voiceMessage.write(to: fullPath, options: .atomic)
        } catch {
            NSLog("error when saving the voice message")
        }
        guard let alMessage = processAttachment(
            filePath: fullPath,
            text: "",
            contentType: Int(ALMESSAGE_CONTENT_AUDIO),
            metadata: metadata
        ) else { return }
        addToWrapper(message: alMessage)
        delegate?.messageSent(at: IndexPath(row: 0, section: messageModels.count - 1))
        uploadAudio(alMessage: alMessage, indexPath: IndexPath(row: 0, section: messageModels.count - 1))
    }

    open func add(geocode: Geocode, metadata: [AnyHashable: Any]?) -> (ALMessage?, IndexPath?) {
        let latlonString = ["lat": "\(geocode.location.latitude)", "lon": "\(geocode.location.longitude)"]
        guard let jsonString = createJson(dict: latlonString) else { return (nil, nil) }
        let message = getLocationMessage(latLonString: jsonString)
        message.metadata = modfiedMessageMetadata(alMessage: message, metadata: metadata)
        addToWrapper(message: message)
        let indexPath = IndexPath(row: 0, section: messageModels.count - 1)
        return (message, indexPath)
    }

    open func sendGeocode(message: ALMessage, indexPath: IndexPath) {
        send(alMessage: message) { updatedMessage in
            guard let mesg = updatedMessage else { return }
            DispatchQueue.main.async {
                print("UI updated at section: ", indexPath.section, message.isSent)
                message.status = NSNumber(integerLiteral: Int(SENT.rawValue))
                self.alMessages[indexPath.section] = mesg
                self.messageModels[indexPath.section] = mesg.messageModel
                self.delegate?.updateMessageAt(indexPath: indexPath)
            }
        }
    }

    open func sendVideo(atPath path: String, sourceType: UIImagePickerController.SourceType, metadata: [AnyHashable: Any]?) -> (ALMessage?, IndexPath?) {
        guard let url = URL(string: path) else { return (nil, nil) }
        var contentType = ALMESSAGE_CONTENT_ATTACHMENT
        if sourceType == .camera {
            contentType = ALMESSAGE_CONTENT_CAMERA_RECORDING
        }

        guard let alMessage = processAttachment(filePath: url, text: "", contentType: Int(contentType), isVideo: true, metadata: metadata) else { return (nil, nil) }
        addToWrapper(message: alMessage)
        return (alMessage, IndexPath(row: 0, section: messageModels.count - 1))
    }

    open func uploadVideo(view: UIView, indexPath: IndexPath) {
        let alMessage = alMessages[indexPath.section]

        let clientService = ALMessageClientService()
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()
        guard let dbMessage = messageService.getMeesageBy(alMessage.msgDBObjectId) as? DB_Message else {
            return
        }

        dbMessage.inProgress = 1
        dbMessage.isUploadFailed = 0

        let error = alHandler?.saveContext()
        if error != nil {
            print("Not saved due to error \(String(describing: error))")
            return
        }

        print("content type: ", alMessage.fileMeta.contentType ?? "")
        print("file path: ", alMessage.imageFilePath ?? "")
        clientService.sendPhoto(forUserInfo: alMessage.dictionary(), withCompletion: {
            urlStr, error in
            guard error == nil, let urlStr = urlStr, let url = URL(string: urlStr) else {
                NSLog("error sending video %@", error.debugDescription)
                return
            }
            NSLog("URL TO UPLOAD VIDEO AT PATH %@ IS %@", alMessage.imageFilePath ?? "", url.description)
            let downloadManager = ALKHTTPManager()
            downloadManager.uploadDelegate = view as? ALKHTTPManagerUploadDelegate
            let task = ALKUploadTask(url: url, fileName: alMessage.fileMeta.name)
            task.identifier = alMessage.identifier
            task.contentType = alMessage.fileMeta.contentType
            task.filePath = alMessage.imageFilePath
            downloadManager.uploadAttachment(task: task)
            downloadManager.uploadCompleted = { [weak self] responseDict, task in
                if task.uploadError == nil, task.completed {
                    self?.uploadAttachmentCompleted(responseDict: responseDict, indexPath: indexPath)
                }
            }
        })
    }

    // FIXME: Remove indexpath from this call and add message id param. Currently there is an unneccessary dependency on the indexpath.
    open func uploadAttachmentCompleted(responseDict: Any?, indexPath: IndexPath) {
        // populate metadata and send message
        guard alMessages.count > indexPath.section else { return }
        let alMessage = alMessages[indexPath.section]
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()
        guard let dbMessage = messageService.getMeesageBy(alMessage.msgDBObjectId) as? DB_Message,
              let message = messageService.createMessageEntity(dbMessage) else { return }

        guard let fileInfo = responseDict as? [String: Any] else { return }
        if ALApplozicSettings.isS3StorageServiceEnabled() {
            message.fileMeta.populate(fileInfo)
        } else {
            guard let fileMeta = fileInfo["fileMeta"] as? [String: Any] else { return }
            message.fileMeta.populate(fileMeta)
        }
        message.status = NSNumber(integerLiteral: Int(SENT.rawValue))

        let error = alHandler?.saveContext()
        if error != nil {
            print("Not saved due to error \(String(describing: error))")
            return
        }

        send(alMessage: message) {
            updatedMessage in
            guard let mesg = updatedMessage else { return }
            DispatchQueue.main.async {
                NSLog("UI updated at section: \(indexPath.section), \(message.isSent)")
                self.alMessages[indexPath.section] = mesg
                self.messageModels[indexPath.section] = mesg.messageModel
                self.delegate?.updateMessageAt(indexPath: indexPath)
            }
        }
    }

    open func updateMessageModelAt(indexPath: IndexPath, data: Data) {
        var message = messageForRow(indexPath: indexPath)
        message?.voiceData = data
        messageModels[indexPath.section] = message as! ALKMessageModel
        delegate?.updateMessageAt(indexPath: indexPath)
    }

    @objc func sendTypingStatus() {
        mqttObject?.sendTypingStatus(ALUserDefaultsHandler.getApplicationKey(), userID: contactId, andChannelKey: channelKey, typing: true)
    }

    open func sendKeyboardBeginTyping() {
        guard shouldSendTyping else { return }
        shouldSendTyping = false
        sendTypingStatus()
        typingTimerTask = Timer.scheduledTimer(timeInterval: 25.0, target: self, selector: #selector(sendTypingStatus), userInfo: nil, repeats: true)
    }

    open func sendKeyboardDoneTyping() {
        shouldSendTyping = true
        typingTimerTask.invalidate()
        mqttObject?.sendTypingStatus(ALUserDefaultsHandler.getApplicationKey(), userID: contactId, andChannelKey: channelKey, typing: false)
    }

    func syncOpenGroup(message: ALMessage) {
        guard let groupId = message.groupId,
              groupId == channelKey,
              !message.isMyMessage,
              message.deviceKey != ALUserDefaultsHandler.getDeviceKeyString()
        else {
            return
        }
        addMessagesToList([message])
    }

    open func refresh() {
        if let key = channelKey, ALChannelService.isChannelDeleted(key) {
            return
        }
        delegate?.loadingStarted()
        guard !isOpenGroup else {
            loadOpenGroupMessages()
            return
        }
        ALMessageService.getLatestMessage(
            forUser: ALUserDefaultsHandler.getDeviceKeyString(),
            withCompletion: { messageList, error in
                self.delegate?.loadingFinished(error: error)
                guard error == nil,
                      let messages = messageList as? [ALMessage],
                      !messages.isEmpty else { return }
                self.loadMessagesFromDB()
            }
        )
    }

    open func uploadAudio(alMessage: ALMessage, indexPath: IndexPath) {
        let clientService = ALMessageClientService()
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()

        guard let dbMessage = messageService.getMeesageBy(alMessage.msgDBObjectId) as? DB_Message else {
            return
        }

        dbMessage.inProgress = 1
        dbMessage.isUploadFailed = 0
        let error = alHandler?.saveContext()
        if error != nil {
            print("Not saved due to error \(String(describing: error))")
            return
        }
        NSLog("content type: ", alMessage.fileMeta.contentType)
        NSLog("file path: ", alMessage.imageFilePath)
        clientService.sendPhoto(forUserInfo: alMessage.dictionary(), withCompletion: {
            urlStr, error in
            guard error == nil, let urlStr = urlStr, let url = URL(string: urlStr) else { return }
            let task = ALKUploadTask(url: url, fileName: alMessage.fileMeta.name)
            task.identifier = String(format: "section: %i, row: %i", indexPath.section, indexPath.row)
            task.contentType = alMessage.fileMeta.contentType
            task.filePath = alMessage.imageFilePath
            let downloadManager = ALKHTTPManager()
            downloadManager.uploadAttachment(task: task)
            downloadManager.uploadCompleted = { [weak self] responseDict, task in
                if task.uploadError == nil, task.completed {
                    self?.uploadAttachmentCompleted(responseDict: responseDict, indexPath: indexPath)
                }
            }
        })
    }

    open func uploadImage(view: UIView, indexPath: IndexPath) {
        let alMessage = alMessages[indexPath.section]
        let clientService = ALMessageClientService()
        let messageService = ALMessageDBService()
        let alHandler = ALDBHandler.sharedInstance()
        guard let dbMessage = messageService.getMeesageBy(alMessage.msgDBObjectId) as? DB_Message else {
            return
        }
        dbMessage.inProgress = 1
        dbMessage.isUploadFailed = 0
        let error = alHandler?.saveContext()
        if error != nil {
            print("Not saved due to error \(String(describing: error))")
            return
        }
        NSLog("content type: ", alMessage.fileMeta.contentType)
        NSLog("file path: ", alMessage.imageFilePath)
        clientService.sendPhoto(forUserInfo: alMessage.dictionary(), withCompletion: {
            urlStr, error in
            guard error == nil, let urlStr = urlStr, let url = URL(string: urlStr) else { return }
            let task = ALKUploadTask(url: url, fileName: alMessage.fileMeta.name)
            task.identifier = String(format: "section: %i, row: %i", indexPath.section, indexPath.row)
            task.contentType = alMessage.fileMeta.contentType
            task.filePath = alMessage.imageFilePath
            let downloadManager = ALKHTTPManager()
            downloadManager.uploadDelegate = view as? ALKHTTPManagerUploadDelegate
            downloadManager.uploadAttachment(task: task)
            downloadManager.uploadCompleted = { [weak self] responseDict, task in
                if task.uploadError == nil, task.completed {
                    self?.uploadAttachmentCompleted(responseDict: responseDict, indexPath: indexPath)
                }
            }
        })
    }

    open func encodeVideo(videoURL: URL, completion: @escaping (_ path: String?) -> Void) {
        guard let videoURL = URL(string: "file://\(videoURL.path)") else { return }

        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let myDocumentPath = URL(fileURLWithPath: documentsDirectory).appendingPathComponent(String(format: "VID-%f.MOV", Date().timeIntervalSince1970 * 1000))
        do {
            let data = try Data(contentsOf: videoURL)
            try data.write(to: myDocumentPath)
        } catch {
            NSLog("error: \(error)")
        }

        let documentsDirectory2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = String(format: "VID-%f.mp4", Date().timeIntervalSince1970 * 1000)
        let filePath = documentsDirectory2.appendingPathComponent(fileName)
        deleteFile(filePath: filePath)

        let avAsset = AVURLAsset(url: myDocumentPath)

        let startDate = NSDate()

        // Create Export session
        let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough)

        exportSession!.outputURL = filePath
        exportSession!.outputFileType = AVFileType.mp4
        exportSession!.shouldOptimizeForNetworkUse = true
        let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
        let range = CMTimeRangeMake(start: start, duration: avAsset.duration)
        exportSession?.timeRange = range

        exportSession!.exportAsynchronously(completionHandler: { () -> Void in
            switch exportSession!.status {
            case .failed:
                print("%@", exportSession?.error as Any)
                completion(nil)
            case .cancelled:
                print("Export canceled")
                completion(nil)
            case .completed:
                // Video conversion finished
                let endDate = NSDate()

                let time = endDate.timeIntervalSince(startDate as Date)
                print(time)
                print("Successful!")
                print(exportSession?.outputURL as Any)
                completion(exportSession?.outputURL?.path)
            default:
                break
            }
        })
    }

    /// One of the template message was selected.
    open func selected(template: ALKTemplateMessageModel, metadata: [AnyHashable: Any]?) {
        // Send message if property is set
        guard template.sendMessageOnSelection else { return }
        var text = template.text
        if let messageToSend = template.messageToSend {
            text = messageToSend
        }

        send(message: text, isOpenGroup: isOpenGroup, metadata: metadata)
    }

    open func setSelectedMessageToReply(_ message: ALKMessageViewModel) {
        selectedMessageForReply = message
    }

    open func getSelectedMessageToReply() -> ALKMessageViewModel? {
        return selectedMessageForReply
    }

    open func clearSelectedMessageToReply() {
        selectedMessageForReply = nil
    }

    open func getIndexpathFor(message: ALKMessageModel) -> IndexPath? {
        guard let index = messageModels.firstIndex(of: message)
        else { return nil }
        return IndexPath(row: 0, section: index)
    }

    open func showPoweredByMessage() -> Bool {
        return ALApplicationInfo().showPoweredByMessage()
    }

    func updateUserDetail(_ userId: String) {
        ALUserService.updateUserDetail(userId, withCompletion: {
            userDetail in
            guard userDetail != nil else { return }
            guard
                !self.isGroup,
                userId == self.contactId,
                let contact = ALContactService().loadContact(byKey: "userId", value: userId)
            else { return }
            self.delegate?.updateDisplay(contact: contact, channel: nil)
        })
    }

    func currentConversationProfile(completion: @escaping (ALKConversationProfile?) -> Void) {
        if channelKey != nil {
            ALChannelService().getChannelInformation(channelKey, orClientChannelKey: nil) { channel in
                guard let channel = channel else {
                    print("Error while fetching channel details")
                    completion(nil)
                    return
                }
                guard
                    let userId = channel.getReceiverIdInGroupOfTwo(),
                    let contact = ALContactDBService().loadContact(byKey: "userId", value: userId)
                else {
                    completion(self.conversationProfileFrom(contact: nil, channel: channel))
                    return
                }
                completion(self.conversationProfileFrom(contact: contact, channel: nil))
            }
        } else if contactId != nil {
            ALUserService().getUserDetail(contactId) { contact in
                guard let contact = contact else {
                    print("Error while fetching contact details")
                    completion(nil)
                    return
                }
                self.updateUserDetail(contact.userId)
                completion(self.conversationProfileFrom(contact: contact, channel: nil))
            }
        }
    }

    func conversationProfileFrom(contact: ALContact?, channel: ALChannel?) -> ALKConversationProfile {
        var conversationProfile = ALKConversationProfile()
        conversationProfile.name = channel?.name ?? contact?.getDisplayName() ?? ""
        conversationProfile.imageUrl = channel?.channelImageURL ?? contact?.contactImageUrl
        guard let contact = contact, channel == nil else {
            return conversationProfile
        }
        conversationProfile.isBlocked = contact.block || contact.blockBy
        conversationProfile.status = ALKConversationProfile.Status(isOnline: contact.connected, lastSeenAt: contact.lastSeenAt)
        return conversationProfile
    }

    func loadMessages() {
        var time: NSNumber?
        if let messageList = alMessageWrapper.getUpdatedMessageArray(), messageList.count > 1 {
            time = (messageList.firstObject as! ALMessage).createdAtTime
        }
        let messageListRequest = MessageListRequest()
        messageListRequest.userId = contactId
        messageListRequest.channelKey = channelKey
        messageListRequest.conversationId = conversationId
        messageListRequest.endTimeStamp = time
        ALMessageService.sharedInstance().getMessageList(forUser: messageListRequest, withCompletion: {
            messages, error, _ in
            guard error == nil, let messages = messages else {
                self.delegate?.loadingFinished(error: error)
                return
            }
            NSLog("messages loaded: ", messages)
            self.alMessages = messages.reversed() as! [ALMessage]
            self.alMessageWrapper.addObject(toMessageArray: messages)
            let models = self.alMessages.map { $0.messageModel }
            self.messageModels = models

            let showLoadEarlierOption: Bool = self.messageModels.count >= 50
            ALUserDefaultsHandler.setShowLoadEarlierOption(showLoadEarlierOption, forContactId: self.chatId)
            self.membersInGroup { members in
                self.groupMembers = members
                self.delegate?.loadingFinished(error: nil)
            }
        })
    }

    func loadSearchMessages() {
        var time: NSNumber?
        if let messageList = alMessageWrapper.getUpdatedMessageArray(), messageList.count > 1 {
            guard let message = messageList.firstObject as? ALMessage else {
                return
            }
            time = message.createdAtTime
        }
        let messageListRequest = MessageListRequest()
        messageListRequest.userId = contactId
        messageListRequest.channelKey = channelKey
        messageListRequest.conversationId = conversationId
        messageListRequest.endTimeStamp = time
        ALMessageClientService().getMessageList(forUser: messageListRequest, isSearch: true) { [weak self] messages, error in
            guard error == nil, let messages = messages, let weakSelf = self else {
                self?.delegate?.loadingFinished(error: error)
                return
            }

            if let list = weakSelf.alMessageWrapper.getUpdatedMessageArray(), list.count > 1 {
                weakSelf.fetchReplyMessages(from: messages) { [weak self] result in
                    guard let replyWeakSelf = self else {
                        self?.delegate?.loadingFinished(error: nil)
                        return
                    }
                    switch result {
                    case let .success(messagesArray):
                        for mesg in messagesArray as! [ALMessage] {
                            guard let msg = self?.alMessages.first, let time = Double(msg.createdAtTime.stringValue) else { continue }
                            if let msgTime = Double(mesg.createdAtTime.stringValue), time <= msgTime {
                                continue
                            }
                            replyWeakSelf.alMessageWrapper
                                .getUpdatedMessageArray()
                                .insert(mesg, at: 0)
                            replyWeakSelf.alMessages.insert(mesg, at: 0)
                            replyWeakSelf.messageModels.insert(mesg.messageModel, at: 0)
                        }
                        replyWeakSelf.delegate?.loadingFinished(error: nil)
                    case let .failure(error):
                        print("Error in fetching messages:", error.localizedDescription)
                        replyWeakSelf.delegate?.loadingFinished(error: nil)
                    }
                }
                return
            }

            weakSelf.fetchReplyMessages(from: messages) { [weak self] result in
                guard let replyWeakSelf = self else {
                    self?.delegate?.loadingFinished(error: nil)
                    return
                }
                switch result {
                case let .success(messagesArray):
                    replyWeakSelf.alMessages = messagesArray.reversed() as! [ALMessage]
                    replyWeakSelf.alMessageWrapper.addObject(toMessageArray: messages)
                    let models = replyWeakSelf.alMessages.map { $0.messageModel }
                    replyWeakSelf.messageModels = models
                    replyWeakSelf.delegate?.loadingFinished(error: nil)
                case let .failure(error):
                    print("Error in fetching messages:", error.localizedDescription)
                    replyWeakSelf.delegate?.loadingFinished(error: nil)
                }
            }
        }
    }

    func fetchReplyMessages(from messages: NSMutableArray, _ completion: @escaping (Result<NSMutableArray, Error>) -> Void) {
        let service = ALMessageService()
        let messageDb = ALMessageDBService()
        let replyMessageKeys = NSMutableArray()
        let contactService = ALContactService()
        let contactDBService = ALContactDBService()

        let alUserService = ALUserService()
        if let newMessages = messages as? [ALMessage] {
            for msg in newMessages {
                if let metadata = msg.metadata,
                   let replyKey = metadata.value(forKey: AL_MESSAGE_REPLY_KEY) as? String,
                   messageDb.getMessageByKey("key", value: replyKey) == nil,
                   !replyMessageKeys.contains(replyKey)
                {
                    replyMessageKeys.add(replyKey)
                }
            }

            service.fetchReplyMessages(replyMessageKeys) { replyMessages in
                var userNotPresentIds = [String]()

                if let newMessages = replyMessages as? [ALMessage], !newMessages.isEmpty {
                    for replyMessage in newMessages {
                        if !contactService.isContactExist(replyMessage.to) {
                            userNotPresentIds.append(replyMessage.to)
                        }
                    }
                }

                guard !userNotPresentIds.isEmpty else {
                    completion(.success(messages))
                    return
                }
                alUserService.fetchAndupdateUserDetails(NSMutableArray(array: userNotPresentIds), withCompletion: { userDetailArray, theError in

                    guard theError == nil else {
                        completion(.failure(theError!))
                        return
                    }
                    contactDBService.addUserDetails(userDetailArray)
                    completion(.success(messages))
                })
            }
        }
    }

    func loadMessagesFromDB(isFirstTime: Bool = true) {
        ALMessageService.getMessageList(forContactId: contactId, isGroup: isGroup, channelKey: channelKey, conversationId: conversationId, start: 0, withCompletion: {
            messages in
            guard let messages = messages else {
                self.delegate?.loadingFinished(error: nil)
                return
            }
            NSLog("messages loaded: %@", messages)
            self.alMessages = messages as! [ALMessage]
            self.alMessageWrapper.addObject(toMessageArray: messages)
            let models = messages.map { ($0 as! ALMessage).messageModel }
            self.messageModels = models
            let showLoadEarlierOption: Bool = self.messageModels.count >= 50
            ALUserDefaultsHandler.setShowLoadEarlierOption(showLoadEarlierOption, forContactId: self.chatId)
            if isFirstTime {
                self.membersInGroup { members in
                    self.groupMembers = members
                    self.delegate?.loadingFinished(error: nil)
                }
            } else {
                self.delegate?.messageUpdated()
            }
        })
    }

    open func loadOpenGroupMessages() {
        var time: NSNumber?
        if let messageList = alMessageWrapper.getUpdatedMessageArray(), messageList.count > 1 {
            time = (messageList.firstObject as! ALMessage).createdAtTime
        }
        NSLog("Last time: \(String(describing: time))")
        fetchOpenGroupMessages(time: time, contactId: contactId, channelKey: channelKey, completion: {
            messageList in

            guard let messages = messageList else {
                self.delegate?.loadingFinished(error: nil)
                return
            }
            self.addMessagesToList(messages)
            self.delegate?.loadingFinished(error: nil)
        })
    }

    func fetchGroupMembersForAutocompletion() -> [AutoCompleteItem] {
        guard let members = groupMembers else { return [] }
        let items =
            members
                .filter { $0.userId != ALUserDefaultsHandler.getUserId() }
                .map { AutoCompleteItem(key: $0.userId, content: $0.displayName ?? $0.userId, displayImageURL: $0.friendDisplayImgURL) }
                .sorted { $0.content < $1.content }
        return items
    }

    func displayNames(ofUserIds userIds: Set<String>) -> [String: String]? {
        guard let groupMembers = groupMembers else { return nil }
        var names: [String: String] = [:]
        groupMembers
            .filter { userIds.contains($0.userId) }
            .forEach { names[$0.userId] = $0.displayName ?? $0.userId }
        return names
    }

    func sendFile(at url: URL, fileName: String, metadata: [AnyHashable: Any]?) -> (ALMessage?, IndexPath?) {
        var fileData: Data?
        do {
            fileData = try Data(contentsOf: url)
        } catch {
            print("Failed to read the content of the file at path: \(url) due to error: \(error.localizedDescription)")
        }
        guard fileData != nil else { return (nil, nil) }
        guard let alMessage = processAttachment(
            filePath: url,
            text: "",
            contentType: Int(ALMESSAGE_CONTENT_ATTACHMENT),
            metadata: metadata,
            fileName: fileName
        ) else {
            return (nil, nil)
        }
        addToWrapper(message: alMessage)
        return (alMessage, IndexPath(row: 0, section: messageModels.count - 1))
    }

    // MARK: - Private Methods

    private func updateGroupInfo(
        groupName: String,
        groupImage: String?,
        completion: @escaping (Bool) -> Void
    ) {
        guard let groupId = groupKey() else { return }
        let alchanneService = ALChannelService()
        alchanneService.updateChannel(
            groupId, andNewName: groupName,
            andImageURL: groupImage,
            orClientChannelKey: nil,
            isUpdatingMetaData: false,
            metadata: nil,
            orChildKeys: nil,
            orChannelUsers: nil,
            withCompletion: {
                errorReceived in
                if let error = errorReceived {
                    print("error received while updating group info: ", error)
                    completion(false)
                } else {
                    completion(true)
                }
            }
        )
    }

    private func loadEarlierMessages() {
        delegate?.loadingStarted()
        var time: NSNumber?
        if let messageList = alMessageWrapper.getUpdatedMessageArray(),
           messageList.count > 1,
           let first = alMessages.first
        {
            time = first.createdAtTime
        }
        let messageListRequest = MessageListRequest()
        messageListRequest.userId = contactId
        messageListRequest.channelKey = channelKey
        messageListRequest.conversationId = conversationId
        messageListRequest.endTimeStamp = time
        ALMessageService.sharedInstance().getMessageList(forUser: messageListRequest, withCompletion: {
            messages, error, _ in
            guard error == nil, let newMessages = messages as? [ALMessage] else {
                self.delegate?.loadingFinished(error: error)
                return
            }
            //                NSLog("messages loaded: ", messages)
            for mesg in newMessages {
                guard let msg = self.alMessages.first, let time = Double(msg.createdAtTime.stringValue) else { continue }
                if let msgTime = Double(mesg.createdAtTime.stringValue), time <= msgTime {
                    continue
                }
                self.alMessageWrapper.getUpdatedMessageArray().insert(newMessages, at: 0)
                self.alMessages.insert(mesg, at: 0)
                self.messageModels.insert(mesg.messageModel, at: 0)
            }
            if newMessages.count < 50 {
                ALUserDefaultsHandler.setShowLoadEarlierOption(false, forContactId: self.chatId)
            }
            self.delegate?.loadingFinished(error: nil)
        })
    }

    private func fetchOpenGroupMessages(time: NSNumber?, contactId: String?, channelKey: NSNumber?, completion: @escaping ([ALMessage]?) -> Void) {
        let messageListRequest = MessageListRequest()
        messageListRequest.userId = contactId
        messageListRequest.channelKey = channelKey
        messageListRequest.conversationId = conversationId
        messageListRequest.endTimeStamp = time
        let messageClientService = ALMessageClientService()
        messageClientService.getMessageList(forUser: messageListRequest, withCompletion: {
            messages, _, userDetailsList in

            let contactDbService = ALContactDBService()
            contactDbService.addUserDetails(userDetailsList)
            guard let alMessages = messages as? [ALMessage] else {
                completion(nil)
                return
            }
            let contactService = ALContactService()
            var contactsNotPresent = [String]()
            for message in alMessages {
                let contactId = message.to ?? ""
                if !contactService.isContactExist(contactId) {
                    contactsNotPresent.append(contactId)
                }
            }

            if !contactsNotPresent.isEmpty {
                let userService = ALUserService()
                userService.fetchAndupdateUserDetails(NSMutableArray(array: contactsNotPresent), withCompletion: { userDetails, _ in
                    contactDbService.addUserDetails(userDetails)
                    completion(alMessages)
                })
            } else {
                completion(alMessages)
            }

        })
    }

    private func addMembersToGroup(users: [ALKFriendViewModel], completion: @escaping (Bool) -> Void) {
        guard let groupId = groupKey() else { return }
        let alchanneService = ALChannelService()
        let channels = NSMutableArray(object: groupId)
        let channelUsers = NSMutableArray(array: users.map { $0.friendUUID as Any })
        alchanneService.addMultipleUsers(toChannel: channels, channelUsers: channelUsers, andCompletion: {
            error in
            if error != nil {
                print("error while adding members to group")
                completion(false)
            } else {
                completion(true)
            }
        })
    }

    private func updateDbMessageWith(key: String, value: String, filePath: String) {
        let messageService = ALMessageDBService()
        messageService.updateDbMessageWith(key: key, value: value, filePath: filePath)
    }

    private func getMessageToPost(isTextMessage: Bool = false) -> ALMessage {
        var alMessage = ALMessage()
        // If it's a text message then set the reply id
        if isTextMessage { alMessage = setReplyId(message: alMessage) }

        delegate?.willSendMessage()
        alMessage.to = contactId
        alMessage.contactIds = contactId
        alMessage.message = ""
        alMessage.type = "5"
        let date = Date().timeIntervalSince1970 * 1000
        alMessage.createdAtTime = NSNumber(value: date)
        alMessage.sendToDevice = false
        alMessage.deviceKey = ALUserDefaultsHandler.getDeviceKeyString()
        alMessage.shared = false
        alMessage.fileMeta = nil
        alMessage.storeOnDevice = false
        alMessage.contentType = Int16(ALMESSAGE_CONTENT_DEFAULT)
        alMessage.key = UUID().uuidString
        alMessage.source = Int16(AL_SOURCE_IOS)
        alMessage.conversationId = conversationId
        alMessage.groupId = channelKey
        return alMessage
    }

    private func getFileMetaInfo() -> ALFileMetaInfo {
        let info = ALFileMetaInfo()
        info.blobKey = nil
        info.contentType = ""
        info.createdAtTime = nil
        info.key = nil
        info.name = ""
        info.size = ""
        info.userKey = ""
        info.thumbnailUrl = ""
        info.progressValue = 0
        return info
    }

    private func processAttachment(
        filePath: URL,
        text _: String,
        contentType: Int,
        isVideo _: Bool = false,
        metadata: [AnyHashable: Any]?,
        fileName: String? = nil
    ) -> ALMessage? {
        let alMessage = getMessageToPost()
        alMessage.metadata = modfiedMessageMetadata(alMessage: alMessage, metadata: metadata)
        alMessage.contentType = Int16(contentType)
        alMessage.fileMeta = getFileMetaInfo()
        alMessage.imageFilePath = filePath.lastPathComponent
        alMessage.fileMeta.name = fileName ?? String(format: "AUD-5-%@", filePath.lastPathComponent)
        if fileName == nil, let contactId = contactId {
            alMessage.fileMeta.name = String(format: "%@-5-%@", contactId, filePath.lastPathComponent)
        }
        let pathExtension = filePath.pathExtension
        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue()
        let mimetype = (UTTypeCopyPreferredTagWithClass(uti!, kUTTagClassMIMEType)?.takeRetainedValue()) as String?
        alMessage.fileMeta.contentType = mimetype ?? "application/zip"
        if contentType == ALMESSAGE_CONTENT_VCARD {
            alMessage.fileMeta.contentType = "text/x-vcard"
        }

        guard let imageData = NSData(contentsOfFile: filePath.path) else {
            // Empty image.
            return nil
        }
        alMessage.fileMeta.size = String(format: "%lu", imageData.length)

        let dbHandler = ALDBHandler.sharedInstance()
        let messageService = ALMessageDBService()

        guard let messageEntity = messageService.createMessageEntityForDBInsertion(with: alMessage) else {
            return nil
        }
        let error = dbHandler?.saveContext()

        if error == nil {
            alMessage.msgDBObjectId = messageEntity.objectID
            return alMessage
        }
        print("Not saved due to error \(String(describing: error))")
        return nil
    }

    private func createJson(dict: [String: String]) -> String? {
        var jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
        } catch {
            print("error creating json")
        }
        guard let data = jsonData, let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
    }

    private func getLocationMessage(latLonString: String) -> ALMessage {
        let alMessage = getMessageToPost()
        alMessage.contentType = Int16(ALMESSAGE_CONTENT_LOCATION)
        alMessage.message = latLonString
        return alMessage
    }

    private func send(alMessage: ALMessage, completion: @escaping (ALMessage?) -> Void) {
        ALMessageService.sharedInstance().sendMessages(alMessage, withCompletion: {
            message, error in
            let newMesg = alMessage
            NSLog("message is: ", newMesg.key)
            NSLog("Message sent: \(String(describing: message)), \(String(describing: error))")
            if error == nil {
                NSLog("No errors while sending the message")
                completion(newMesg)
            } else {
                completion(nil)
            }
        })
    }

    private func updateMessageStatus(filteredList: [ALMessage], status: Int32) {
        if !filteredList.isEmpty {
            let message = filteredList.first
            message?.status = status as NSNumber
            guard let model = message?.messageModel, let index = messageModels.firstIndex(of: model) else { return }
            messageModels[index] = model
            delegate?.updateMessageAt(indexPath: IndexPath(row: 0, section: index))
        }
    }

    private func deleteFile(filePath: URL) {
        guard FileManager.default.fileExists(atPath: filePath.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(atPath: filePath.path)
        } catch {
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }

    private func setReplyId(message: ALMessage) -> ALMessage {
        if let replyMessage = getSelectedMessageToReply() {
            let metaData = NSMutableDictionary()
            metaData[AL_MESSAGE_REPLY_KEY] = replyMessage.identifier
            message.metadata = metaData
        }
        return message
    }

    private func updateInfo() {
        guard let groupId = groupKey() else { return }
        let channel = ALChannelService().getChannelByKey(groupId)
        delegate?.updateDisplay(contact: nil, channel: channel)
    }

    private func getGenericCardTemplateFor(message: ALKMessageViewModel) -> ALKGenericCardTemplate? {
        guard
            let metadata = message.metadata,
            let payload = metadata["payload"] as? String
        else { return nil }
        do {
            let cards = try JSONDecoder().decode([ALKGenericCard].self, from: payload.data)
            let cardTemplate = ALKGenericCardTemplate(cards: cards)
            richMessages[message.identifier] = cardTemplate
            return cardTemplate
        } catch {
            print("\(error)")
            return nil
        }
    }

    private func membersInGroup(completion: @escaping ((Set<ALContact>?) -> Void)) {
        guard let channelKey = channelKey else {
            completion(nil)
            return
        }
        ALChannelDBService().membersInGroup(channelKey: channelKey) { contacts in
            guard let contacts = contacts, !contacts.isEmpty else {
                completion(nil)
                return
            }
            completion(contacts)
        }
    }
}
