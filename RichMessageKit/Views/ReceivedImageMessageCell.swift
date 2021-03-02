//
//  ReceivedImageMessageView.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 20/05/19.
//

import UIKit

public class ReceivedImageMessageCell: UITableViewCell {
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
            public static var rightPadding: CGFloat = 60.0
            public static var topPadding: CGFloat = 2.0
        }

        public enum DisplayName {
            public static var height: CGFloat = 16.0
            public static var topPadding: CGFloat = 10.0

            /// Left padding of `DisplayName` from `ProfileImage`
            public static var leftPadding: CGFloat = 10.0

            /// Right padding of `DisplayName` from `ReceivedMessageView`. Used as lessThanOrEqualTo
            public static var rightPadding: CGFloat = 20.0
        }

        public enum ImageBubbleView {
            public static var topPadding: CGFloat = 5.0
            public static var leftPadding: CGFloat = 10.0
        }
    }

    // MARK: - Private properties

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

    fileprivate lazy var messageView = MessageView(
        bubbleStyle: MessageTheme.receivedMessage.bubble,
        messageStyle: MessageTheme.receivedMessage.message,
        maxWidth: Config.maxWidth
    )

    fileprivate lazy var timeLabelWidth = timeLabel.widthAnchor.constraint(equalToConstant: 0)
    fileprivate lazy var timeLabelHeight = timeLabel.heightAnchor.constraint(equalToConstant: 0)

    fileprivate var messageViewPadding: Padding
    fileprivate var imageBubble: ImageContainer
    fileprivate var imageBubbleWidth: CGFloat
    fileprivate lazy var messageViewHeight = messageView.heightAnchor.constraint(equalToConstant: 0)
    fileprivate lazy var imageBubbleHeight = imageBubble.heightAnchor.constraint(equalToConstant: 0)

    fileprivate var imageUrl: String?

    var imageTapped: (() -> Void)?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        messageViewPadding = Padding(left: Config.MessageView.leftPadding,
                                     right: Config.MessageView.rightPadding,
                                     top: Config.MessageView.topPadding,
                                     bottom: Config.MessageView.bottomPadding)
        imageBubble = ImageContainer(frame: .zero, maxWidth: Config.maxWidth, isMyMessage: false)
        imageBubbleWidth = Config.maxWidth * ImageBubbleTheme.receivedMessage.widthRatio
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
        setupGesture()
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Updated the `ImageMessageView`.
    ///
    /// - WARNING: `MessageModel`'s isMyMessage should be same as what is passed in initialization.
    /// - Parameter model: object that conforms to `MessageModel`
    public func update(model: ImageMessage) {
        guard !model.message.isMyMessage else {
            print("😱😱😱Inconsistent information passed to the view.😱😱😱")
            print("For Received view isMyMessage should be false")
            return
        }
        let isMessageEmpty = model.message.isMessageEmpty()

        let messageHeight = isMessageEmpty ? 0 : ReceivedMessageViewSizeCalculator().rowHeight(messageModel: model.message, maxWidth: Config.maxWidth, padding: messageViewPadding)
        messageViewHeight.constant = messageHeight

        imageBubbleHeight.constant = ImageBubbleSizeCalculator().rowHeight(model: model, maxWidth: Config.maxWidth)

        if !isMessageEmpty {
            messageView.update(model: model.message)
        }

        messageView.updateHeighOfView(hideView: isMessageEmpty, model: model.message)
        /// Set frame
        let height = ReceivedImageMessageCell.rowHeight(model: model)
        frame.size = CGSize(width: Config.maxWidth, height: height)

        imageUrl = model.url
        imageBubble.update(model: model)

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

    /// It is used to get exact height of `ImageMessageView` using messageModel, width and padding
    ///
    /// - NOTE: Font is not used. Change `ImageBubbleStyle.captionStyle.font`
    /// - Parameters:
    ///   - model: object that conforms to `ImageMessage`
    /// - Returns: exact height of the view.
    public static func rowHeight(model: ImageMessage) -> CGFloat {
        return ImageMessageViewSizeCalculator().rowHeight(model: model, maxWidth: Config.maxWidth)
    }

    private func setupConstraints() {
        contentView.addViewsForAutolayout(views: [avatarImageView, nameLabel, messageView, imageBubble, timeLabel])
        let nameRightPadding = max(Config.MessageView.rightPadding, Config.DisplayName.rightPadding)
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

            imageBubble.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: Config.ImageBubbleView.topPadding),
            imageBubble.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Config.ImageBubbleView.leftPadding),
            imageBubble.widthAnchor.constraint(equalToConstant: imageBubbleWidth),
            imageBubbleHeight,
            timeLabel.leadingAnchor.constraint(equalTo: imageBubble.leadingAnchor, constant: Config.TimeLabel.leftPadding),
            timeLabel.topAnchor.constraint(equalTo: imageBubble.bottomAnchor, constant: Config.TimeLabel.topPadding),
            timeLabelWidth,
            timeLabelHeight,
            timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -1 * Config.TimeLabel.rightPadding),
        ])
    }

    @objc private func imageTapAction() {
        imageTapped?()
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapAction))
        tapGesture.numberOfTapsRequired = 1
        imageBubble.addGestureRecognizer(tapGesture)
    }
}
