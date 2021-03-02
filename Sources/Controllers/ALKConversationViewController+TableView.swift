//
//  ALKConversationViewController+TableView.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import AVFoundation
import Foundation
import UIKit
import WebKit

extension ALKConversationViewController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in _: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    public func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(section: section)
    }

    private func necessarySetupForMessageCell(cell: ALKMessageCell, message: ALKMessageViewModel) {
        cell.setLocalizedStringFileName(configuration.localizedStringFileName)
        cell.displayNames = { [weak self] userIds in
            self?.viewModel.displayNames(ofUserIds: userIds)
        }
        cell.update(viewModel: message)
        cell.update(chatBar: chatBar)
        cell.delegate = self
        cell.menuAction = { [weak self] action in
            self?.menuItemSelected(action: action, message: message)
        }
        cell.replyViewAction = { [weak self] in
            self?.scrollTo(message: message)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let message = viewModel.messageForRow(indexPath: indexPath) else {
            return UITableViewCell()
        }
        print("Cell updated at row: ", indexPath.row, "and type is: ", message.messageType)

        switch message.messageType {
        case .text, .html, .email:
            if !configuration.isLinkPreviewDisabled, message.messageType == .text, ALKLinkPreviewManager.extractURLAndAddInCache(from: message.message, identifier: message.identifier) != nil {
                var cell = ALKLinkPreviewBaseCell()
                cell.menuOptionsToShow = configuration.messageMenuOptions
                if message.isMyMessage {
                    cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ALKMyLinkPreviewCell
                    cell.showReport = false
                    necessarySetupForMessageCell(cell: cell, message: message)
                } else {
                    cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ALKFriendLinkPreviewCell
                    cell.showReport = true
                    cell.avatarTapped = { [weak self] in
                        guard let currentModel = cell.viewModel else { return }
                        self?.messageAvatarViewDidTap(messageVM: currentModel, indexPath: indexPath)
                    }
                    necessarySetupForMessageCell(cell: cell, message: message)
                }
                cell.isCellVisible { [weak self] identifier in
                    guard let weakSelf = self else { return false }
                    return weakSelf.isCellVisible(identifier: identifier)
                }
                return cell

            } else {
                if message.isMyMessage {
                    let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ALKMyMessageCell
                    cell.menuOptionsToShow = configuration.messageMenuOptions
                    cell.showReport = false
                    necessarySetupForMessageCell(cell: cell, message: message)
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ALKFriendMessageCell
                    cell.menuOptionsToShow = configuration.messageMenuOptions
                    cell.showReport = true
                    cell.avatarTapped = { [weak self] in
                        guard let currentModel = cell.viewModel else { return }
                        self?.messageAvatarViewDidTap(messageVM: currentModel, indexPath: indexPath)
                    }
                    necessarySetupForMessageCell(cell: cell, message: message)
                    return cell
                }
            }
        case .photo:
            if message.isMyMessage {
                // Right now ratio is fixed to 1.77
                if message.ratio < 1 {
                    print("image messsage called")
                    let cell: ALKMyPhotoPortalCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                    // Set the value to nil so that previous image gets removed before reuse
                    cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                    cell.photoView.image = nil
                    cell.menuOptionsToShow = configuration.messageMenuOptions
                    cell.showReport = false
                    cell.update(viewModel: message)
                    cell.uploadTapped = { [weak self]
                        _ in
                        // upload
                        self?.attachmentViewDidTapUpload(view: cell, indexPath: indexPath)
                    }
                    cell.uploadCompleted = { [weak self]
                        responseDict in
                        self?.attachmentUploadDidCompleteWith(response: responseDict, indexPath: indexPath)
                    }
                    cell.downloadTapped = { [weak self]
                        _ in
                        self?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                    }
                    cell.menuAction = { [weak self] action in
                        self?.menuItemSelected(action: action, message: message)
                    }
                    return cell

                } else {
                    let cell: ALKMyPhotoLandscapeCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                    cell.menuOptionsToShow = configuration.messageMenuOptions
                    cell.showReport = false
                    cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                    cell.update(viewModel: message)
                    cell.uploadCompleted = { [weak self]
                        responseDict in
                        self?.attachmentUploadDidCompleteWith(response: responseDict, indexPath: indexPath)
                    }
                    cell.menuAction = { [weak self] action in
                        self?.menuItemSelected(action: action, message: message)
                    }
                    return cell
                }

            } else {
                if message.ratio < 1 {
                    let cell: ALKFriendPhotoPortalCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                    cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                    cell.menuOptionsToShow = configuration.messageMenuOptions
                    cell.showReport = true
                    cell.update(viewModel: message)
                    cell.downloadTapped = { [weak self]
                        _ in
                        self?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                    }
                    cell.avatarTapped = { [weak self] in
                        guard let currentModel = cell.viewModel else { return }
                        self?.messageAvatarViewDidTap(messageVM: currentModel, indexPath: indexPath)
                    }
                    cell.menuAction = { [weak self] action in
                        self?.menuItemSelected(action: action, message: message)
                    }
                    return cell

                } else {
                    let cell: ALKFriendPhotoLandscapeCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                    cell.menuOptionsToShow = configuration.messageMenuOptions
                    cell.showReport = true
                    cell.menuAction = { [weak self] action in
                        self?.menuItemSelected(action: action, message: message)
                    }
                    cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                    cell.update(viewModel: message)
                    return cell
                }
            }
        case .voice:
            print("voice cell loaded with url", message.filePath as Any)
            print("current voice state: ", message.voiceCurrentState, "row", indexPath.row, message.voiceTotalDuration, message.voiceData as Any)
            print("voice identifier: ", message.identifier, "and row: ", indexPath.row)

            if message.isMyMessage {
                let cell: ALKMyVoiceCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.menuOptionsToShow = configuration.messageMenuOptions
                cell.showReport = false
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.downloadTapped = { [weak self] _ in
                    self?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                }
                cell.update(viewModel: message)
                cell.setCellDelegate(delegate: self)
                cell.menuAction = { [weak self] action in
                    self?.menuItemSelected(action: action, message: message)
                }
                return cell
            } else {
                let cell: ALKFriendVoiceCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.menuOptionsToShow = configuration.messageMenuOptions
                cell.showReport = true
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.downloadTapped = { [weak self] _ in
                    self?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                }
                cell.update(viewModel: message)
                cell.setCellDelegate(delegate: self)
                cell.avatarTapped = { [weak self] in
                    guard let currentModel = cell.viewModel else { return }
                    self?.messageAvatarViewDidTap(messageVM: currentModel, indexPath: indexPath)
                }
                cell.menuAction = { [weak self] action in
                    self?.menuItemSelected(action: action, message: message)
                }
                return cell
            }
        case .location:
            if message.isMyMessage {
                let cell: ALKMyLocationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.menuOptionsToShow = configuration.messageMenuOptions
                cell.showReport = false
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.update(viewModel: message)
                cell.setDelegate(locDelegate: self)
                cell.menuAction = { [weak self] action in
                    self?.menuItemSelected(action: action, message: message)
                }
                return cell

            } else {
                let cell: ALKFriendLocationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.menuOptionsToShow = configuration.messageMenuOptions
                cell.showReport = true
                cell.update(viewModel: message)
                cell.setDelegate(locDelegate: self)
                cell.avatarTapped = { [weak self] in
                    guard let currentModel = cell.viewModel else { return }
                    self?.messageAvatarViewDidTap(messageVM: currentModel, indexPath: indexPath)
                }
                cell.menuAction = { [weak self] action in
                    self?.menuItemSelected(action: action, message: message)
                }
                return cell
            }
        case .information:
            let cell: ALKInformationCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
            cell.setConfiguration(configuration: configuration)
            cell.update(viewModel: message)
            return cell
        case .video:
            if message.isMyMessage {
                let cell: ALKMyVideoCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.menuOptionsToShow = configuration.messageMenuOptions
                cell.showReport = false
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.update(viewModel: message)
                cell.uploadTapped = { [weak self]
                    _ in
                    // upload
                    self?.attachmentViewDidTapUpload(view: cell, indexPath: indexPath)
                }
                cell.uploadCompleted = { [weak self]
                    responseDict in
                    self?.attachmentUploadDidCompleteWith(response: responseDict, indexPath: indexPath)
                }
                cell.downloadTapped = { [weak self]
                    _ in
                    self?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                }
                cell.menuAction = { [weak self] action in
                    self?.menuItemSelected(action: action, message: message)
                }
                return cell
            } else {
                let cell: ALKFriendVideoCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.menuOptionsToShow = configuration.messageMenuOptions
                cell.showReport = true
                cell.update(viewModel: message)
                cell.downloadTapped = { [weak self]
                    _ in
                    self?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                }
                cell.avatarTapped = { [weak self] in
                    guard let currentModel = cell.viewModel else { return }
                    self?.messageAvatarViewDidTap(messageVM: currentModel, indexPath: indexPath)
                }
                cell.menuAction = { [weak self] action in
                    self?.menuItemSelected(action: action, message: message)
                }
                return cell
            }
        case .cardTemplate:

            if message.isMyMessage {
                let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ALKMyGenericCardMessageCell
                cell.menuOptionsToShow = configuration.messageMenuOptions
                cell.showReport = false
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.register(cell: ALKGenericCardCell.self)
                cell.update(viewModel: message, width: UIScreen.main.bounds.width)
                cell.menuAction = { [weak self] action in
                    self?.menuItemSelected(action: action, message: message)
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ALKFriendGenericCardMessageCell
                cell.menuOptionsToShow = configuration.messageMenuOptions
                cell.showReport = true
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.register(cell: ALKGenericCardCell.self)
                cell.update(viewModel: message, width: UIScreen.main.bounds.width)
                cell.menuAction = { [weak self] action in
                    self?.menuItemSelected(action: action, message: message)
                }
                return cell
            }

        case .faqTemplate:

            if message.isMyMessage {
                let cell: SentFAQMessageCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                guard let faqMessage = message.faqMessage() else { return UITableViewCell() }
                cell.update(model: faqMessage)
                return cell
            } else {
                let cell: ReceivedFAQMessageCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                guard let faqMessage = message.faqMessage() else { return UITableViewCell() }
                cell.update(model: faqMessage)
                cell.faqSelected = {
                    [weak self] _, title in
                    guard let weakSelf = self, let viewModel = weakSelf.viewModel else { return }
                    viewModel.send(message: title, metadata: weakSelf.configuration.messageMetadata)
                }
                return cell
            }
        case .quickReply:
            if message.isMyMessage {
                let cell: ALKMyMessageQuickReplyCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.update(viewModel: message, maxWidth: UIScreen.main.bounds.width)
                cell.update(chatBar: chatBar)
                return cell
            } else {
                let cell: ALKFriendMessageQuickReplyCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.update(viewModel: message, maxWidth: UIScreen.main.bounds.width)
                cell.update(chatBar: chatBar)
                guard let template = message.payloadFromMetadata() else {
                    return cell
                }
                cell.quickReplySelected = { [weak self] index, title in
                    guard let weakSelf = self else { return }
                    weakSelf.quickReplySelected(
                        index: index,
                        title: title,
                        template: template,
                        message: message,
                        isButtonClickDisabled: weakSelf.configuration.disableRichMessageButtonAction
                    )
                }
                return cell
            }
        case .button:
            if message.isMyMessage {
                let cell: ALKMyMessageButtonCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.update(viewModel: message, maxWidth: UIScreen.main.bounds.width)
                cell.update(chatBar: chatBar)
                return cell
            } else {
                let cell: ALKFriendMessageButtonCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.update(viewModel: message, maxWidth: UIScreen.main.bounds.width)
                cell.update(chatBar: chatBar)
                cell.buttonSelected = { [weak self] index, title in
                    guard let weakSelf = self else { return }
                    weakSelf.messageButtonSelected(
                        index: index,
                        title: title,
                        message: message,
                        isButtonClickDisabled: weakSelf.configuration.disableRichMessageButtonAction
                    )
                }
                return cell
            }
        case .listTemplate:
            if message.isMyMessage {
                let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ALKMyMessageListTemplateCell
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.update(viewModel: message, maxWidth: UIScreen.main.bounds.width)
                cell.update(chatBar: chatBar)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(forIndexPath: indexPath) as ALKFriendMessageListTemplateCell
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.update(viewModel: message, maxWidth: UIScreen.main.bounds.width)
                cell.update(chatBar: chatBar)
                cell.templateSelected = { [weak self] defaultText, action in
                    guard let weakSelf = self else { return }
                    weakSelf.listTemplateSelected(defaultText: defaultText, action: action)
                }
                return cell
            }
        case .document:
            if message.isMyMessage {
                let cell: ALKMyDocumentCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.menuOptionsToShow = configuration.messageMenuOptions
                cell.showReport = false
                cell.update(viewModel: message)
                cell.update(chatBar: chatBar)
                cell.uploadTapped = { [weak self]
                    _ in
                    // upload
                    self?.attachmentViewDidTapUpload(view: cell, indexPath: indexPath)
                }
                cell.uploadCompleted = { [weak self]
                    responseDict in
                    self?.attachmentUploadDidCompleteWith(response: responseDict, indexPath: indexPath)
                }
                cell.downloadTapped = { [weak self]
                    _ in
                    self?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                }

                return cell
            } else {
                let cell: ALKFriendDocumentCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.menuOptionsToShow = configuration.messageMenuOptions
                cell.showReport = true
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.update(viewModel: message)
                cell.update(chatBar: chatBar)
                cell.uploadTapped = { [weak self]
                    _ in
                    // upload
                    self?.attachmentViewDidTapUpload(view: cell, indexPath: indexPath)
                }
                cell.uploadCompleted = { [weak self]
                    responseDict in
                    self?.attachmentUploadDidCompleteWith(response: responseDict, indexPath: indexPath)
                }
                cell.downloadTapped = { [weak self]
                    _ in
                    self?.attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                }
                return cell
            }
        case .contact:
            if message.isMyMessage {
                let cell: ALKMyContactMessageCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.update(viewModel: message)
                if let filePath = message.filePath {
                    cell.updateContactDetails(key: message.identifier, filePath: filePath)
                }
                if message.filePath == nil {
                    attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                }
                cell.contactView.contactSelected = { contactModel in
                    let contact = contactModel.contact
                    self.openContact(contact)
                }
                return cell
            } else {
                let cell: ALKFriendContactMessageCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.update(viewModel: message)
                if let filePath = message.filePath {
                    cell.updateContactDetails(key: message.identifier, filePath: filePath)
                }
                if message.filePath == nil {
                    attachmentViewDidTapDownload(view: cell, indexPath: indexPath)
                }
                cell.contactView.contactSelected = { contactModel in
                    let contact = contactModel.contact
                    self.openContact(contact)
                }
                return cell
            }
        case .imageMessage:
            guard let imageMessage = message.imageMessage() else { return UITableViewCell() }
            if message.isMyMessage {
                let cell: SentImageMessageCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.imageTapped = {
                    guard let imageUrl = URL(string: imageMessage.url) else { return }
                    self.openRichMessageImageView(imageUrl: imageUrl)
                }
                cell.update(model: imageMessage)
                return cell
            } else {
                let cell: ReceivedImageMessageCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.imageTapped = {
                    guard let imageUrl = URL(string: imageMessage.url) else { return }
                    self.openRichMessageImageView(imageUrl: imageUrl)
                }
                cell.update(model: imageMessage)
                return cell
            }

        case .allButtons:
            guard let allButtons = message.allButtons() else { return UITableViewCell() }
            if message.isMyMessage {
                let cell: SentButtonsCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.update(model: allButtons)
                return cell
            } else {
                let cell: ReceivedButtonsCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.update(model: allButtons)
                cell.tapped = { [weak self] index, name in
                    guard let weakSelf = self else { return }
                    weakSelf.richButtonSelected(
                        index: index,
                        title: name,
                        message: message,
                        isButtonClickDisabled: weakSelf.configuration.disableRichMessageButtonAction
                    )
                }
                return cell
            }
        case .form:
            guard message.formTemplate() != nil else { return UITableViewCell() }
            if message.isMyMessage {
                let cell: ALKMyFormCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.activeTextFieldChanged = { textField in
                    self.activeTextField = textField
                }
                cell.update(viewModel: message)
                cell.onTapOfDateSelect = { [weak self] index,
                    delegate,
                    datePickerMode,
                    identifier in
                    guard let weakSelf = self,
                          let pickerButtonClickProtocol = delegate else { return }
                    weakSelf.showDatePickerController(delegate: pickerButtonClickProtocol,
                                                      identifier: identifier,
                                                      position: index,
                                                      datePickerMode: datePickerMode,
                                                      localizedStringFileName: cell.localizedStringFileName)
                }
                return cell
            } else {
                let cell: ALKFriendFormCell = tableView.dequeueReusableCell(forIndexPath: indexPath)
                cell.setLocalizedStringFileName(configuration.localizedStringFileName)
                cell.activeTextFieldChanged = { textField in
                    self.activeTextField = textField
                }
                cell.update(viewModel: message)
                cell.tapped = { [weak self] _, _, submitData in
                    guard let weakSelf = self else { return }

                    // If not valid reload the table view section for a form to show the error message below the text fields.
                    if !cell.isFormDataValid() {
                        weakSelf.reloadSectionFor(identifier: message.identifier)
                    } else {
                        // The form data is valid to reload the existing form cell to remove error labels in the form.
                        if let validationFields = submitData?.validationFields,
                           !validationFields.isEmpty
                        {
                            weakSelf.reloadSectionFor(identifier: message.identifier)
                        }
                        weakSelf.formSubmitButtonSelected(formSubmitData: submitData,
                                                          messageModel: message,
                                                          isButtonClickDisabled:
                                                          weakSelf.configuration.disableRichMessageButtonAction)
                    }
                }

                cell.onTapOfDateSelect = { [weak self] index,
                    delegate,
                    datePickerMode,
                    identifier in
                    guard let weakSelf = self,
                          let pickerButtonClickProtocol = delegate else { return }
                    weakSelf.showDatePickerController(delegate: pickerButtonClickProtocol,
                                                      identifier: identifier,
                                                      position: index,
                                                      datePickerMode: datePickerMode,
                                                      localizedStringFileName: cell.localizedStringFileName)
                }
                return cell
            }
        }
    }

    public func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let message = viewModel.messageForRow(indexPath: indexPath),
           message.messageType == .form,
           message.formTemplate() != nil
        {
            return UITableView.automaticDimension
        } else {
            return viewModel.heightForRow(indexPath: indexPath, cellFrame: view.frame, configuration: configuration)
        }
    }

    public func tableView(_: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if let message = viewModel.messageForRow(indexPath: indexPath),
           message.messageType == .form,
           message.formTemplate() != nil
        {
            return UITableView.automaticDimension
        } else {
            return viewModel.heightForRow(indexPath: indexPath, cellFrame: view.frame, configuration: configuration)
        }
    }

    public func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let heightForHeaderInSection: CGFloat = 40.0

        guard let message1 = viewModel.messageForRow(indexPath: IndexPath(row: 0, section: section)) else {
            return 0.0
        }

        // If it is the first section then no need to check the difference,
        // just show the start date. (message list is not empty)
        if section == 0 {
            return heightForHeaderInSection
        }

        // Get previous message
        guard let message2 = viewModel.messageForRow(indexPath: IndexPath(row: 0, section: section - 1)) else {
            return 0.0
        }
        let date1 = message1.date
        let date2 = message2.date
        switch Calendar.current.compare(date1, to: date2, toGranularity: .day) {
        case .orderedDescending:
            // There is a day difference between current message and the previous message.
            return heightForHeaderInSection
        default:
            return 0.0
        }
    }

    public func tableView(_: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let message = viewModel.messageForRow(indexPath: IndexPath(row: 0, section: section)) else {
            return nil
        }

        // Get message creation date
        let date = message.date

        let dateView = ALKDateSectionHeaderView.instanceFromNib()

        // Set view style
        dateView.setupViewStyle()
        // Set date text
        dateView.setupDate(withDateFormat: date.stringCompareCurrentDate())
        return dateView
    }

    public func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let message = viewModel.messageForRow(indexPath: indexPath) else {
            return
        }
        guard message.metadata != nil else {
            return
        }
        if message.messageType == .cardTemplate {
            if message.isMyMessage {
                guard let cell = cell as? ALKMyGenericCardMessageCell else {
                    return
                }
                cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, indexPath: indexPath)
                let index = cell.collectionView.tag
                cell.collectionView.setContentOffset(CGPoint(x: collectionViewOffsetFromIndex(index), y: 0), animated: false)
            } else {
                guard let cell = cell as? ALKFriendGenericCardMessageCell else {
                    return
                }
                cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, indexPath: indexPath)
                let index = cell.collectionView.tag
                cell.collectionView.setContentOffset(CGPoint(x: collectionViewOffsetFromIndex(index), y: 0), animated: false)
            }
        }
    }

    func reloadSectionFor(identifier: String) {
        guard let index = viewModel.sectionFor(identifier: identifier),
              index < tableView.numberOfSections
        else {
            print("Can't be updated form cell due to incorrect index")
            return
        }
        tableView.reloadSections([index], with: .fade)
    }

    // MARK: Paging

    public func scrollViewDidEndDragging(_: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate { return }
        configurePaginationWindow()
    }

    public func scrollViewDidEndDecelerating(_: UIScrollView) {
        configurePaginationWindow()
    }

    public func scrollViewDidScrollToTop(_: UIScrollView) {
        configurePaginationWindow()
    }

    func configurePaginationWindow() {
        if tableView.frame.equalTo(CGRect.zero) { return }
        if tableView.isDragging { return }
        if tableView.isDecelerating { return }
        let topOffset = -tableView.contentInset.top
        let distanceFromTop = tableView.contentOffset.y - topOffset
        let minimumDistanceFromTopToTriggerLoadingMore: CGFloat = 200
        let nearTop = distanceFromTop <= minimumDistanceFromTopToTriggerLoadingMore
        if !nearTop { return }

        viewModel.nextPage()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if tableView.isCellVisible(section: viewModel.messageModels.count - 2, row: 0) {
            unreadScrollButton.isHidden = true
        }
        if scrollView is UICollectionView {
            let horizontalOffset = scrollView.contentOffset.x
            let collectionView = scrollView as! UICollectionView
            contentOffsetDictionary[collectionView.tag] = horizontalOffset as AnyObject
        }
    }
}

