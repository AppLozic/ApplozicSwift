//
//  ALKListTemplateCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 18/02/19.
//

import Kingfisher
import UIKit

// MARK: - `ALKMyMessageListTemplateCell` for sender side.

public class ALKMyMessageListTemplateCell: ALKListTemplateCell {
    enum ViewPadding {
        enum StateView {
            static let top: CGFloat = 3
            static let right: CGFloat = 2
            static let height: CGFloat = 9
            static let width: CGFloat = 17
        }

        enum TimeLabel {
            static let right: CGFloat = 2
            static let left: CGFloat = 2
            static let top: CGFloat = 2
            static let maxWidth: CGFloat = 200
        }

        enum ListTemplateView {
            static var top: CGFloat = 5.0
        }

        static let maxWidth = UIScreen.main.bounds.width
        static let messageViewPadding = Padding(left: ChatCellPadding.SentMessage.Message.left,
                                                right: ChatCellPadding.SentMessage.Message.right,
                                                top: 0,
                                                bottom: 0)
    }

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

    fileprivate lazy var timeLabelWidth = timeLabel.widthAnchor.constraint(equalToConstant: 0)
    fileprivate lazy var timeLabelHeight = timeLabel.heightAnchor.constraint(equalToConstant: 0)

    fileprivate lazy var messageView = MessageView(
        bubbleStyle: MessageTheme.sentMessage.bubble,
        messageStyle: MessageTheme.sentMessage.message,
        maxWidth: ViewPadding.maxWidth
    )
    lazy var messageViewHeight = messageView.heightAnchor.constraint(equalToConstant: 0)

    override public func update(viewModel: ALKMessageViewModel, maxWidth: CGFloat) {
        super.update(viewModel: viewModel)
        let isMessageEmpty = viewModel.isMessageEmpty
        let model = viewModel.messageDetails()

        messageViewHeight.constant = isMessageEmpty ? 0 :
            SentMessageViewSizeCalculator().rowHeight(messageModel: model,
                                                      maxWidth: ViewPadding.maxWidth,
                                                      padding: ViewPadding.messageViewPadding)
        if !isMessageEmpty {
            messageView.update(model: model)
        }

        messageView.updateHeighOfView(hideView: isMessageEmpty, model: model)

        super.update(viewModel: viewModel, maxWidth: maxWidth)

        // Set time
        timeLabel.text = viewModel.time
        timeLabel.setStyle(ALKMessageStyle.time)

        let timeLabelSize = viewModel.time!.rectWithConstrainedWidth(
            ViewPadding.TimeLabel.maxWidth,
            font: ALKMessageStyle.time.font
        )
        timeLabelHeight.constant = timeLabelSize.height.rounded(.up)
        timeLabelWidth.constant = timeLabelSize.width.rounded(.up)

        setStatusStyle(statusView: stateView, ALKMessageStyle.messageStatus)
    }

    override public class func rowHeight(viewModel: ALKMessageViewModel, maxWidth: CGFloat) -> CGFloat {
        var height: CGFloat = 0
        let model = viewModel.messageDetails()

        let timeLabelSize = viewModel.time!.rectWithConstrainedWidth(
            ViewPadding.TimeLabel.maxWidth,
            font: ALKMessageStyle.time.font
        )

        if !viewModel.isMessageEmpty {
            height = SentMessageViewSizeCalculator().rowHeight(messageModel: model,
                                                               maxWidth: ViewPadding.maxWidth,
                                                               padding: ViewPadding.messageViewPadding)
        }

        let templateHeight = super.rowHeight(viewModel: viewModel, maxWidth: maxWidth)
        return height +
            templateHeight +
            paddingBelowCell +
            timeLabelSize.height.rounded(.up) +
            ViewPadding.TimeLabel.top +
            ViewPadding.ListTemplateView.top
    }

    override func setupConstraints() {
        let leftPadding = ChatCellPadding.SentMessage.Message.left
        let rightPadding = ChatCellPadding.SentMessage.Message.right
        contentView.addViewsForAutolayout(views: [messageView, listTemplateView, stateView, timeLabel])
        messageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        messageView.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: leftPadding).isActive = true
        messageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1 * rightPadding).isActive = true
        messageViewHeight.isActive = true

        let width = CGFloat(ALKMessageStyle.sentBubble.widthPadding)
        let templateLeftPadding = leftPadding + width
        let templateRightPadding = rightPadding - width
        listTemplateView.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: ViewPadding.ListTemplateView.top).isActive = true
        listTemplateView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: templateLeftPadding).isActive = true
        listTemplateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1 * templateRightPadding).isActive = true
        listTemplateHeight.isActive = true

        stateView.topAnchor.constraint(equalTo: listTemplateView.bottomAnchor, constant: ViewPadding.StateView.top).isActive = true
        stateView.trailingAnchor.constraint(equalTo: listTemplateView.trailingAnchor, constant: -1 * ViewPadding.StateView.right).isActive = true
        stateView.heightAnchor.constraint(equalToConstant: ViewPadding.StateView.height).isActive = true
        stateView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        stateView.widthAnchor.constraint(equalToConstant: ViewPadding.StateView.width).isActive = true
        timeLabel.topAnchor.constraint(equalTo: listTemplateView.bottomAnchor, constant: ViewPadding.TimeLabel.top).isActive = true
        timeLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: ViewPadding.TimeLabel.left).isActive = true
        timeLabelWidth.isActive = true
        timeLabelHeight.isActive = true
        timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -1 * ViewPadding.TimeLabel.right).isActive = true
    }
}

