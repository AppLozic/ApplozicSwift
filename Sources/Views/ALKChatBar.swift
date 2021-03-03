//
//  ALKChatBar.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation
import UIKit

// swiftlint:disable:next type_body_length
open class ALKChatBar: UIView, Localizable {
    var configuration: ALKConfiguration!

    public var chatBarConfiguration: ALKChatBarConfiguration {
        return configuration.chatBar
    }

    public var isMicButtonHidden: Bool!

    public enum ButtonMode {
        case send
        case media
    }

    public enum ActionType {
        case sendText(UIButton, NSAttributedString)
        case chatBarTextBeginEdit
        case chatBarTextChange(UIButton)
        case sendVoice(NSData)
        case startVideoRecord
        case startVoiceRecord
        case showImagePicker
        case showLocation
        case noVoiceRecordPermission
        case mic(UIButton)
        case more(UIButton)
        case cameraButtonClicked(UIButton)
        case shareContact
        case showDocumentPicker
    }

    public var action: ((ActionType) -> Void)?

    var poweredByMessageTextView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.isEditable = false
        textView.textContainer.maximumNumberOfLines = 1
        textView.textContainer.lineBreakMode = .byTruncatingTail
        textView.backgroundColor = UIColor.darkGray
        textView.dataDetectorTypes = .link
        textView.linkTextAttributes = [.foregroundColor: UIColor.blue,
                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
        textView.isScrollEnabled = false
        textView.delaysContentTouches = false
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.textContainerInset = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.contentInset = .zero
        return textView
    }()

    public var autocompletionView: UITableView!

    open lazy var soundRec: ALKAudioRecorderView = {
        let view = ALKAudioRecorderView(frame: CGRect.zero, configuration: self.configuration)
        view.layer.masksToBounds = true
        return view
    }()

    /// A header view which will be present on top of the chat bar.
    /// Use this to add custom views on top. It's default height will be 0.
    /// Make sure to set the height using `headerViewHeight` property.
    open var headerView: UIView = {
        let view = UIView(frame: CGRect.zero)
        view.backgroundColor = UIColor.clear
        view.accessibilityIdentifier = "Header view"
        return view
    }()

    /// Use this to set `headerView`'s height. Default height is 0.
    open var headerViewHeight: Double = 0 {
        didSet {
            headerView.constraint(withIdentifier: ConstraintIdentifier.headerViewHeight.rawValue)?.constant = CGFloat(headerViewHeight)
        }
    }

    public let textView: ALKChatBarTextView = {
        let tv = ALKChatBarTextView()
        tv.setBackgroundColor(UIColor.color(.none))
        tv.scrollsToTop = false
        tv.autocapitalizationType = .sentences
        tv.accessibilityIdentifier = "chatTextView"
        return tv
    }()

