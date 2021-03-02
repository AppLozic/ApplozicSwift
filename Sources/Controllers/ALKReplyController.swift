//
//  ALKReplyController.swift
//  ApplozicSwift
//
//  Created by apple on 01/07/19.
//

import Foundation

import ApplozicCore
import Kingfisher

class ALKReplyController: UIViewController, Localizable {
    enum ConstraintIdentifier {
        static let modelViewHeight = "modelViewHeight"
        static let messageTextViewHeight = "messageTextViewHeight"
    }

    enum Padding {
        enum ModelView {
            static let minHeightForMessageView: CGFloat = 230.0
            static let maxHeightForMessageView: CGFloat = 270.0
            static let heightForAttachmentView: CGFloat = 310.0
            static let left: CGFloat = 30.0
            static let right: CGFloat = 30.0
        }

        enum TitleLabel {
            static let top: CGFloat = 15.0
            static let left: CGFloat = 10.0
            static let right: CGFloat = 10.0
            static let height: CGFloat = 30.0
        }

        enum MessageLabel {
            static let bottom: CGFloat = 12.0
            static let left: CGFloat = 15.0
            static let right: CGFloat = 15.0
            static let height: CGFloat = 50.0
        }

        enum MessageTextView {
            static let top: CGFloat = 3.0
            static let left: CGFloat = 10.0
            static let right: CGFloat = 10.0
            static let maxHeight: CGFloat = 100.0
            static let minHeight: CGFloat = 60.0
        }

        enum AttachmentView {
            static let top: CGFloat = 3.0
            static let left: CGFloat = 10.0
            static let right: CGFloat = 10.0
            static let height: CGFloat = 150.0
        }

        enum ButtonUIView {
            static let height: CGFloat = 50.0
        }

        enum ConfirmButton {
            static let height: CGFloat = 50.0
        }

        enum AvatarImage {
            static let top: CGFloat = 35.0
            static let left: CGFloat = 9.0
            static let width: CGFloat = 25.0
            static let height: CGFloat = 25.0
        }
    }

    let configuration: ALKConfiguration
    let messageKey: String

    private let attachmentView = ALKAttatchmentView(frame: .zero)

