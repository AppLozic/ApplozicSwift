//
//  SentFAQMessageView.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 04/06/19.
//

import Foundation
import UIKit

/// FAQMessageCell for sender side.
///
/// It contains `FAQMessageView` and `SentMessageView`
/// It also contains `Config` which is used to configure views properties. Values can be changed for customizations.
public class SentFAQMessageCell: UITableViewCell {
    // MARK: Public properties

    /// Configuration to adjust padding and maxWidth for the view.
    public enum Config {
        public static var maxWidth = UIScreen.main.bounds.width

        public enum MessageView {
            /// Left padding of `MessageView`
            public static var leftPadding: CGFloat = 60.0
            /// Bottom padding of `MessageView`
            public static var rightPadding: CGFloat = 10.0
            public static var topPadding: CGFloat = 10.0
            public static var bottomPadding: CGFloat = 0.0
        }

        public enum StateView {
            public static var rightPadding: CGFloat = 2.0
            public static var bottomPadding: CGFloat = 5
        }

        public enum TimeLabel {
            public static var maxWidth: CGFloat = 200.0
            public static var rightPadding: CGFloat = 2.0
            public static var bottomPadding: CGFloat = 2.0
        }

        public enum FaqView {
            public static var topPadding: CGFloat = 5.0
            public static var rightPadding: CGFloat = 10.0
            public static var leftPadding: CGFloat = 20.0
        }
    }

    // MARK: Fileprivate properties

    fileprivate var timeLabel: UILabel = {
        let lb = UILabel()
        lb.setStyle(MessageTheme.sentMessage.time)
        lb.isOpaque = true
        return lb
    }()

    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    fileprivate lazy var timeLabelWidth = timeLabel.widthAnchor.constraint(equalToConstant: 0)
    fileprivate lazy var timeLabelHeight = timeLabel.heightAnchor.constraint(equalToConstant: 0)

    fileprivate lazy var stateViewWidth = stateView.widthAnchor.constraint(equalToConstant: 0)
    fileprivate lazy var stateViewHeight = stateView.heightAnchor.constraint(equalToConstant: 0)

    fileprivate lazy var messageView = MessageView(
        bubbleStyle: MessageTheme.sentMessage.bubble,
        messageStyle: MessageTheme.sentMessage.message,
        maxWidth: Config.maxWidth
    )

    fileprivate lazy var faqView = FAQMessageView(
        frame: .zero,
        faqStyle: FAQMessageTheme.sentMessage,
        alignLeft: false
    )

    fileprivate var messageViewPadding: Padding

    fileprivate lazy var messageViewHeight = messageView.heightAnchor.constraint(equalToConstant: 0)

    static let faqWidth = Config.maxWidth - Config.FaqView.leftPadding - Config.FaqView.rightPadding

    // MARK: Initializer

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        messageViewPadding = Padding(left: Config.MessageView.leftPadding,
                                     right: Config.MessageView.rightPadding,
                                     top: Config.MessageView.topPadding,
                                     bottom: Config.MessageView.bottomPadding)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public methods

    /// It updates `SentFAQMessageCell`. Sets FAQmessage, text message, time, status.
    ///
    /// - Parameter model: `FAQMessage` used to update the cell.
    public func update(model: FAQMessage) {
        guard model.message.isMyMessage else {
            print("😱😱😱Inconsistent information passed to the view.😱😱😱")
            print("For Sender view isMyMessage should be true")
            return
        }
        let isMessageEmpty = model.message.isMessageEmpty()

        messageViewHeight.constant = isMessageEmpty ? 0 : SentMessageViewSizeCalculator().rowHeight(messageModel: model.message, maxWidth: Config.maxWidth, padding: messageViewPadding)
        if !isMessageEmpty {
            messageView.update(model: model.message)
        }

        messageView.updateHeighOfView(hideView: isMessageEmpty, model: model.message)

        setStatusStyle(statusView: stateView, MessageTheme.messageStatus, model: model.message)

        // Set time and update timeLabel constraint.
        timeLabel.text = model.message.time
        let timeLabelSize = model.message.time.rectWithConstrainedWidth(Config.TimeLabel.maxWidth,
                                                                        font: MessageTheme.sentMessage.time.font)
        timeLabelHeight.constant = timeLabelSize.height.rounded(.up)
        timeLabelWidth.constant = timeLabelSize.width.rounded(.up) // This is amazing😱😱😱... a diff in fraction can trim.
        layoutIfNeeded()

        faqView.update(model: model, maxWidth: SentFAQMessageCell.faqWidth)
        /// Set frame
        let height = SentFAQMessageCell.rowHeight(model: model)
        frame.size = CGSize(width: Config.maxWidth, height: height)
    }

    /// It's used to get the exact height of cell.
    ///
    /// - Parameter model: `FAQMessage` used for updating the cell.
    /// - Returns: Exact height of cell.
    public class func rowHeight(model: FAQMessage) -> CGFloat {
        return FAQMessageSizeCalculator().rowHeight(model: model, maxWidth: Config.maxWidth)
    }

    // MARK: - Private helper methods

    private func setupConstraints() {
        addViewsForAutolayout(views: [messageView, faqView, stateView, timeLabel])

        NSLayoutConstraint.activate([
            messageView.topAnchor.constraint(equalTo: topAnchor, constant: Config.MessageView.topPadding),
            messageView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: Config.MessageView.leftPadding),
            messageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -1 * Config.MessageView.rightPadding),
            messageViewHeight,
            faqView.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: Config.FaqView.topPadding),
            faqView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Config.FaqView.leftPadding),
            faqView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Config.FaqView.rightPadding),
            faqView.bottomAnchor.constraint(equalTo: timeLabel.topAnchor),
            stateViewWidth,
            stateViewHeight,
            stateView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1 * Config.StateView.bottomPadding),
            stateView.trailingAnchor.constraint(equalTo: faqView.trailingAnchor, constant: -1 * Config.StateView.rightPadding),

            timeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1 * Config.TimeLabel.bottomPadding),
            timeLabelWidth,
            timeLabelHeight,
            timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -1 * Config.TimeLabel.rightPadding),
        ])
    }

    func setStatusStyle(
        statusView: UIImageView,
        _ style: MessageTheme.SentMessageStatus,
        _ size: CGSize = CGSize(width: 17, height: 9), model: Message
    ) {
        guard let status = model.status, let statusIcon = style.statusIcons[status] else { return }

        switch statusIcon {
        case let .templateImageWithTint(image, tintColor):
            statusView.image = image
                .imageFlippedForRightToLeftLayoutDirection()
                .scale(with: size)?
                .withRenderingMode(.alwaysTemplate)
            statusView.tintColor = tintColor
            stateViewWidth.constant = size.width
            stateViewHeight.constant = size.height
        case let .normalImage(image):
            statusView.image = image
                .imageFlippedForRightToLeftLayoutDirection()
                .scale(with: size)?
                .withRenderingMode(.alwaysOriginal)
            stateViewWidth.constant = size.width
            stateViewHeight.constant = size.height
        case .none:
            statusView.image = nil
            stateViewWidth.constant = 0
            stateViewHeight.constant = 0
        }
    }
}