    open var frameView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = .clear
        view.contentMode = .scaleToFill
        view.isUserInteractionEnabled = false
        return view
    }()

    open var grayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.isUserInteractionEnabled = false
        return view
    }()

    open lazy var placeHolder: UITextView = {
        let view = UITextView()
        view.setFont(ALKChatBarConfiguration.TextView.placeholder.font)
        view.setTextColor(ALKChatBarConfiguration.TextView.placeholder.text)
        view.text = localizedString(forKey: "ChatHere", withDefaultValue: SystemMessage.Information.ChatHere, fileName: configuration.localizedStringFileName)
        view.isUserInteractionEnabled = false
        view.isScrollEnabled = false
        view.scrollsToTop = false
        view.changeTextDirection()
        view.setBackgroundColor(.color(.none))
        return view
    }()

    #if SPEECH_REC
        open lazy var micButton: SpeechToTextButton = {
            let button = SpeechToTextButton(
                textView: textView,
                localizedStringFileName: configuration.localizedStringFileName
            )
            button.layer.masksToBounds = true
            button.accessibilityIdentifier = "MicButton"
            return button
        }()
    #else
        open var micButton: AudioRecordButton = {
            let button = AudioRecordButton(frame: CGRect())
            button.layer.masksToBounds = true
            button.accessibilityIdentifier = "MicButton"
            return button
        }()
    #endif

    open var photoButton: UIButton = {
        let bt = UIButton(type: .custom)
        bt.accessibilityIdentifier = "photoButtonInConversationScreen"
        return bt
    }()

    open var galleryButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = "galleryButtonInConversationScreen"
        return button
    }()

    open var plusButton: UIButton = {
        let bt = UIButton(type: .custom)
        var image = UIImage(named: "icon_more_menu", in: Bundle.applozic, compatibleWith: nil)
        image = image?.imageFlippedForRightToLeftLayoutDirection()
        bt.setImage(image, for: .normal)
        return bt
    }()

    open var locationButton: UIButton = {
        let bt = UIButton(type: .custom)
        bt.accessibilityIdentifier = "locationButtonInConversationScreen"
        return bt
    }()

    open var contactButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = "contactButtonInConversationScreen"
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        return button
    }()

    open var documentButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = "documentButtonInConversationScreen"
        return button
    }()

    open var lineImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "line", in: Bundle.applozic, compatibleWith: nil))
        return imageView
    }()

    open lazy var sendButton: UIButton = {
        let bt = UIButton(type: .custom)
        bt.accessibilityIdentifier = "sendButton"
        return bt
    }()

    open var lineView: UIView = {
        let view = UIView()
        let layer = view.layer
        view.backgroundColor = UIColor(red: 217.0 / 255.0, green: 217.0 / 255.0, blue: 217.0 / 255.0, alpha: 1.0)
        return view
    }()

    open var bottomGrayView: UIView = {
        let view = UIView()
        view.setBackgroundColor(.background(.grayEF))
        view.isUserInteractionEnabled = false
        return view
    }()

    open var videoButton: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = "videoButtonInConversationScreen"
        return button
    }()

    /// Returns true if the textView is first responder.
    open var isTextViewFirstResponder: Bool {
        return textView.isFirstResponder
    }

    var isMediaViewHidden = false {
        didSet {
            if isMediaViewHidden {
                bottomGrayView.constraint(withIdentifier: ConstraintIdentifier.mediaBackgroudViewHeight.rawValue)?.constant = 0
                attachmentButtonStackView.constraint(withIdentifier: ConstraintIdentifier.mediaStackViewHeight.rawValue)?.constant = 0

            } else {
                bottomGrayView.constraint(withIdentifier: ConstraintIdentifier.mediaBackgroudViewHeight.rawValue)?.constant = 45
                attachmentButtonStackView.constraint(withIdentifier: ConstraintIdentifier.mediaStackViewHeight.rawValue)?.constant = 25
            }
        }
    }

    lazy var defaultTextAttributes: [NSAttributedString.Key: Any] = {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 4.0
        let attrs = [
            NSAttributedString.Key.paragraphStyle: style,
            NSAttributedString.Key.font: ALKChatBarConfiguration.TextView.text.font,
            NSAttributedString.Key.foregroundColor: ALKChatBarConfiguration.TextView.text.text,
        ]
        return attrs
    }() {
        didSet {
            textView.typingAttributes = defaultTextAttributes
        }
    }

    private var attachmentButtonStackView: UIStackView = {
        let attachmentStack = UIStackView(frame: CGRect.zero)
        return attachmentStack
    }()

    fileprivate var textViewHeighConstrain: NSLayoutConstraint?
    fileprivate let textViewHeigh: CGFloat = 40.0
    fileprivate let textViewHeighMax: CGFloat = 102.2 + 8.0

    fileprivate var textViewTrailingWithSend: NSLayoutConstraint?
    fileprivate var textViewTrailingWithMic: NSLayoutConstraint?

    private enum ConstraintIdentifier: String {
        case mediaBackgroudViewHeight
        case poweredByMessageHeight
        case headerViewHeight
        case mediaStackViewHeight
    }

    @objc func tapped(button: UIButton) {
        switch button {
        case sendButton:
            let attributedText = textView.attributedText ?? NSAttributedString(string: textView.text)
            if attributedText.string.lengthOfBytes(using: .utf8) > 0 {
                action?(.sendText(button, attributedText))
            }
        case plusButton:
            action?(.more(button))
        case photoButton:
            action?(.cameraButtonClicked(button))
        case videoButton:
            action?(.startVideoRecord)
        case galleryButton:
            action?(.showImagePicker)
        case locationButton:
            action?(.showLocation)
        case contactButton:
            action?(.shareContact)
        case documentButton:
            action?(.showDocumentPicker)
        default: break
        }
    }

    fileprivate func toggleKeyboardType(textView: UITextView) {
        // If the keyboard used is not English, the keyboard is changed. (.asciiCapable -> .emailAddress)
        textView.keyboardType = .emailAddress
        textView.reloadInputViews()
        textView.keyboardType = .default
        textView.reloadInputViews()
    }

    private weak var comingSoonDelegate: UIView?

    var chatIdentifier: String?
    var bottomBackgroundColor: UIColor = .background(.grayEF) {
        didSet {
            bottomGrayView.backgroundColor = bottomBackgroundColor
            backgroundColor = bottomBackgroundColor
        }
    }

    private func initializeView() {
        if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
            textView.textAlignment = .right
        }

        micButton.setAudioRecDelegate(recorderDelegate: self)
        soundRec.setAudioRecViewDelegate(recorderDelegate: self)
        textView.typingAttributes = defaultTextAttributes
        textView.add(delegate: self)
        bottomGrayView.backgroundColor = bottomBackgroundColor
        backgroundColor = bottomBackgroundColor
        translatesAutoresizingMaskIntoConstraints = false

        plusButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        photoButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        galleryButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        locationButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        contactButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        documentButton.addTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        let appSettingsUserDefaults = ALKAppSettingsUserDefaults()
        let buttonTintColor = appSettingsUserDefaults.getAttachmentIconsTintColor()
        setupAttachment(buttonIcons: chatBarConfiguration.attachmentIcons, tintColor: buttonTintColor)
        setupConstraints()
        micButton.setButtonTintColor(color: buttonTintColor)
        var image = configuration.sendMessageIcon
        image = image?.imageFlippedForRightToLeftLayoutDirection()
        if !chatBarConfiguration.disableButtonTintColor {
            image = image?.withRenderingMode(.alwaysTemplate)
            sendButton.imageView?.tintColor = buttonTintColor
        }
        sendButton.setImage(image, for: .normal)

        if configuration.hideLineImageFromChatBar {
            lineImageView.isHidden = true
        }
        updateMediaViewVisibility()
    }

    func setComingSoonDelegate(delegate: UIView) {
        comingSoonDelegate = delegate
    }

    open func clear() {
        textView.text = ""
        clearTextInTextView()
        textView.attributedText = nil
        toggleKeyboardType(textView: textView)
    }

    func hideMicButton() {
        isMicButtonHidden = true
        micButton.isHidden = true
        sendButton.isHidden = false
    }

    public required init(frame: CGRect, configuration: ALKConfiguration) {
        super.init(frame: frame)
        self.configuration = configuration
        isMicButtonHidden = configuration.hideAudioOptionInChatBar
        initializeView()
    }

    deinit {
        plusButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        photoButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        sendButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        videoButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        galleryButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        locationButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        contactButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
        documentButton.removeTarget(self, action: #selector(tapped(button:)), for: .touchUpInside)
    }

    private var isNeedInitText = true

    override open func layoutSubviews() {
        super.layoutSubviews()

        if isNeedInitText {
            guard chatIdentifier != nil else {
                return
            }

            isNeedInitText = false
        }
    }

    // swiftlint:disable:next function_body_length
    private func setupConstraints(
        maxLength: CGFloat = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    ) {
        plusButton.isHidden = true

        var bottomAnchor: NSLayoutYAxisAnchor {
            if #available(iOS 11.0, *) {
                return self.safeAreaLayoutGuide.bottomAnchor
            } else {
                return self.bottomAnchor
            }
        }

        var buttonSpacing: CGFloat = 25
        if maxLength <= 568.0 { buttonSpacing = 20 } // For iPhone 5

        func buttonsForOptions(_ options: ALKChatBarConfiguration.AttachmentOptions) -> [UIButton] {
            var buttons: [UIButton] = []
            switch options {
            case .all:
                for option in AttachmentType.allCases {
                    buttons.append(buttonForAttachmentType(option))
                }
            case let .some(options):
                for option in options {
                    buttons.append(buttonForAttachmentType(option))
                }
            case .none:
                print("Nothing to add")
            }
            return buttons
        }

        func buttonForAttachmentType(
            _ type: AttachmentType
        ) -> UIButton {
            switch type {
            case .contact:
                return contactButton
            case .gallery:
                return galleryButton
            case .location:
                return locationButton
            case .camera:
                return photoButton
            case .video:
                return videoButton
            case .document:
                return documentButton
            }
        }

        let buttonSize = CGSize(width: 25, height: 25)
        let attachmentButtons = buttonsForOptions(chatBarConfiguration.optionsToShow)
        attachmentButtons.forEach { attachmentButtonStackView.addArrangedSubview($0) }
        attachmentButtonStackView.spacing = buttonSpacing

        addViewsForAutolayout(views: [
            headerView,
            bottomGrayView,
            plusButton,
            attachmentButtonStackView,
            grayView,
            textView,
            sendButton,
            micButton,
            lineImageView,
            lineView,
            frameView,
            placeHolder,
            soundRec,
            poweredByMessageTextView,
        ])

        lineView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true
        lineView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        lineView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true

        headerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        headerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        headerView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.headerViewHeight.rawValue).isActive = true

        let buttonheightConstraints = attachmentButtonStackView.subviews
            .map { $0.widthAnchor.constraint(equalToConstant: buttonSize.width) }

        var stackViewConstraints = [
            attachmentButtonStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            attachmentButtonStackView.heightAnchor.constraintEqualToAnchor(
                constant: buttonSize.height,
                identifier: ConstraintIdentifier.mediaStackViewHeight.rawValue
            ),
            attachmentButtonStackView.centerYAnchor.constraint(equalTo: bottomGrayView.centerYAnchor),
        ]
        stackViewConstraints.append(contentsOf: buttonheightConstraints)
        NSLayoutConstraint.activate(stackViewConstraints)

        plusButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        plusButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        plusButton.widthAnchor.constraint(equalToConstant: 38).isActive = true
        plusButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true

        lineImageView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -15).isActive = true
        lineImageView.widthAnchor.constraint(equalToConstant: 2).isActive = true
        lineImageView.topAnchor.constraint(equalTo: textView.topAnchor, constant: 10).isActive = true
        lineImageView.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -10).isActive = true

        sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 28).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: 28).isActive = true
        sendButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -7).isActive = true

        micButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        micButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        micButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        micButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: -10).isActive = true

        if isMicButtonHidden {
            micButton.isHidden = true
        } else {
            sendButton.isHidden = true
        }

        textView.topAnchor.constraint(equalTo: poweredByMessageTextView.bottomAnchor, constant: 0).isActive = true
        textView.bottomAnchor.constraint(equalTo: bottomGrayView.topAnchor, constant: 0).isActive = true
        textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 3).isActive = true
        poweredByMessageTextView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        poweredByMessageTextView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        poweredByMessageTextView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.poweredByMessageHeight.rawValue).isActive = true
        poweredByMessageTextView.topAnchor.constraint(equalTo: headerView.bottomAnchor).isActive = true

        textView.trailingAnchor.constraint(equalTo: lineImageView.leadingAnchor).isActive = true

        textViewHeighConstrain = textView.heightAnchor.constraint(equalToConstant: textViewHeigh)
        textViewHeighConstrain?.isActive = true

        placeHolder.heightAnchor.constraint(equalToConstant: 35).isActive = true
        placeHolder.centerYAnchor.constraint(equalTo: textView.centerYAnchor, constant: 0).isActive = true
        placeHolder.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 0).isActive = true
        placeHolder.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 0).isActive = true

        soundRec.isHidden = true
        soundRec.topAnchor.constraint(equalTo: textView.topAnchor).isActive = true
        soundRec.bottomAnchor.constraint(equalTo: textView.bottomAnchor).isActive = true
        soundRec.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 0).isActive = true
        soundRec.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: 0).isActive = true

        frameView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 0).isActive = true
        frameView.bottomAnchor.constraint(equalTo: textView.bottomAnchor, constant: 0).isActive = true
        frameView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -4).isActive = true
        frameView.rightAnchor.constraint(equalTo: rightAnchor, constant: 2).isActive = true

        grayView.topAnchor.constraint(equalTo: frameView.topAnchor, constant: 0).isActive = true
        grayView.bottomAnchor.constraint(equalTo: frameView.bottomAnchor, constant: 0).isActive = true
        grayView.leftAnchor.constraint(equalTo: frameView.leftAnchor, constant: 0).isActive = true
        grayView.rightAnchor.constraint(equalTo: frameView.rightAnchor, constant: 0).isActive = true

        bottomGrayView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0).isActive = true
        bottomGrayView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.mediaBackgroudViewHeight.rawValue).isActive = true
        bottomGrayView.leftAnchor.constraint(equalTo: leftAnchor, constant: 0).isActive = true
        bottomGrayView.rightAnchor.constraint(equalTo: rightAnchor, constant: 0).isActive = true

        bringSubviewToFront(frameView)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func showPoweredByMessage() {
        poweredByMessageTextView.constraint(withIdentifier: ConstraintIdentifier.poweredByMessageHeight.rawValue)?.constant = 20
    }

    /// Use this to update the visibilty of attachment options
    /// after the view has been set up.
    ///
    /// Note: If hide is false then view's visibility will be
    /// changed based on `ALKChatBarConfiguration`s `optionsToShow`
    /// value.
    public func updateMediaViewVisibility(hide: Bool = false) {
        if hide {
            isMediaViewHidden = true
        } else if configuration.chatBar.optionsToShow != .none {
            isMediaViewHidden = false
        }
    }

    public func disableSendButton(isSendButtonDisabled: Bool) {
        sendButton.isEnabled = !isSendButtonDisabled
    }

    public func addTextView(delegate: UITextViewDelegate) {
        textView.add(delegate: delegate)
    }

    private func changeButton() {
        if soundRec.isHidden {
            soundRec.isHidden = false
            placeHolder.text = nil
            if placeHolder.isFirstResponder {
                placeHolder.resignFirstResponder()
            } else if textView.isFirstResponder {
                textView.resignFirstResponder()
            }
        } else {
            micButton.isSelected = false
            soundRec.isHidden = true
            resetToDefaultPlaceholderText()
        }
    }

    func stopRecording() {
        #if SPEECH_REC
            toggleButtonInChatBar(hide: false)
        #else
            soundRec.userDidStopRecording()
            micButton.isSelected = false
            soundRec.isHidden = true
            resetToDefaultPlaceholderText()
        #endif
    }

    func hideAudioOptionInChatBar() {
        guard !isMicButtonHidden else {
            micButton.isHidden = true
            return
        }
        micButton.isHidden = !textView.text.isEmpty
    }

    func toggleButtonInChatBar(hide: Bool) {
        if !isMicButtonHidden {
            sendButton.isHidden = hide
            micButton.isHidden = !hide
        }
    }

    func toggleUserInteractionForViews(enabled: Bool) {
        micButton.isUserInteractionEnabled = enabled
        sendButton.isUserInteractionEnabled = enabled
        soundRec.isUserInteractionEnabled = enabled
        photoButton.isUserInteractionEnabled = enabled
        videoButton.isUserInteractionEnabled = enabled
        locationButton.isUserInteractionEnabled = enabled
        galleryButton.isUserInteractionEnabled = enabled
        plusButton.isUserInteractionEnabled = enabled
        contactButton.isUserInteractionEnabled = enabled
        textView.isUserInteractionEnabled = enabled
    }

    func disableChat(message: String) {
        toggleUserInteractionForViews(enabled: false)
        placeHolder.text = message
        if !soundRec.isHidden {
            cancelAudioRecording()
        }
        if textView.text != nil {
            textView.text = ""
            clearTextInTextView()
        }
    }

    func enableChat() {
        guard soundRec.isHidden else { return }
        toggleUserInteractionForViews(enabled: true)
        resetToDefaultPlaceholderText()
    }

    func updateTextViewHeight(textView: UITextView, text: String) {
        let attributes = textView.typingAttributes
        let tv = UITextView(frame: textView.frame)
        tv.attributedText = NSAttributedString(string: text, attributes: attributes)

        let fixedWidth = textView.frame.size.width
        let size = tv.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))

        if let textViewHeighConstrain = self.textViewHeighConstrain, size.height != textViewHeighConstrain.constant {
            if size.height < textViewHeighMax {
                textViewHeighConstrain.constant = size.height > textViewHeigh ? size.height : textViewHeigh
            } else if textViewHeighConstrain.constant != textViewHeighMax {
                textViewHeighConstrain.constant = textViewHeighMax
            }

            textView.layoutIfNeeded()
        }
    }

    func setupAttachment(buttonIcons: [AttachmentType: UIImage?], tintColor: UIColor?) {
        func setup(
            image: UIImage?,
            to button: UIButton,
            withSize size: CGSize = CGSize(width: 25, height: 25)
        ) {
            var image = image?.imageFlippedForRightToLeftLayoutDirection()
            image = image?.scale(with: size)
            if tintColor != nil,
               !chatBarConfiguration.disableButtonTintColor
            {
                image = image?.withRenderingMode(.alwaysTemplate)
                button.imageView?.tintColor = tintColor
            }
            button.setImage(image, for: .normal)
        }

        for option in AttachmentType.allCases {
            switch option {
            case .contact:
                setup(image: buttonIcons[AttachmentType.contact] ?? nil, to: contactButton)
            case .camera:
                setup(image: buttonIcons[AttachmentType.camera] ?? nil, to: photoButton)
            case .gallery:
                setup(image: buttonIcons[AttachmentType.gallery] ?? nil, to: galleryButton)
            case .video:
                setup(image: buttonIcons[AttachmentType.video] ?? nil, to: videoButton)
            case .location:
                setup(image: buttonIcons[AttachmentType.location] ?? nil, to: locationButton)
            case .document:
                setup(image: buttonIcons[AttachmentType.document] ?? nil, to: documentButton)
            }
        }
    }

    func setDefaultText(_ text: String) {
        textView.text = text
    }
}