    private let modalView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5
        return view
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor(red: 88 / 255.0, green: 87 / 255.0, blue: 87 / 255.0, alpha: 1.0)
        label.numberOfLines = 3
        label.font = Font.bold(size: 12.0).font()
        return label
    }()

    private var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 12
        layer.masksToBounds = true
        return imv
    }()

    private let messageView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.isUserInteractionEnabled = true
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.isEditable = false
        textView.dataDetectorTypes = .link
        textView.textColor = UIColor.gray
        textView.setFont(Font.normal(size: 14).font())
        textView.linkTextAttributes = [.foregroundColor: UIColor.blue,
                                       .underlineStyle: NSUnderlineStyle.single.rawValue]
        textView.delaysContentTouches = false
        textView.setBackgroundColor(UIColor(red: 249 / 255.0, green: 249 / 255.0, blue: 249 / 255.0, alpha: 1.0))
        return textView
    }()

    private let alertMessageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 4
        label.textColor = UIColor(red: 140 / 255.0, green: 140 / 255.0, blue: 140 / 255.0, alpha: 1.0)
        label.font = Font.light(size: 14.0).font()
        return label
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        let title = localizedString(forKey: "OkayMessage", withDefaultValue: SystemMessage.ButtonName.okay, fileName: configuration.localizedStringFileName)
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIView().tintColor, for: .normal)
        button.setFont(font: Font.normal(size: 16.0).font())
        button.setBackgroundColor(UIColor(red: 242.0 / 255.0, green: 242.0 / 255.0, blue: 242.0 / 255.0, alpha: 1.0))
        return button
    }()

    private let buttonUIView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 93.7, green: 93.7, blue: 93.7, alpha: 1.0)
        return view
    }()

    init(messageKey: String, configuration: ALKConfiguration) {
        self.messageKey = messageKey
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(10, green: 10, blue: 10, alpha: 0.2)
        view.isOpaque = false
        setupViews()
        proccessAndUpdateView()
    }

    func proccessAndUpdateView() {
        let messageDatabase = ALMessageDBService()
        guard let message = messageDatabase.getMessageByKey(messageKey) else {
            return
        }
        let infoMessage = localizedString(forKey: "ReplyInfoMessage", withDefaultValue: SystemMessage.Information.ReportInfoMessage, fileName: configuration.localizedStringFileName)
        alertMessageLabel.text = infoMessage

        if message.fileMeta != nil || message.isLocationMessage() {
            modalView.constraint(withIdentifier: ConstraintIdentifier.modelViewHeight)?.constant = Padding.ModelView.heightForAttachmentView
            attachmentView.isHidden = false
            messageView.isHidden = true
            attachmentView.update(message: message, localizationFileName: configuration.localizedStringFileName)
        } else {
            messageView.isHidden = false
            attachmentView.isHidden = true
            let height = message.message.heightWithConstrainedWidth(getMaxWidth(), font: Font.normal(size: 14).font())
            var modelViewHeight: CGFloat = 0
            var messasgeTextViewHeight: CGFloat = 0

            if height <= 35.0 {
                modelViewHeight = Padding.ModelView.minHeightForMessageView
                messasgeTextViewHeight = Padding.MessageTextView.minHeight
            } else {
                modelViewHeight = Padding.ModelView.maxHeightForMessageView
                messasgeTextViewHeight = Padding.MessageTextView.maxHeight
            }

            modalView.constraint(withIdentifier: ConstraintIdentifier.modelViewHeight)?.constant = modelViewHeight
            messageView.constraint(withIdentifier: ConstraintIdentifier.messageTextViewHeight)?.constant = messasgeTextViewHeight
            messageView.text = message.message
            messageView.sizeToFit()
        }
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        let contactService = ALContactService()
        let contact = contactService.loadContact(byKey: "userId", value: message.to)
        if let imageUrl = contact?.contactImageUrl, let url = URL(string: imageUrl) {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            avatarImageView.image = placeHolder
        }

        timeLabel.text = message.date.stringCompareCurrentDate()
    }

    @objc func tappedConfirmButton() {
        dismiss(animated: true, completion: nil)
    }

    func getMaxWidth() -> CGFloat {
        let modelPadding = Padding.ModelView.left + Padding.ModelView.right
        let avatarImagePadding = Padding.AvatarImage.left + Padding.AvatarImage.width
        let messageViewPadding = Padding.MessageTextView.left + Padding.MessageTextView.right
        let contentWidth = modelPadding + avatarImagePadding + messageViewPadding
        return view.bounds.width - contentWidth
    }

    func setupViews() {
        view.addViewsForAutolayout(views: [modalView])
        modalView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        modalView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        modalView.heightAnchor.constraintEqualToAnchor(
            constant: 0,
            identifier: ConstraintIdentifier.modelViewHeight
        ).isActive = true
        modalView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Padding.ModelView.left).isActive = true
        modalView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Padding.ModelView.right).isActive = true
        modalView.addViewsForAutolayout(views: [timeLabel, alertMessageLabel, buttonUIView, confirmButton, avatarImageView, messageView, attachmentView])
        modalView.bringSubviewToFront(confirmButton)
        modalView.bringSubviewToFront(messageView)

        avatarImageView.topAnchor.constraint(equalTo: modalView.topAnchor, constant: Padding.AvatarImage.top).isActive = true
        avatarImageView.leadingAnchor.constraint(
            equalTo: modalView.leadingAnchor,
            constant: Padding.AvatarImage.left
        ).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: Padding.AvatarImage.height).isActive = true
        avatarImageView.widthAnchor.constraint(equalToConstant: Padding.AvatarImage.width).isActive = true

        timeLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Padding.TitleLabel.left).isActive = true
        timeLabel.heightAnchor.constraint(equalToConstant: Padding.TitleLabel.height).isActive = true
        timeLabel.topAnchor.constraint(equalTo: modalView.topAnchor, constant: Padding.TitleLabel.top).isActive = true
        timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: modalView.trailingAnchor).isActive = true

        messageView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: Padding.MessageTextView.top).isActive = true
        messageView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor,
                                             constant: Padding.MessageTextView.left).isActive = true
        messageView.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -Padding.MessageTextView.right).isActive = true
        messageView.heightAnchor.constraintEqualToAnchor(
            constant: 0, identifier: ConstraintIdentifier.messageTextViewHeight
        ).isActive = true

        attachmentView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: Padding.AttachmentView.top).isActive = true
        attachmentView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Padding.AttachmentView.left).isActive = true
        attachmentView.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -Padding.AttachmentView.right).isActive = true
        attachmentView.heightAnchor.constraint(equalToConstant: Padding.AttachmentView.height).isActive = true

        alertMessageLabel.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: Padding.MessageLabel.left).isActive = true
        alertMessageLabel.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -Padding.MessageLabel.right).isActive = true
        alertMessageLabel.heightAnchor.constraint(equalToConstant: Padding.MessageLabel.height).isActive = true
        alertMessageLabel.bottomAnchor.constraint(equalTo: buttonUIView.topAnchor, constant: -Padding.MessageLabel.bottom).isActive = true

        buttonUIView.heightAnchor.constraint(equalToConstant: Padding.ButtonUIView.height).isActive = true
        buttonUIView.leadingAnchor.constraint(equalTo: modalView.leadingAnchor).isActive = true
        buttonUIView.trailingAnchor.constraint(equalTo: modalView.trailingAnchor).isActive = true
        buttonUIView.bottomAnchor.constraint(equalTo: modalView.bottomAnchor).isActive = true

        confirmButton.heightAnchor.constraint(equalToConstant: Padding.ConfirmButton.height).isActive = true
        confirmButton.leadingAnchor.constraint(equalTo: buttonUIView.leadingAnchor).isActive = true
        confirmButton.trailingAnchor.constraint(equalTo: buttonUIView.trailingAnchor).isActive = true
        confirmButton.bottomAnchor.constraint(equalTo: modalView.bottomAnchor).isActive = true

        confirmButton.addTarget(self, action: #selector(tappedConfirmButton), for: .touchUpInside)
    }
}