extension ALKConversationViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        guard
            let message = viewModel.messageForRow(
                indexPath: IndexPath(
                    row: 0,
                    section: collectionView.tag
                )
            ),
            message.metadata != nil
        else {
            return 0
        }

        guard collectionView.isKind(of: ALKIndexedCollectionView.self),
              let template = ALKGenericCardCollectionView.getCardTemplate(message: message)
        else {
            return 0
        }
        return template.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let collectionView = collectionView as? ALKIndexedCollectionView
        else {
            return UICollectionViewCell()
        }

        guard let message = viewModel.messageForRow(indexPath: IndexPath(row: 0, section: collectionView.tag)),
              let template = ALKGenericCardCollectionView.getCardTemplate(message: message),
              template.count > indexPath.row
        else {
            return UICollectionViewCell()
        }

        let cell: ALKGenericCardCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
        let card = template[indexPath.row]
        cell.update(card: card)
        cell.buttonSelected = { [weak self] tag, title, card in
            print("\(title), \(tag) button selected in generic card \(card)")
            guard let strongSelf = self else { return }
            strongSelf.cardTemplateSelected(tag: tag, title: title, template: card, message: message)
        }
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let message = viewModel.messageForRow(indexPath: IndexPath(row: 0, section: collectionView.tag)),
              let template = ALKGenericCardCollectionView.getCardTemplate(message: message),
              template.count > indexPath.row
        else {
            return CGSize(width: 0, height: 0)
        }
        if message.messageType == .cardTemplate {
            let width = view.frame.width - cardTemplateMargin

            let height = ALKGenericCardCell.rowHeight(card: template[indexPath.row], maxWidth: width)
            return CGSize(width: width, height: height)
        }
        return CGSize(width: view.frame.width - 50, height: 350)
    }
}

extension ALTopicDetail: ALKContextTitleDataType {
    public var titleText: String {
        return title ?? ""
    }

    public var subtitleText: String {
        return subtitle
    }

    public var imageURL: URL? {
        guard let urlStr = link, let url = URL(string: urlStr) else {
            return nil
        }
        return url
    }

    public var infoLabel1Text: String? {
        guard let key = key1, let value = value1 else {
            return nil
        }
        return "\(key): \(value)"
    }

    public var infoLabel2Text: String? {
        guard let key = key2, let value = value2 else {
            return nil
        }
        return "\(key): \(value)"
    }
}
