//
//  ALKMyPhotoPortalCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Foundation

// MARK: - ALKMyPhotoPortalCell

final class ALKMyPhotoPortalCell: ALKPhotoCell {
    enum State {
        case upload
        case uploading
        case uploaded
    }

    let appSettingsUserDefaults = ALKAppSettingsUserDefaults()
    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    enum Padding {
        enum PhotoView {
            static let right: CGFloat = 14
            static let top: CGFloat = 6
        }
    }

    override class var messageTextFont: UIFont {
        return ALKMessageStyle.sentMessage.font
    }

    override func setupViews() {
        super.setupViews()
        accessibilityIdentifier = "myPhotoCell"
        contentView.addViewsForAutolayout(views: [stateView])

        photoView.topAnchor
            .constraint(equalTo: contentView.topAnchor, constant: Padding.PhotoView.top)
            .isActive = true

        photoView.trailingAnchor
            .constraint(equalTo: contentView.trailingAnchor, constant: -Padding.PhotoView.right)
            .isActive = true

        photoView.widthAnchor
            .constraint(equalToConstant: ALKPhotoCell.maxWidth * ALKPhotoCell.widthPercentage)
            .isActive = true
        photoView.heightAnchor
            .constraint(equalToConstant: ALKPhotoCell.maxWidth * ALKPhotoCell.heightPercentage)
            .isActive = true

        bubbleView.backgroundColor = UIColor.hex8(Color.Background.grayF2.rawValue).withAlphaComponent(0.26)

        fileSizeLabel.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: 0).isActive = true
        stateView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -1.0).isActive = true
        stateView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -2.0).isActive = true

        timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -2.0).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2).isActive = true
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)
        setStatusStyle(statusView: stateView, ALKMessageStyle.messageStatus)
    }

    override class func bottomPadding() -> CGFloat {
        return 6
    }

    override func setupStyle() {
        super.setupStyle()
        captionLabel.font = ALKMessageStyle.sentMessage.font
        captionLabel.textColor = ALKMessageStyle.sentMessage.text
        if ALKMessageStyle.sentBubble.style == .edge {
            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
            bubbleView.backgroundColor = appSettingsUserDefaults.getSentMessageBackgroundColor()
            photoView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
        } else {
            photoView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
            bubbleView.layer.cornerRadius = ALKMessageStyle.sentBubble.cornerRadius
        }
        setStatusStyle(statusView: stateView, ALKMessageStyle.messageStatus)
    }
}
