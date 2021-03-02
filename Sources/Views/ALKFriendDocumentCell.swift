//
//  ALKFriendDocumentCell.swift
//  ApplozicSwift
//
//  Created by sunil on 05/03/19.
//

import ApplozicCore
import Foundation
import Kingfisher
import UIKit

class ALKFriendDocumentCell: ALKDocumentCell {
    let appSettingsUserDefaults = ALKAppSettingsUserDefaults()
    enum Padding {
        enum NameLabel {
            static let top: CGFloat = 6
            static let leading: CGFloat = 57
            static let height: CGFloat = 16
            static let trailing: CGFloat = 56
        }

        enum AvatarImageView {
            static let top: CGFloat = 18
            static let leading: CGFloat = 9
            static let height: CGFloat = 37
        }

        enum TimeLabel {
            static let left: CGFloat = 2
            static let bottom: CGFloat = 2
        }

        enum BubbleView {
            static let top: CGFloat = 1
            static let leading: CGFloat = 5
            static let bottom: CGFloat = 8
            static let trailing: CGFloat = 48
        }
    }

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

    override func setupViews() {
        super.setupViews()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(avatarTappedAction))
        avatarImageView.addGestureRecognizer(tapGesture)

        contentView.addViewsForAutolayout(views: [avatarImageView, nameLabel, timeLabel])

        nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.NameLabel.top).isActive = true
        nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.NameLabel.leading).isActive = true

        nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.NameLabel.trailing).isActive = true
        nameLabel.heightAnchor.constraint(equalToConstant: Padding.NameLabel.height).isActive = true

        avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.AvatarImageView.top).isActive = true

        avatarImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.AvatarImageView.leading).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: Padding.AvatarImageView.height).isActive = true
        avatarImageView.widthAnchor.constraint(equalTo: avatarImageView.heightAnchor).isActive = true

        timeLabel.leftAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: Padding.TimeLabel.left).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -Padding.TimeLabel.bottom).isActive = true

        bubbleView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: Padding.BubbleView.top).isActive = true
        bubbleView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Padding.BubbleView.leading).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.BubbleView.trailing).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Padding.BubbleView.bottom).isActive = true
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)
        let placeHolder = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)

        if let url = viewModel.avatarURL {
            let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
            avatarImageView.kf.setImage(with: resource, placeholder: placeHolder)
        } else {
            avatarImageView.image = placeHolder
        }
        nameLabel.text = viewModel.displayName
    }

    override func setupStyle() {
        super.setupStyle()
        timeLabel.setStyle(ALKMessageStyle.time)
        nameLabel.setStyle(ALKMessageStyle.displayName)
        bubbleView.backgroundColor = appSettingsUserDefaults.getReceivedMessageBackgroundColor()
    }

    override class func rowHeigh(viewModel _: ALKMessageViewModel, width _: CGFloat) -> CGFloat {
        let minimumHeight: CGFloat = 60 // 55 is avatar image... + padding
        let messageHeight: CGFloat = heightPadding()
        return max(messageHeight, minimumHeight)
    }

    class func heightPadding() -> CGFloat {
        return commonHeightPadding() + Padding.NameLabel.height + Padding.NameLabel.top + Padding.BubbleView.bottom + Padding.BubbleView.top
    }

    @objc private func avatarTappedAction() {
        avatarTapped?()
    }
}