extension ALKChatBar: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        textView.typingAttributes = defaultTextAttributes
        if textView.text.isEmpty {
            clearTextInTextView()
        } else {
            placeHolder.isHidden = true
            placeHolder.alpha = 0
            if micButton.states != .recording {
                toggleButtonInChatBar(hide: false)
            }
            updateTextViewHeight(textView: textView, text: textView.text)
        }

        if let selectedTextRange = textView.selectedTextRange {
            let line = textView.caretRect(for: selectedTextRange.start)
            let overflow = line.origin.y + line.size.height - (textView.contentOffset.y + textView.bounds.size.height - textView.contentInset.bottom - textView.contentInset.top)

            if overflow > 0 {
                var offset = textView.contentOffset
                offset.y += overflow + 8.2 // leave 8.2 pixels margin

                textView.setContentOffset(offset, animated: false)
            }
        }
        action?(.chatBarTextChange(photoButton))
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
        action?(.chatBarTextBeginEdit)
        guard textView.text == nil || textView.text.isEmpty else { return }
        textView.changeTextDirection()
        placeHolder.changeTextDirection()
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            toggleButtonInChatBar(hide: true)
            if placeHolder.isHidden {
                placeHolder.isHidden = false
                placeHolder.alpha = 1.0

                DispatchQueue.main.async { [weak self] in
                    guard let weakSelf = self else { return }

                    weakSelf.textViewHeighConstrain?.constant = weakSelf.textViewHeigh
                    UIView.animate(withDuration: 0.15) {
                        weakSelf.layoutIfNeeded()
                    }
                }
            }
        }

        // clear inputview of textview
        textView.inputView = nil
        textView.reloadInputViews()
        guard textView.text == nil || textView.text.isEmpty else { return }
        textView.changeTextDirection()
        placeHolder.changeTextDirection()
    }

    func resetToDefaultPlaceholderText() {
        placeHolder.text = localizedString(forKey: "ChatHere", withDefaultValue: SystemMessage.Information.ChatHere, fileName: configuration.localizedStringFileName)
    }

    fileprivate func clearTextInTextView() {
        if textView.text.isEmpty {
            toggleButtonInChatBar(hide: true)
            if placeHolder.isHidden {
                placeHolder.isHidden = false
                placeHolder.alpha = 1.0

                textViewHeighConstrain?.constant = textViewHeigh
                layoutIfNeeded()
            }
        }
        textView.inputView = nil
        textView.reloadInputViews()
    }
}

