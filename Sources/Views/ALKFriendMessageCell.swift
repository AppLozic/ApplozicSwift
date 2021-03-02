//
//  ALKFriendMessageCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 12/06/19.
//

import ApplozicCore
import Kingfisher
import UIKit

// TODO: Handle padding for reply name and reply message when preview image isn't visible.
open class ALKFriendMessageCell: ALKMessageCell {
    private var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 18.5
        layer.masksToBounds = true
        imv.isUserInteractionEnabled = true
        return imv
    }()

    private var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.isOpaque = true
        return label
    }()

    enum Padding {
        enum NameLabel {
            static let top: CGFloat = 6.0
            static let left: CGFloat = 57.0
            static let right: CGFloat = 57.0
            static let height: CGFloat = 16.0
        }

        enum AvatarImage {
            static let top: CGFloat = 18.0
            static let left: CGFloat = 9.0
            static let width: CGFloat = 37.0
            static let height: CGFloat = 37.0
        }

        enum BubbleView {
            static let left: CGFloat = 5.0
            static let right: CGFloat = 95.0
            static let bottom: CGFloat = 5.0
        }

        enum ReplyView {
            static let left: CGFloat = 5.0
            static let right: CGFloat = 5.0
            static let top: CGFloat = 5.0
            static let height: CGFloat = 80.0
        }

        enum ReplyNameLabel {
            static let right: CGFloat = 10.0
            static let height: CGFloat = 30.0
        }

        enum ReplyMessageLabel {
            static let right: CGFloat = 10.0
            static let top: CGFloat = 5.0
            static let height: CGFloat = 30.0
        }

        enum PreviewImageView {
            static let height: CGFloat = 50.0
            static let width: CGFloat = 70.0
            static let right: CGFloat = 5.0
            static let top: CGFloat = 10.0
        }

        enum MessageView {
            static let top: CGFloat = 5
            static let bottom: CGFloat = 10
        }

        enum TimeLabel {
            static let bottom: CGFloat = 2
            static let left: CGFloat = 10
        }
    }

    static let bubbleViewLeftPadding: CGFloat = {
        /// For edge add extra 5
        guard ALKMessageStyle.receivedBubble.style == .edge else {
            return ALKMessageStyle.receivedBubble.widthPadding
        }
        return ALKMessageStyle.receivedBubble.widthPadding + 5
    }()

    override func setupViews() {
        super.setupViews()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTappedAction))
        avatarImageView.addGestureRecognizer(tapGesture)

        contentView.addViewsForAutolayout(views: [avatarImageView, nameLabel])
        contentView.bringSubviewToFront(messageView)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: Padding.NameLabel.top
            ),
            nameLabel.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Padding.NameLabel.left
            ),
            nameLabel.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Padding.NameLabel.right
            ),
            nameLabel.heightAnchor.constraint(equalToConstant: Padding.NameLabel.height),

            avatarImageView.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: Padding.AvatarImage.top
            ),
            avatarImageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: Padding.AvatarImage.left
            ),
            avatarImageView.heightAnchor.constraint(equalToConstant: Padding.AvatarImage.height),
            avatarImageView.widthAnchor.constraint(equalToConstant: Padding.AvatarImage.width),

            emailBottomView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor
            ),
            emailBottomViewHeight,
            emailBottomView.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor
            ),
            emailBottomView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor
            ),

            bubbleView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor),
            bubbleView.bottomAnchor.constraint(
                equalTo: emailBottomView.topAnchor,
                constant: -Padding.BubbleView.bottom
            ),
            bubbleView.leadingAnchor.constraint(
                equalTo: avatarImageView.trailingAnchor,
                constant: Padding.BubbleView.left
            ),
            bubbleView.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor,
                constant: -Padding.BubbleView.right
            ),

            replyView.topAnchor.constraint(
                equalTo: bubbleView.topAnchor,
                constant: Padding.ReplyView.top
            ),
            replyView.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.replyViewHeightIdentifier
            ),
            replyView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: Padding.ReplyView.left
            ),
            replyView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -Padding.ReplyView.right
            ),

            previewImageView.topAnchor.constraint(
                equalTo: replyView.topAnchor,
                constant: Padding.PreviewImageView.top
            ),
            previewImageView.trailingAnchor.constraint(
                lessThanOrEqualTo: replyView.trailingAnchor,
                constant: -Padding.PreviewImageView.right
            ),
            previewImageView.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.PreviewImage.height
            ),
            previewImageView.widthAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.PreviewImage.width
            ),

            replyNameLabel.leadingAnchor.constraint(equalTo: replyView.leadingAnchor),
            replyNameLabel.topAnchor.constraint(equalTo: replyView.topAnchor),
            replyNameLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: previewImageView.leadingAnchor,
                constant: -Padding.ReplyNameLabel.right
            ),
            replyNameLabel.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.ReplyNameLabel.height
            ),

            replyMessageLabel.leadingAnchor.constraint(equalTo: replyView.leadingAnchor),
            replyMessageLabel.topAnchor.constraint(
                equalTo: replyNameLabel.bottomAnchor,
                constant: Padding.ReplyMessageLabel.top
            ),
            replyMessageLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: previewImageView.leadingAnchor,
                constant: -Padding.ReplyMessageLabel.right
            ),
            replyMessageLabel.heightAnchor.constraintEqualToAnchor(
                constant: 0,
                identifier: ConstraintIdentifier.ReplyMessageLabel.height
            ),

            emailTopView.topAnchor.constraint(
                equalTo: replyView.bottomAnchor,
                constant: Padding.MessageView.top
            ),
            emailTopView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -ALKMessageStyle.receivedBubble.widthPadding
            ),
            emailTopView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: ALKFriendMessageCell.bubbleViewLeftPadding
            ),
            emailTopHeight,

            messageView.topAnchor.constraint(
                equalTo: emailTopView.bottomAnchor
            ),
            messageView.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: -Padding.MessageView.bottom
            ),
            messageView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -ALKMessageStyle.receivedBubble.widthPadding
            ),
            messageView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: ALKFriendMessageCell.bubbleViewLeftPadding
            ),

            timeLabel.leadingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: Padding.TimeLabel.left
            ),
            timeLabel.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: Padding.TimeLabel.bottom
            ),
        ])

        let linktapGesture = UITapGestureRecognizer(target: self, action: #selector(viewEmailTappedAction))
        emailBottomView.emailLinkLabel.addGestureRecognizer(linktapGesture)
    }

    override func setupStyle() {
        super.setupStyle()

        nameLabel.setStyle(ALKMessageStyle.displayName)
        messageView.setStyle(ALKMessageStyle.receivedMessage)
        bubbleView.setStyle(ALKMessageStyle.receivedBubble, isReceiverSide: true)
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(
            viewModel: viewModel,
            messageStyle: ALKMessageStyle.receivedMessage,
            mentionStyle: ALKMessageStyle.receivedMention
        )

        if viewModel.isReplyMessage {
            guard
                let metadata = viewModel.metadata,
                let replyId = metadata[AL_MESSAGE_REPLY_KEY] as? String,
                let actualMessage = getMessageFor(key: replyId)
            else { return }
            showReplyView(true)
            if actualMessage.messageType == .text || actualMessage.messageType == .html {
                previewImageView.constraint(withIdentifier: ConstraintIdentifier.PreviewImage.height)?.constant = 0
            } else {
                previewImageView.constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?.constant = Padding.PreviewImageView.width
            }
        } else {
            showReplyView(false)
        }

        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            avatarImageView.image = placeHolder
        }

        nameLabel.text = viewModel.displayName
    }

    class func rowHeigh(
        viewModel: ALKMessageViewModel,
        width: CGFloat,
        displayNames: ((Set<String>) -> ([String: String]?))?
    ) -> CGFloat {
        let minimumHeight = Padding.AvatarImage.top + Padding.AvatarImage.height + 5
        /// Calculating available width for messageView
        let leftSpacing = Padding.AvatarImage.left + Padding.AvatarImage.width + Padding.BubbleView.left + bubbleViewLeftPadding
        let rightSpacing = Padding.BubbleView.right + ALKMessageStyle.receivedBubble.widthPadding
        let messageWidth = width - (leftSpacing + rightSpacing)

        /// Calculating messageHeight
        let messageHeight = super
            .messageHeight(
                viewModel: viewModel,
                width: messageWidth,
                font: ALKMessageStyle.receivedMessage.font,
                mentionStyle: ALKMessageStyle.receivedMention,
                displayNames: displayNames
            )
        let heightPadding = Padding.NameLabel.top + Padding.NameLabel.height + Padding.ReplyView.top + Padding.MessageView.top + Padding.MessageView.bottom + Padding.BubbleView.bottom

        let totalHeight = max(messageHeight + heightPadding, minimumHeight)

        guard let metadata = viewModel.metadata,
              metadata[AL_MESSAGE_REPLY_KEY] as? String != nil
        else {
            return totalHeight
        }
        return totalHeight + Padding.ReplyView.height
    }

    @objc private func avatarTappedAction() {
        avatarTapped?()
    }

    @objc private func viewEmailTappedAction() {
        let text = localizedString(forKey: "EmailWebViewTitle", withDefaultValue: SystemMessage.NavbarTitle.emailWebViewTitle, fileName: localizedStringFileName)

        let emailWebViewController = ALKWebViewController(htmlString: viewModel?.message ?? "", url: nil, title: text)
        let pushAssist = ALPushAssist()
        pushAssist.topViewController.navigationController?.pushViewController(emailWebViewController, animated: true)
    }

    // MARK: - ChatMenuCell

    override func menuWillShow(_ sender: Any) {
        super.menuWillShow(sender)
        if ALKMessageStyle.receivedBubble.style == .edge {
            bubbleView.image = bubbleView.imageBubble(
                for: ALKMessageStyle.receivedBubble.style,
                isReceiverSide: true,
                showHangOverImage: true
            )
        }
    }

    override func menuWillHide(_ sender: Any) {
        super.menuWillHide(sender)
        if ALKMessageStyle.receivedBubble.style == .edge {
            bubbleView.image = bubbleView.imageBubble(
                for: ALKMessageStyle.receivedBubble.style,
                isReceiverSide: true,
                showHangOverImage: false
            )
        }
    }

    private func showReplyView(_ show: Bool) {
        replyView
            .constraint(withIdentifier: ConstraintIdentifier.replyViewHeightIdentifier)?
            .constant = show ? Padding.ReplyView.height : 0
        replyNameLabel
            .constraint(withIdentifier: ConstraintIdentifier.ReplyNameLabel.height)?
            .constant = show ? Padding.ReplyNameLabel.height : 0
        replyMessageLabel
            .constraint(withIdentifier: ConstraintIdentifier.ReplyMessageLabel.height)?
            .constant = show ? Padding.ReplyMessageLabel.height : 0
        previewImageView
            .constraint(withIdentifier: ConstraintIdentifier.PreviewImage.height)?
            .constant = show ? Padding.PreviewImageView.height : 0
        previewImageView
            .constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?
            .constant = show ? Padding.PreviewImageView.width : 0

        replyView.isHidden = !show
        replyNameLabel.isHidden = !show
        replyMessageLabel.isHidden = !show
        previewImageView.isHidden = !show
    }
}
