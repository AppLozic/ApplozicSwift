//
//  SentButtonsView.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 23/09/19.
//

import Foundation

public class SentButtonsCell: UITableViewCell {
    // MARK: - Public properties

    enum ViewPadding {
        enum StateView {
            static let bottom: CGFloat = 3
            static let right: CGFloat = 2
            static let height: CGFloat = 9
            static let width: CGFloat = 17
        }

        enum TimeLabel {
            static let right: CGFloat = 2
            static let left: CGFloat = 2
            static let bottom: CGFloat = 2
            static let maxWidth: CGFloat = 200
        }

        static let maxWidth = UIScreen.main.bounds.width
        static let messageViewPadding = Padding(left: ChatCellPadding.SentMessage.Message.left,
                                                right: ChatCellPadding.SentMessage.Message.right,
                                                top: 0,
                                                bottom: 0)
    }

    // MARK: - Fileprivate properties

    fileprivate var timeLabel: UILabel = {
        let lb = UILabel()
        lb.isOpaque = true
        return lb
    }()

    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    fileprivate lazy var buttons = SuggestedReplyView()
    fileprivate lazy var messageView = MessageView(
        bubbleStyle: MessageTheme.sentMessage.bubble,
        messageStyle: MessageTheme.sentMessage.message,
        maxWidth: ViewPadding.maxWidth
    )
    fileprivate lazy var messageViewHeight = messageView.heightAnchor.constraint(equalToConstant: 0)
    fileprivate lazy var timeLabelWidth = timeLabel.widthAnchor.constraint(equalToConstant: 0)
    fileprivate lazy var timeLabelHeight = timeLabel.heightAnchor.constraint(equalToConstant: 0)

    // MARK: - Initializer

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Updates the `SentButtonsCell`.
    ///
    /// - Parameter model: object that conforms to `SuggestedReplyMessage`
    public func update(model: SuggestedReplyMessage) {
        guard model.message.isMyMessage else {
            print("😱😱😱Inconsistent information passed to the view.😱😱😱")
            print("For SentMessage value of isMyMessage should be true")
            return
        }
        let isMessageEmpty = model.message.isMessageEmpty()
        messageViewHeight.constant = isMessageEmpty ? 0 : SentMessageViewSizeCalculator().rowHeight(messageModel: model.message,
                                                                                                    maxWidth: ViewPadding.maxWidth,
                                                                                                    padding: ViewPadding.messageViewPadding)
        if !isMessageEmpty {
            messageView.update(model: model.message)
        }

        messageView.updateHeighOfView(hideView: isMessageEmpty, model: model.message)

        let buttonsWidth = ViewPadding.maxWidth -
            (ChatCellPadding.SentMessage.QuickReply.left + ChatCellPadding.SentMessage.QuickReply.right)
        buttons.update(model: model, maxWidth: buttonsWidth)

        // Set time
        timeLabel.text = model.message.time
        timeLabel.setStyle(MessageTheme.sentMessage.time)

        let timeLabelSize = model.message.time.rectWithConstrainedWidth(
            ViewPadding.TimeLabel.maxWidth,
            font: MessageTheme.sentMessage.time.font
        )

        timeLabelHeight.constant = timeLabelSize.height.rounded(.up)
        timeLabelWidth.constant = timeLabelSize.width.rounded(.up)
        setStatusStyle(model: model, statusView: stateView, MessageTheme.messageStatus)
    }

    /// It is used to get exact height of `SentButtonsCell` using messageModel, width and padding
    ///
    /// - Parameters:
    ///   - model: object that conforms to `SuggestedReplyMessage`
    /// - Returns: exact height of the view.
    public static func rowHeight(model: SuggestedReplyMessage) -> CGFloat {
        var height: CGFloat = 0
        let isMessageEmpty = model.message.isMessageEmpty()

        let timeLabelSize = model.message.time.rectWithConstrainedWidth(
            ViewPadding.TimeLabel.maxWidth,
            font: MessageTheme.sentMessage.time.font
        )

        if !isMessageEmpty {
            height = SentMessageViewSizeCalculator().rowHeight(messageModel: model.message,
                                                               maxWidth: ViewPadding.maxWidth,
                                                               padding: ViewPadding.messageViewPadding)
        }

        let quickReplyViewWidth = ViewPadding.maxWidth -
            (ChatCellPadding.SentMessage.QuickReply.left + ChatCellPadding.SentMessage.QuickReply.right)

        return height
            + SuggestedReplyView.rowHeight(model: model, maxWidth: quickReplyViewWidth)
            + ChatCellPadding.SentMessage.QuickReply.top
            + ChatCellPadding.SentMessage.QuickReply.bottom + timeLabelSize.height.rounded(.up) + ViewPadding.TimeLabel.bottom
    }

    private func setupConstraints() {
        addViewsForAutolayout(views: [messageView, buttons, stateView, timeLabel])
        NSLayoutConstraint.activate([
            messageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            messageView.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor,
                constant: ChatCellPadding.SentMessage.Message.left
            ),
            messageView.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -ChatCellPadding.SentMessage.Message.right
            ),
            messageViewHeight,
            buttons.topAnchor.constraint(
                equalTo: messageView.bottomAnchor,
                constant: ChatCellPadding.SentMessage.QuickReply.top
            ),
            buttons.trailingAnchor.constraint(
                equalTo: contentView.trailingAnchor,
                constant: -ChatCellPadding.SentMessage.QuickReply.right
            ),
            buttons.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: ChatCellPadding.SentMessage.QuickReply.left),
            buttons.bottomAnchor.constraint(
                equalTo: timeLabel.topAnchor,
                constant: -ChatCellPadding.SentMessage.QuickReply.bottom
            ),
            stateView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1 * ViewPadding.StateView.bottom),
            stateView.trailingAnchor.constraint(equalTo: buttons.trailingAnchor, constant: -1 * ViewPadding.StateView.right),
            stateView.heightAnchor.constraint(equalToConstant: ViewPadding.StateView.height),
            stateView.widthAnchor.constraint(equalToConstant: ViewPadding.StateView.width),
            timeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1 * ViewPadding.TimeLabel.bottom),
            timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: ViewPadding.TimeLabel.left),
            timeLabelWidth,
            timeLabelHeight,
            timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -1 * ViewPadding.TimeLabel.right),
        ])
    }

    func setStatusStyle(
        model: SuggestedReplyMessage,
        statusView: UIImageView,
        _ style: MessageTheme.SentMessageStatus,
        _ size: CGSize = CGSize(width: 17, height: 9)
    ) {
        guard let status = model.message.status,
              let statusIcon = style.statusIcons[status] else { return }
        switch statusIcon {
        case let .templateImageWithTint(image, tintColor):
            statusView.image = image
                .imageFlippedForRightToLeftLayoutDirection()
                .scale(with: size)?
                .withRenderingMode(.alwaysTemplate)
            statusView.tintColor = tintColor
        case let .normalImage(image):
            statusView.image = image
                .imageFlippedForRightToLeftLayoutDirection()
                .scale(with: size)?
                .withRenderingMode(.alwaysOriginal)
        case .none:
            statusView.image = nil
        }
    }
}