extension ALKChatBar: ALKAudioRecorderProtocol {
    public func startRecordingAudio() {
        changeButton()
        action?(.startVoiceRecord)
        soundRec.userDidStartRecording()
    }

    public func finishRecordingAudio(soundData: NSData) {
        textView.resignFirstResponder()
        if soundRec.isRecordingTimeSufficient() {
            action?(.sendVoice(soundData))
        }
        stopRecording()
    }

    public func cancelRecordingAudio() {
        stopRecording()
    }

    public func permissionNotGrant() {
        action?(.noVoiceRecordPermission)
    }

    public func moveButton(location: CGPoint) {
        soundRec.moveView(location: location)
    }
}

extension ALKChatBar: ALKAudioRecorderViewProtocol {
    public func cancelAudioRecording() {
        #if !SPEECH_REC
            micButton.cancelAudioRecord()
        #endif
        stopRecording()
    }
}

extension UITextView {
    func hyperLink(mutableAttributedString: NSMutableAttributedString,
                   url: URL,
                   clickString: String)
    {
        let range = mutableAttributedString.string.range(of: clickString)

        guard let subStringRange = range else {
            return
        }

        mutableAttributedString.setAttributes([.link: url], range: NSRange(subStringRange, in: mutableAttributedString.string))
        attributedText = mutableAttributedString
        textAlignment = .center
        textColor = .white
    }
}