// MARK: - `ALKFriendMessageListTemplateCell` for receiver side.

public class ALKFriendMessageListTemplateCell: ALKListTemplateCell {
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
            static var bottom: CGFloat = 2.0
            static var top: CGFloat = 2.0
            static let maxWidth: CGFloat = 200
        }

        enum ListTemplateView {
            static var top: CGFloat = 5.0
        }

        static let maxWidth = UIScreen.main.bounds.width
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
        maxWidth: ViewPadding.maxWidth
    )

    lazy var messageViewHeight = self.messageView.heightAnchor.constraint(equalToConstant: 0)

    override public func update(viewModel: ALKMessageViewModel, maxWidth: CGFloat) {
        super.update(viewModel: viewModel)
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

        timeLabel.text = viewModel.time
        let timeLabelSize = viewModel.time!.rectWithConstrainedWidth(
            ViewPadding.TimeLabel.maxWidth,
            font: ALKMessageStyle.time.font
        )

        timeLabelHeight.constant = timeLabelSize.height.rounded(.up)
        timeLabelWidth.constant = timeLabelSize.width.rounded(.up)

        timeLabel.setStyle(ALKMessageStyle.time)
        super.update(viewModel: viewModel, maxWidth: maxWidth)
    }

    override public class func rowHeight(viewModel: ALKMessageViewModel,
                                         maxWidth: CGFloat) -> CGFloat
    {
        let isMessageEmpty = viewModel.isMessageEmpty
        var height: CGFloat = 0
        let timeLabelSize = viewModel.time!.rectWithConstrainedWidth(
            ViewPadding.TimeLabel.maxWidth,
            font: ALKMessageStyle.time.font
        )
        let model = viewModel.messageDetails()

        if isMessageEmpty {
            height += ViewPadding.NameLabel.height +
                ViewPadding.NameLabel.top +
                ChatCellPadding.ReceivedMessage.Message.top
        } else {
            height = ReceivedMessageViewSizeCalculator().rowHeight(messageModel: model,
                                                                   maxWidth: ViewPadding.maxWidth,
                                                                   padding: ViewPadding.messageViewPadding) +
                ViewPadding.NameLabel.height +
                ViewPadding.NameLabel.top
        }

        let templateHeight = super.rowHeight(viewModel: viewModel, maxWidth: maxWidth)
        return height +
            templateHeight +
            paddingBelowCell +
            ViewPadding.ListTemplateView.top +
            ViewPadding.TimeLabel.top +
            ViewPadding.TimeLabel.bottom +
            timeLabelSize.height.rounded(.up) // Padding between messages
    }

    override func setupConstraints() {
        contentView.addViewsForAutolayout(views: [nameLabel, avatarImageView, messageView, listTemplateView, timeLabel])

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
        messageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: ChatCellPadding.ReceivedMessage.Message.top).isActive = true
        messageView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: leftPadding).isActive = true
        messageView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -1 * rightPadding).isActive = true
        messageViewHeight.isActive = true

        let width = CGFloat(ALKMessageStyle.receivedBubble.widthPadding)
        let templateLeftPadding = width
        let templateRightPadding = rightPadding - width
        listTemplateView.topAnchor.constraint(equalTo: messageView.bottomAnchor, constant: ViewPadding.ListTemplateView.top).isActive = true
        listTemplateView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: templateLeftPadding).isActive = true
        listTemplateView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -1 * templateRightPadding).isActive = true
        listTemplateHeight.isActive = true

        timeLabel.leadingAnchor.constraint(equalTo: listTemplateView.leadingAnchor, constant: ViewPadding.TimeLabel.leading).isActive = true
        timeLabel.topAnchor.constraint(equalTo: listTemplateView.bottomAnchor, constant: ViewPadding.TimeLabel.top).isActive = true
        timeLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -1 * ViewPadding.TimeLabel.bottom).isActive = true
        timeLabelWidth.isActive = true
        timeLabelHeight.isActive = true
        timeLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor).isActive = true
    }
}

// MARK: - `ALKListTemplateCell`

public class ALKListTemplateCell: ALKChatBaseCell<ALKMessageViewModel> {
    static var paddingBelowCell: CGFloat = 10

    var listTemplateView: ListTemplateView = {
        let view = ListTemplateView(frame: .zero)
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()

    lazy var listTemplateHeight = listTemplateView.heightAnchor.constraint(equalToConstant: 0)

    public var templateSelected: ((_ text: String?, _ action: ListTemplate.Action) -> Void)? {
        didSet {
            listTemplateView.selected = templateSelected
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(viewModel: ALKMessageViewModel, maxWidth _: CGFloat) {
        guard let metadata = viewModel.metadata,
              let template = try? TemplateDecoder.decode(ListTemplate.self, from: metadata)
        else {
            listTemplateView.isHidden = true
            layoutIfNeeded()
            return
        }
        listTemplateView.isHidden = false
        listTemplateView.update(item: template)
        listTemplateHeight.constant = ListTemplateView.rowHeight(template: template)
        layoutIfNeeded()
    }

    public class func rowHeight(viewModel: ALKMessageViewModel, maxWidth _: CGFloat) -> CGFloat {
        guard let metadata = viewModel.metadata,
              let template = try? TemplateDecoder.decode(ListTemplate.self, from: metadata)
        else {
            return CGFloat(0)
        }
        return ListTemplateView.rowHeight(template: template)
    }

    func setupConstraints() {
        fatalError("This method must be overriden.")
    }
}
