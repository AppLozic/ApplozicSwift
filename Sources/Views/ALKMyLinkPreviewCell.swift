import ApplozicCore
import Foundation

class ALKMyLinkPreviewCell: ALKLinkPreviewBaseCell {
    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    static var bubbleViewRightPadding: CGFloat = {
        /// For edge add extra 5
        guard ALKMessageStyle.sentBubble.style == .edge else {
            return ALKMessageStyle.sentBubble.widthPadding
        }
        return ALKMessageStyle.sentBubble.widthPadding + 5
    }()

    enum Padding {
        enum ReplyView {
            static let height: CGFloat = 80.0
            static let left: CGFloat = 5.0
            static let right: CGFloat = 5.0
            static let top: CGFloat = 5.0
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
            static let right: CGFloat = 10.0
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = 5.0
        }

        enum MessageView {
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = 10.0
        }

        enum BubbleView {
            static let left: CGFloat = 95.0
            static let bottom: CGFloat = 8.0
            static let right: CGFloat = 10.0
        }

        enum StateView {
            static let height: CGFloat = 9.0
            static let width: CGFloat = 17.0
            static let right: CGFloat = 2.0
        }

        enum LinkView {
            static let height: CGFloat = 90.0
            static let top: CGFloat = 5.0
            static let left: CGFloat = 10.0
            static let right: CGFloat = 8.0
        }

        enum TimeLabel {
            static let left: CGFloat = 2.0
            static let bottom: CGFloat = 2.0
        }
    }

    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [stateView])

        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bubbleView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor,
                constant: Padding.BubbleView.left
            ),
            bubbleView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -Padding.BubbleView.right
            ),

            emailTopView.topAnchor.constraint(
                equalTo: bubbleView.topAnchor,
                constant: Padding.MessageView.top
            ),
            emailTopView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: ALKMessageStyle.sentBubble.widthPadding
            ),
            emailTopView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -ALKMyMessageCell.bubbleViewRightPadding
            ),
            emailTopHeight,

            replyView.topAnchor.constraint(
                equalTo: emailTopView.bottomAnchor,
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
                equalTo: replyNameLabel.topAnchor,
                constant: Padding.PreviewImageView.top
            ),
            previewImageView.trailingAnchor.constraint(
                equalTo: replyView.trailingAnchor,
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
            emailBottomView.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -Padding.BubbleView.bottom * 0.7
            ),
            emailBottomViewHeight,
            emailBottomView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor
            ),
            emailBottomView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor
            ),
            bubbleView.bottomAnchor.constraint(
                equalTo: emailBottomView.topAnchor,
                constant: -Padding.BubbleView.bottom * 0.3
            ),

            linkView.topAnchor.constraint(
                equalTo: replyView.bottomAnchor,
                constant: Padding.LinkView.top
            ),
            linkView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: Padding.LinkView.left
            ),
            linkView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -Padding.LinkView.right
            ),
            linkView.heightAnchor.constraint(equalToConstant: Padding.LinkView.height),
            messageView.topAnchor.constraint(
                equalTo: linkView.bottomAnchor
            ),
            messageView.leadingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: ALKMessageStyle.sentBubble.widthPadding
            ),
            messageView.trailingAnchor.constraint(
                equalTo: bubbleView.trailingAnchor,
                constant: -ALKMyMessageCell.bubbleViewRightPadding
            ),
            messageView.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: -Padding.MessageView.bottom
            ),
            stateView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor),
            stateView.trailingAnchor.constraint(
                equalTo: bubbleView.leadingAnchor,
                constant: -Padding.StateView.right
            ),

            timeLabel.trailingAnchor.constraint(
                equalTo: stateView.leadingAnchor,
                constant: -Padding.TimeLabel.left
            ),
            timeLabel.bottomAnchor.constraint(
                equalTo: bubbleView.bottomAnchor,
                constant: Padding.TimeLabel.bottom
            ),
        ])
    }

    override open func setupStyle() {
        super.setupStyle()
        messageView.setStyle(ALKMessageStyle.sentMessage)
        bubbleView.setStyle(ALKMessageStyle.sentBubble, isReceiverSide: false)
        setStatusStyle(statusView: stateView, ALKMessageStyle.messageStatus)
    }

    override open func update(viewModel: ALKMessageViewModel) {
        super.update(
            viewModel: viewModel,
            messageStyle: ALKMessageStyle.sentMessage,
            mentionStyle: ALKMessageStyle.sentMention
        )

        if viewModel.isReplyMessage {
            guard
                let metadata = viewModel.metadata,
                let replyId = metadata[AL_MESSAGE_REPLY_KEY] as? String,
                let actualMessage = getMessageFor(key: replyId)
            else { return }
            showReplyView(true)
            if actualMessage.messageType == .text || actualMessage.messageType == .html {
                previewImageView.constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?.constant = 0
            } else {
                previewImageView.constraint(withIdentifier: ConstraintIdentifier.PreviewImage.width)?.constant = Padding.PreviewImageView.width
            }
        } else {
            showReplyView(false)
        }
        setStatusStyle(statusView: stateView, ALKMessageStyle.messageStatus)
        linkView.update(url: url, identifier: viewModel.identifier)
    }

    class func rowHeigh(viewModel: ALKMessageViewModel,
                        width: CGFloat,
                        displayNames: ((Set<String>) -> ([String: String]?))?) -> CGFloat
    {
        /// Calculating messageHeight
        let leftSpacing = Padding.BubbleView.left + ALKMessageStyle.sentBubble.widthPadding
        let rightSpacing = Padding.BubbleView.right + bubbleViewRightPadding
        let messageWidth = width - (leftSpacing + rightSpacing)
        let messageHeight = super
            .messageHeight(
                viewModel: viewModel,
                width: messageWidth,
                font: ALKMessageStyle.sentMessage.font,
                mentionStyle: ALKMessageStyle.sentMention,
                displayNames: displayNames
            )

        let heightPadding = Padding.MessageView.top + Padding.MessageView.bottom + Padding.BubbleView.bottom + Padding.ReplyView.top

        let linkURL = ALKLinkPreviewManager.extractURLAndAddInCache(from: viewModel.message, identifier: viewModel.identifier)

        var isReplyMessage = false
        if let metadata = viewModel.metadata,
           metadata[AL_MESSAGE_REPLY_KEY] as? String != nil
        {
            isReplyMessage = true
        }

        if isReplyMessage, linkURL != nil {
            let linkViewHeight = ALKLinkView.height() + Padding.LinkView.top
            return messageHeight + heightPadding + Padding.ReplyView.height + linkViewHeight
        } else if isReplyMessage {
            return messageHeight + Padding.ReplyView.height
        } else if linkURL != nil {
            return messageHeight + heightPadding + ALKLinkView.height() + Padding.LinkView.top
        }

        return messageHeight + heightPadding
    }

    fileprivate func showReplyView(_ show: Bool) {
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

    // MARK: - ChatMenuCell

    override func menuWillShow(_ sender: Any) {
        super.menuWillShow(sender)
        if ALKMessageStyle.sentBubble.style == .edge {
            bubbleView.image = bubbleView.imageBubble(
                for: ALKMessageStyle.sentBubble.style,
                isReceiverSide: false,
                showHangOverImage: true
            )
        }
    }

    override func menuWillHide(_ sender: Any) {
        super.menuWillHide(sender)
        if ALKMessageStyle.sentBubble.style == .edge {
            bubbleView.image = bubbleView.imageBubble(
                for: ALKMessageStyle.sentBubble.style,
                isReceiverSide: false,
                showHangOverImage: false
            )
        }
    }
}
