//
//  ALKFriendContactMessageCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 19/04/19.
//

import Kingfisher

class ALKFriendContactMessageCell: ALKContactMessageBaseCell {
    enum Padding {
        enum Name {
            static let left: CGFloat = 10
            static let right: CGFloat = 57
            static let top: CGFloat = 6
            static let height: CGFloat = 16
        }

        enum Image {
            static let left: CGFloat = 9
            static let top: CGFloat = 18
            static let width: CGFloat = 37
            static let height: CGFloat = 37
        }

        enum Contact {
            static let left: CGFloat = 10
            static let top: CGFloat = 4
            static let multiplier: CGFloat = 0.5
            static let bottom: CGFloat = 2
        }

        enum Time {
            static let left: CGFloat = 10
        }
    }

    fileprivate var timeLabel = UILabel(frame: .zero)

    public var avatarImageView: UIImageView = {
        let imv = UIImageView()
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
        label.isOpaque = true
        return label
    }()

    override func setupViews() {
        setupConstraints()
    }

    override func update(viewModel: ALKMessageViewModel) {
        loadingIndicator.startLoading(localizationFileName: localizedStringFileName)
        contactView.isHidden = true
        if let filePath = viewModel.filePath {
            updateContactDetails(key: viewModel.identifier, filePath: filePath)
        }
        timeLabel.text = viewModel.time
        timeLabel.setStyle(ALKMessageStyle.time)

        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)

        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            avatarImageView.image = placeHolder
        }

        nameLabel.text = viewModel.displayName
        nameLabel.setStyle(ALKMessageStyle.displayName)
    }

    override func setupStyle() {
        super.setupStyle()
        contactView.setStyle(
            itemColor: ALKMessageStyle.receivedMessage.text,
            bubbleStyle: ALKMessageStyle.receivedBubble, isReceiverSide: true
        )
    }

    class func rowHeight() -> CGFloat {
        var height = ContactView.height()
        height += Padding.Name.top + Padding.Name.height // Name height
        height += Padding.Contact.top + Padding.Contact.bottom // Contact padding
        return height + 5 // Extra padding.
    }

    private func setupConstraints() {
        contentView.addViewsForAutolayout(views: [avatarImageView, nameLabel, contactView, timeLabel, loadingIndicator])
        contentView.bringSubviewToFront(loadingIndicator)

        avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.Image.top).isActive = true
        avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.Image.left).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: Padding.Image.width).isActive = true
        avatarImageView.widthAnchor.constraint(equalToConstant: Padding.Image.width).isActive = true

        nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.Name.top).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Padding.Name.left).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.Name.right).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: Padding.Name.height).isActive = true

        contactView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Padding.Contact.top).isActive = true
        contactView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Padding.Contact.left).isActive = true
        contactView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: Padding.Contact.multiplier).isActive = true
        contactView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -Padding.Contact.bottom).isActive = true

        loadingIndicator.trailingAnchor.constraint(equalTo: contactView.trailingAnchor).isActive = true
        loadingIndicator.topAnchor.constraint(equalTo: contactView.topAnchor).isActive = true
        loadingIndicator.bottomAnchor.constraint(equalTo: contactView.bottomAnchor).isActive = true
        loadingIndicator.leadingAnchor.constraint(equalTo: contactView.leadingAnchor).isActive = true

        timeLabel.leadingAnchor.constraint(equalTo: contactView.trailingAnchor, constant: Padding.Time.left).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: contactView.bottomAnchor, constant: Padding.Contact.bottom).isActive = true
    }
}
