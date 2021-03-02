//
//  ReceivedFAQMessageCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 03/06/19.
//

import UIKit

/// FAQMessageCell for receiver side.
///
/// It contains `FAQMessageView` and `ReceivedMessageView`
/// It also contains `Config` which is used to configure views properties. Values can be changed for customizations.
/// For handling button clicks of FAQMessage, use faqSelected property.
public class ReceivedFAQMessageCell: UITableViewCell {
    // MARK: Public properties

    /// Configuration to adjust padding and maxWidth for the view.
    public enum Config {
        public static var maxWidth = UIScreen.main.bounds.width

        public enum MessageView {
            /// Left padding of `MessageView` from `ProfileImage`
            public static var leftPadding: CGFloat = 10.0

            /// Top padding of `MessageView` from `DisplayName`
            public static var topPadding: CGFloat = 2.0

            /// Bottom padding of `MessageView`
            public static var bottomPadding: CGFloat = 0.0

            /// Right padding of `MessageView`
            public static var rightPadding: CGFloat = 60.0
        }

        public enum ProfileImage {
            public static var width: CGFloat = 37.0
            public static var height: CGFloat = 37.0
            /// Top padding of `ProfileImage` from `DisplayName`
            public static var topPadding: CGFloat = 2.0
            public static var leftPadding: CGFloat = 10.0
        }

        public enum TimeLabel {
            /// Left padding of `TimeLabel` from `MessageView`
            public static var leftPadding: CGFloat = 2.0
            public static var maxWidth: CGFloat = 200.0
            public static var bottomPadding: CGFloat = 2.0
        }

        public enum DisplayName {
            public static var height: CGFloat = 16.0

            /// Left padding of `DisplayName` from `ProfileImage`
            public static var leftPadding: CGFloat = 10.0

            /// Right padding of `DisplayName` from `ReceivedMessageView`. Used as lessThanOrEqualTo
            public static var rightPadding: CGFloat = 20.0
            /// Top padding of `DisplayName`
            public static var topPadding: CGFloat = 2.0
        }

        public enum FAQView {
            public static var topPadding: CGFloat = 5.0
            public static var leftPadding: CGFloat = 10.0
            public static var rightPadding: CGFloat = 20
        }
    }

    /// Closure to get callbacks when buttons are tapped.
    public var faqSelected: ((_ index: Int?, _ title: String) -> Void)? {
        didSet {
            faqView.faqSelected = faqSelected
        }
    }

    // MARK: Fileprivate properties

    fileprivate lazy var faqView = FAQMessageView(
        frame: .zero,
        faqStyle: FAQMessageTheme.receivedMessage,
        alignLeft: true
    )

    fileprivate lazy var messageView = MessageView(
        bubbleStyle: MessageTheme.receivedMessage.bubble,
        messageStyle: MessageTheme.receivedMessage.message,
        maxWidth: Config.maxWidth
    )

    fileprivate var timeLabel: UILabel = {
        let lb = UILabel()
        lb.setStyle(MessageTheme.receivedMessage.time)
        lb.isOpaque = true
        return lb
    }()

    fileprivate var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.image = UIImage(named: "contact-placeholder", in: Bundle.richMessageKit, compatibleWith: nil)
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        imv.layer.cornerRadius = 18.5
        imv.layer.masksToBounds = true
        imv.isUserInteractionEnabled = true
        return imv
    }()

    fileprivate var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.setStyle(MessageTheme.receivedMessage.displayName)
        label.isOpaque = true
        return label
    }()

    fileprivate lazy var messageViewHeight = messageView.heightAnchor.constraint(equalToConstant: 0)

    fileprivate lazy var timeLabelWidth = timeLabel.widthAnchor.constraint(equalToConstant: 0)
    fileprivate lazy var timeLabelHeight = timeLabel.heightAnchor.constraint(equalToConstant: 0)

    fileprivate var messageViewPadding: Padding

    static var faqWidth = Config.maxWidth - Config.FAQView.rightPadding
        - (Config.ProfileImage.width
            + Config.FAQView.leftPadding)

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

    /// It updates `SentFAQMessageCell`.
    /// Sets FAQmessage, text message, time, name, profile image.
    ///
    /// - Parameter model: `FAQMessage` used to update the cell.
    public func update(model: FAQMessage) {
        guard !model.message.isMyMessage else {
            print("😱😱😱Inconsistent information passed to the view.😱😱😱")
            print("For Received view isMyMessage should be false")
            return
        }

        let isMessageEmpty = model.message.isMessageEmpty()

        messageViewHeight.constant = isMessageEmpty ? 0 : ReceivedMessageViewSizeCalculator().rowHeight(messageModel: model.message, maxWidth: Config.maxWidth, padding: messageViewPadding)

        if !isMessageEmpty {
            messageView.update(model: model.message)
        }

        faqView.update(model: model, maxWidth: ReceivedFAQMessageCell.faqWidth)
        /// Set frame
        let height = ReceivedFAQMessageCell.rowHeight(model: model)
        frame.size = CGSize(width: Config.maxWidth, height: height)

        // Set time

        timeLabel.text = model.message.time
        let timeLabelSize = model.message.time.rectWithConstrainedWidth(
            Config.TimeLabel.maxWidth,
            font: MessageTheme.receivedMessage.time.font
        )
        timeLabelHeight.constant = timeLabelSize.height.rounded(.up)
        timeLabelWidth.constant = timeLabelSize.width.rounded(.up)

        // Set name
        nameLabel.text = model.message.displayName

        guard let url = model.message.imageURL else { return }
        ImageCache.downloadImage(url: url) { [weak self] image in
            guard let image = image else { return }
            DispatchQueue.main.async {
                self?.avatarImageView.image = image
            }
        }
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
        let nameRightPadding = max(Config.MessageView.rightPadding, Config.DisplayName.rightPadding)
        addViewsForAutolayout(views: [avatarImageView, nameLabel, faqView, timeLabel, messageView])
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Config.ProfileImage.topPadding),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Config.ProfileImage.leftPadding),
            avatarImageView.widthAnchor.constraint(equalToConstant: Config.ProfileImage.width),
            avatarImageView.heightAnchor.constraint(equalToConstant: Config.ProfileImage.height),

            nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: Config.DisplayName.topPadding),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Config.DisplayName.leftPadding),
            nameLabel.heightAnchor.constraint(equalToConstant: Config.DisplayName.height),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -1 * nameRightPadding),

            messageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Config.MessageView.topPadding),
            messageView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Config.MessageView.leftPadding),
            messageViewHeight,
            messageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -1 * Config.MessageView.rightPadding),

            faqView.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: Config.FAQView.topPadding),
            faqView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Config.FAQView.leftPadding),
            faqView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Config.FAQView.rightPadding),
            faqView.bottomAnchor.constraint(equalTo: timeLabel.topAnchor),

            timeLabel.leadingAnchor.constraint(equalTo: faqView.leadingAnchor, constant: Config.TimeLabel.leftPadding),
            timeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1 * Config.TimeLabel.bottomPadding),
            timeLabelWidth,
            timeLabelHeight,
        ])
    }
}
