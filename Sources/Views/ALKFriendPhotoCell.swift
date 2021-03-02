//
//  FriendPhotoCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation
import Kingfisher

// MARK: - FriendPhotoCell

class ALKFriendPhotoCell: ALKPhotoCell {
    let appSettingsUserDefaults = ALKAppSettingsUserDefaults()
    private var avatarImageView: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        let layer = imv.layer
        layer.cornerRadius = 18.5
        layer.backgroundColor = UIColor.lightGray.cgColor
        layer.masksToBounds = true
        imv.isUserInteractionEnabled = true
        return imv
    }()

    private var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor.lightGray
        return label
    }()

    enum Padding {
        enum PhotoView {
            static let right: CGFloat = 56
        }
    }

    override class func topPadding() -> CGFloat {
        return 28
    }

    override class var messageTextFont: UIFont {
        return ALKMessageStyle.receivedMessage.font
    }

    override func setupStyle() {
        super.setupStyle()
        nameLabel.setStyle(ALKMessageStyle.displayName)
        captionLabel.font = ALKMessageStyle.receivedMessage.font
        captionLabel.textColor = ALKMessageStyle.receivedMessage.text
        if ALKMessageStyle.receivedBubble.style == .edge {
            bubbleView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
            bubbleView.backgroundColor = appSettingsUserDefaults.getReceivedMessageBackgroundColor()
            photoView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
        } else {
            photoView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
            bubbleView.layer.cornerRadius = ALKMessageStyle.receivedBubble.cornerRadius
        }
    }

    override func setupViews() {
        super.setupViews()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTappedAction))
        avatarImageView.addGestureRecognizer(tapGesture)

        contentView.addViewsForAutolayout(views: [avatarImageView, nameLabel])
        nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 57).isActive = true

        nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -56).isActive = true
        nameLabel.bottomAnchor.constraint(equalTo: photoView.topAnchor, constant: -6).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: 16).isActive = true

        avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18).isActive = true
        avatarImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: 0).isActive = true

        avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 9).isActive = true
        avatarImageView.trailingAnchor.constraint(equalTo: photoView.leadingAnchor, constant: -10).isActive = true

        avatarImageView.heightAnchor.constraint(equalToConstant: 37).isActive = true
        avatarImageView.widthAnchor.constraint(equalTo: avatarImageView.heightAnchor).isActive = true

        photoView.trailingAnchor
            .constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -Padding.PhotoView.right)
            .isActive = true
        photoView.widthAnchor
            .constraint(equalToConstant: ALKPhotoCell.maxWidth * ALKPhotoCell.widthPercentage)
            .isActive = true
        photoView.heightAnchor
            .constraint(equalToConstant: ALKPhotoCell.maxWidth * ALKPhotoCell.heightPercentage)
            .isActive = true

        timeLabel.leadingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 2).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2).isActive = true

        fileSizeLabel.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 0).isActive = true
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)

        nameLabel.text = viewModel.displayName

        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)

        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            avatarImageView.image = placeHolder
        }
    }

    @objc private func avatarTappedAction() {
        avatarTapped?()
    }
}
