//
//  ALKFriendGenericCardCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 05/12/18.
//

import ApplozicCore
import Foundation
import Kingfisher

open class ALKFriendGenericCardMessageCell: ALKGenericCardBaseCell {
    enum ViewPadding {
        enum NameLabel {
            static let top: CGFloat = 6
            static let leading: CGFloat = 57
            static let trailing: CGFloat = 57
            static let height: CGFloat = 16
        }

        enum AvatarImageView {
            static let top: CGFloat = 18
            static let leading: CGFloat = 9
            static let height: CGFloat = 37
            static let width: CGFloat = 37
        }

        enum TimeLabel {
            static var leading: CGFloat = 2.0
            static var top: CGFloat = 2.0
            static let maxWidth: CGFloat = 200
        }

        static let maxWidth = UIScreen.main.bounds.width
            - (ViewPadding.AvatarImageView.width + ViewPadding.AvatarImageView.leading)
        static let messageViewPadding = Padding(left: ChatCellPadding.ReceivedMessage.Message.left,
                                                right: ChatCellPadding.ReceivedMessage.Message.right,
                                                top: ChatCellPadding.ReceivedMessage.Message.top,
                                                bottom: 0)
    }

    fileprivate var timeLabel: UILabel = {
        let lb = UILabel()
        lb.isOpaque = true
        return lb
    }()

    fileprivate var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 18.5
        layer.masksToBounds = true
        imv.isUserInteractionEnabled = true
        return imv
    }()

    fileprivate var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.isOpaque = true
        return label
    }()

    fileprivate lazy var timeLabelWidth = timeLabel.widthAnchor.constraint(equalToConstant: 0)
    fileprivate lazy var timeLabelHeight = timeLabel.heightAnchor.constraint(equalToConstant: 0)

    fileprivate lazy var messageView = MessageView(
        bubbleStyle: MessageTheme.receivedMessage.bubble,
        messageStyle: MessageTheme.receivedMessage.message,
        maxWidth: ViewPadding.maxWidth - (ViewPadding.messageViewPadding.left + ViewPadding.messageViewPadding.right)
    )
    // fileprivate var messageViewPadding: Padding
    lazy var messageViewHeight = self.messageView.heightAnchor.constraint(equalToConstant: 0)

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func update(viewModel: ALKMessageViewModel, width: CGFloat) {
        let isMessageEmpty = viewModel.isMessageEmpty
        let model = viewModel.messageDetails()

        messageViewHeight.constant = isMessageEmpty ? 0 :
            ReceivedMessageViewSizeCalculator().rowHeight(messageModel: model, maxWidth: ViewPadding.maxWidth, padding: ViewPadding.messageViewPadding)
        if !isMessageEmpty {
            messageView.update(model: model)
        }
        messageView.updateHeighOfView(hideView: isMessageEmpty, model: model)
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)

        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            avatarImageView.image = placeHolder
        }

        nameLabel.text = viewModel.displayName
        nameLabel.setStyle(ALKMessageStyle.displayName)

        super.update(viewModel: viewModel, width: width)

        timeLabel.setStyle(ALKMessageStyle.time)
        timeLabel.text = viewModel.time
        let timeLabelSize = viewModel.time!.rectWithConstrainedWidth(
            ViewPadding.TimeLabel.maxWidth,
            font: ALKMessageStyle.time.font
        )

        timeLabelHeight.constant = timeLabelSize.height.rounded(.up)
        timeLabelWidth.constant = timeLabelSize.width.rounded(.up)
        layoutIfNeeded()
    }

    override func setupViews() {
        super.setupViews()
        setupCollectionView()

        contentView.addViewsForAutolayout(views: [collectionView, messageView, nameLabel, avatarImageView, timeLabel])
        contentView.bringSubviewToFront(messageView)

        nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: ViewPadding.NameLabel.top).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ViewPadding.NameLabel.leading).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ViewPadding.NameLabel.trailing).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: ViewPadding.NameLabel.height).isActive = true

        avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: ViewPadding.AvatarImageView.top).isActive = true
        avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ViewPadding.AvatarImageView.leading).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: ViewPadding.AvatarImageView.height).isActive = true
        avatarImageView.widthAnchor.constraint(equalToConstant: ViewPadding.AvatarImageView.width).isActive = true

        let leftPadding = ChatCellPadding.ReceivedMessage.Message.left
        let rightPadding = ChatCellPadding.ReceivedMessage.Message.right
        messageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor).isActive = true
        messageView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: leftPadding).isActive = true
        messageView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -1 * rightPadding).isActive = true
        messageViewHeight.isActive = true

        let templateLeftPadding = CGFloat(ALKMessageStyle.receivedBubble.widthPadding)
        collectionView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: templateLeftPadding).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: ALKFriendGenericCardMessageCell.cardTopPadding).isActive = true
        collectionView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: CommonConstraintIdentifier.collectionView.rawValue).isActive = true
        timeLabel.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: ViewPadding.TimeLabel.leading).isActive = true
        timeLabel.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: ViewPadding.TimeLabel.top).isActive = true
        timeLabelWidth.isActive = true
        timeLabelHeight.isActive = true
        timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor).isActive = true
    }

    override open class func rowHeigh(viewModel: ALKMessageViewModel, width: CGFloat) -> CGFloat {
        let isMessageEmpty = viewModel.isMessageEmpty
        var height: CGFloat = 0

        let timeLabelSize = viewModel.time!.rectWithConstrainedWidth(
            ViewPadding.TimeLabel.maxWidth,
            font: ALKMessageStyle.time.font
        )

        if isMessageEmpty {
            height += ViewPadding.NameLabel.top +
                ViewPadding.NameLabel.height
        } else {
            let model = viewModel.messageDetails()
            height = ReceivedMessageViewSizeCalculator().rowHeight(messageModel: model, maxWidth: ViewPadding.maxWidth, padding: ViewPadding.messageViewPadding) +
                ViewPadding.NameLabel.top +
                ViewPadding.NameLabel.height
        }

        let cardHeight = super.cardHeightFor(message: viewModel, width: width)
        return cardHeight +
            height +
            10 +
            timeLabelSize.height.rounded(.up) +
            ViewPadding.TimeLabel.top // Extra 10 below complete view. Modify this for club/unclub.
    }

    private func setupCollectionView() {
        let layout = TopAlignedFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.scrollDirection = .horizontal
        collectionView = ALKGenericCardCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
    }
}
