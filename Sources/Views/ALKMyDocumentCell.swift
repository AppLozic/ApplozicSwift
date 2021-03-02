//
//  ALKMyDocumentCell.swift
//  ApplozicSwift
//
//  Created by sunil on 05/03/19.
//

import ApplozicCore
import Foundation
import Kingfisher
import UIKit

class ALKMyDocumentCell: ALKDocumentCell {
    let appSettingsUserDefaults = ALKAppSettingsUserDefaults()
    enum Padding {
        enum StateView {
            static let trailing: CGFloat = 2
            static let bottom: CGFloat = 1
            static let height: CGFloat = 9
            static let width: CGFloat = 17
        }

        enum AvatarImageView {
            static let top: CGFloat = 18
            static let leading: CGFloat = 9
            static let height: CGFloat = 37
        }

        enum TimeLabel {
            static let trailing: CGFloat = 2
            static let bottom: CGFloat = 0
        }

        enum BubbleView {
            static let top: CGFloat = 10
            static let leading: CGFloat = 57
            static let bottom: CGFloat = 7
            static let trailing: CGFloat = 14
        }
    }

    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [timeLabel, stateView])
        stateView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -Padding.StateView.bottom).isActive = true
        stateView.trailingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: -Padding.StateView.trailing).isActive = true

        timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -Padding.TimeLabel.trailing).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: Padding.TimeLabel.bottom).isActive = true

        bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.BubbleView.top).isActive = true
        bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.BubbleView.leading).isActive = true
        bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.BubbleView.trailing).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Padding.BubbleView.bottom).isActive = true
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)
        setStatusStyle(statusView: stateView, ALKMessageStyle.messageStatus)
    }

    override func setupStyle() {
        super.setupStyle()
        timeLabel.setStyle(ALKMessageStyle.time)
        bubbleView.backgroundColor = appSettingsUserDefaults.getSentMessageBackgroundColor()
        setStatusStyle(statusView: stateView, ALKMessageStyle.messageStatus)
    }

    class func heightPadding() -> CGFloat {
        return commonHeightPadding() + Padding.BubbleView.bottom + Padding.BubbleView.top
    }

    override class func rowHeigh(viewModel _: ALKMessageViewModel, width _: CGFloat) -> CGFloat {
        let minimumHeight: CGFloat = 0
        var messageHeight: CGFloat = 0.0
        messageHeight += heightPadding()
        return max(messageHeight, minimumHeight)
    }
}
