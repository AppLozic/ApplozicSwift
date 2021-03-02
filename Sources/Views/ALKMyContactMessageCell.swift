//
//  ALKMyContactMessageCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 16/04/19.
//

import ApplozicCore

class ALKMyContactMessageCell: ALKContactMessageBaseCell {
    enum Padding {
        enum StateView {
            static let width: CGFloat = 17.0
            static let height: CGFloat = 9.0
            static let bottom: CGFloat = 1
            static let right: CGFloat = 2
        }

        enum TimeLabel {
            static let right: CGFloat = 2
            static let bottom: CGFloat = 2
        }

        enum ContactView {
            static let multiplier: CGFloat = 0.5
            static let right: CGFloat = 10
        }
    }

    fileprivate var timeLabel = UILabel(frame: .zero)

    fileprivate var stateView: UIImageView = {
        let sv = UIImageView()
        sv.isUserInteractionEnabled = false
        sv.contentMode = .center
        return sv
    }()

    override func setupViews() {
        setupConstraints()
        accessibilityIdentifier = "myContactCell"
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)
        loadingIndicator.startLoading(localizationFileName: localizedStringFileName)
        contactView.isHidden = true
        if let filePath = viewModel.filePath {
            updateContactDetails(key: viewModel.identifier, filePath: filePath)
        }
        timeLabel.text = viewModel.time
        timeLabel.setStyle(ALKMessageStyle.time)
        setStatusStyle(statusView: stateView, ALKMessageStyle.messageStatus)
    }

    override func setupStyle() {
        super.setupStyle()
        contactView.setStyle(
            itemColor: ALKMessageStyle.sentMessage.text,
            bubbleStyle: ALKMessageStyle.sentBubble, isReceiverSide: false
        )
        setStatusStyle(statusView: stateView, ALKMessageStyle.messageStatus)
    }

    class func rowHeight() -> CGFloat {
        var height = ContactView.height()
        height += max(Padding.StateView.bottom, Padding.TimeLabel.bottom)
        return height + 5 // Extra padding
    }

    private func setupConstraints() {
        contentView.addViewsForAutolayout(views: [contactView, timeLabel, stateView, loadingIndicator])
        contentView.bringSubviewToFront(loadingIndicator)

        contactView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.ContactView.right).isActive = true
        contactView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: Padding.ContactView.multiplier).isActive = true
        contactView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contactView.heightAnchor.constraint(equalToConstant: ContactView.height()).isActive = true

        loadingIndicator.trailingAnchor.constraint(equalTo: contactView.trailingAnchor).isActive = true
        loadingIndicator.topAnchor.constraint(equalTo: contactView.topAnchor).isActive = true
        loadingIndicator.bottomAnchor.constraint(equalTo: contactView.bottomAnchor).isActive = true
        loadingIndicator.leadingAnchor.constraint(equalTo: contactView.leadingAnchor).isActive = true
        stateView.bottomAnchor.constraint(equalTo: contactView.bottomAnchor, constant: -1 * Padding.StateView.bottom).isActive = true
        stateView.trailingAnchor.constraint(equalTo: contactView.leadingAnchor, constant: -1 * Padding.StateView.right).isActive = true

        timeLabel.trailingAnchor.constraint(equalTo: stateView.leadingAnchor, constant: -1 * Padding.TimeLabel.right).isActive = true
        timeLabel.bottomAnchor.constraint(equalTo: contactView.bottomAnchor, constant: Padding.TimeLabel.bottom).isActive = true
    }
}
