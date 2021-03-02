//
//  ALKReplyMessageView.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 07/02/18.
//

import ApplozicCore
import UIKit

/* Reply message view to be used in the
 bottom (above chat bar) when replying
 to a message */

open class ALKReplyMessageView: UIView, Localizable {
    public enum Theme {
        public static var message = Style(
            font: Font.normal(size: 14).font(),
            text: .text(.black00)
        )
        public static var mention = Style(
            font: Font.normal(size: 14).font(),
            text: .blue,
            background: UIColor.blue.withAlphaComponent(0.1)
        )
    }

    var configuration: ALKConfiguration!

    open var nameLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.text = "Name"
        label.numberOfLines = 1
        return label
    }()

    open var messageLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.text = "The message"
        label.numberOfLines = 1
        return label
    }()

    open var closeButton: UIButton = {
        let button = UIButton(frame: CGRect.zero)
        let closeImage = UIImage(named: "close", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(closeImage, for: .normal)
        return button
    }()

    open var previewImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.backgroundColor = .clear
        return imageView
    }()

    open lazy var selfNameText: String = {
        let text = localizedString(forKey: "You", withDefaultValue: SystemMessage.LabelName.You, fileName: configuration.localizedStringFileName)
        return text
    }()

    public var closeButtonTapped: ((Bool) -> Void)?

    private var message: ALKMessageViewModel?
    var displayNames: ((Set<String>) -> ([String: String]?))?

    private enum Padding {
        enum NameLabel {
            static let height: CGFloat = 30.0
            static let left: CGFloat = 10.0
            static let right: CGFloat = -10.0
            static let top: CGFloat = 5.0
        }

        enum MessageLabel {
            static let height: CGFloat = 30.0
            static let left: CGFloat = 10.0
            static let right: CGFloat = -5.0
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = -5.0
        }

        enum CloseButton {
            static let height: CGFloat = 30.0
            static let width: CGFloat = 30.0
            static let right: CGFloat = -10.0
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = -5.0
        }

        enum PreviewImageView {
            static let height: CGFloat = 50.0
            static let width: CGFloat = 80.0
            static let right: CGFloat = -10.0
            static let top: CGFloat = 5.0
            static let bottom: CGFloat = -5.0
        }
    }

    init(frame: CGRect, configuration: ALKConfiguration) {
        super.init(frame: frame)
        self.configuration = configuration
        setUpViews()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func update(message: ALKMessageViewModel) {
        self.message = message
        nameLabel.text = message.isMyMessage ?
            selfNameText : message.displayName
        if message.messageType == .text,
           let attributedText = message
           .attributedTextWithMentions(
               defaultAttributes: Theme.message.toAttributes,
               mentionAttributes: Theme.mention.toAttributes,
               displayNames: displayNames
           )
        {
            messageLabel.attributedText = attributedText
        } else {
            messageLabel.text = getMessageText()
        }

        if let imageURL = getURLForPreviewImage(message: message) {
            setImageFrom(url: imageURL, to: previewImageView)
        } else {
            previewImageView.image = placeholderForPreviewImage(message: message)
        }
    }

    // MARK: - Internal methods

    private func setUpViews() {
        messageLabel.setStyle(Theme.message)
        setUpConstraints()
        closeButton.addTarget(self, action: #selector(closeButtonTapped(_:)), for: .touchUpInside)
    }

    private func setUpConstraints() {
        addViewsForAutolayout(views: [nameLabel, messageLabel, closeButton, previewImageView])

        let view = self

        nameLabel.heightAnchor.constraint(
            lessThanOrEqualToConstant: Padding.NameLabel.height
        )
        .isActive = true
        nameLabel.leadingAnchor.constraint(
            equalTo: view.leadingAnchor,
            constant: Padding.NameLabel.left
        ).isActive = true
        nameLabel.trailingAnchor.constraint(
            equalTo: previewImageView.leadingAnchor,
            constant: Padding.NameLabel.right
        ).isActive = true
        nameLabel.topAnchor.constraint(
            equalTo: view.topAnchor,
            constant: Padding.NameLabel.top
        ).isActive = true

        messageLabel.heightAnchor.constraint(
            lessThanOrEqualToConstant: Padding.MessageLabel.height
        )
        .isActive = true
        messageLabel.leadingAnchor.constraint(
            equalTo: view.leadingAnchor,
            constant: Padding.MessageLabel.left
        ).isActive = true
        messageLabel.trailingAnchor.constraint(
            equalTo: previewImageView.leadingAnchor,
            constant: Padding.MessageLabel.right
        ).isActive = true
        messageLabel.topAnchor.constraint(
            equalTo: nameLabel.bottomAnchor,
            constant: Padding.MessageLabel.top
        ).isActive = true
        messageLabel.bottomAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: Padding.MessageLabel.bottom
        ).isActive = true

        closeButton.heightAnchor.constraint(
            lessThanOrEqualToConstant: Padding.CloseButton.height
        )
        .isActive = true
        closeButton.widthAnchor.constraint(
            equalToConstant: Padding.CloseButton.width
        ).isActive = true
        closeButton.trailingAnchor.constraint(
            equalTo: view.trailingAnchor,
            constant: Padding.CloseButton.right
        ).isActive = true
        closeButton.topAnchor.constraint(
            equalTo: view.topAnchor,
            constant: Padding.CloseButton.top
        ).isActive = true
        closeButton.bottomAnchor.constraint(
            equalTo: messageLabel.topAnchor,
            constant: Padding.CloseButton.bottom
        ).isActive = true

        previewImageView.heightAnchor.constraint(
            lessThanOrEqualToConstant: Padding.PreviewImageView.height
        )
        .isActive = true
        previewImageView.widthAnchor.constraint(
            equalToConstant: Padding.PreviewImageView.width
        ).isActive = true
        previewImageView.trailingAnchor.constraint(
            equalTo: closeButton.leadingAnchor,
            constant: Padding.PreviewImageView.right
        ).isActive = true
        previewImageView.topAnchor.constraint(
            equalTo: nameLabel.topAnchor,
            constant: Padding.PreviewImageView.top
        ).isActive = true
        previewImageView.bottomAnchor.constraint(
            equalTo: messageLabel.bottomAnchor,
            constant: 0
        ).isActive = true
    }

    @objc private func closeButtonTapped(_: UIButton) {
        closeButtonTapped?(true)
    }

    private func getMessageText() -> String? {
        guard let message = message else { return nil }
        switch message.messageType {
        case .text, .html:
            return message.message
        default:
            return message.messageType.rawValue
        }
    }

    private func setImageFrom(url: URL?, to imageView: UIImageView) {
        imageView.kf.setImage(with: url)
    }

    private func getURLForPreviewImage(message: ALKMessageViewModel) -> URL? {
        switch message.messageType {
        case .photo, .video:
            return getImageURL(for: message)
        case .location:
            return getMapImageURL(for: message)
        default:
            return nil
        }
    }

    private func getImageURL(for message: ALKMessageViewModel) -> URL? {
        guard message.messageType == .photo else { return nil }
        if let filePath = message.filePath {
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(filePath)
            return path
        } else if let thumnailURL = message.thumbnailURL {
            return thumnailURL
        }
        return nil
    }

    private func getMapImageURL(for message: ALKMessageViewModel) -> URL? {
        guard message.messageType == .location else { return nil }
        guard let lat = message.geocode?.location.latitude,
              let lon = message.geocode?.location.longitude
        else { return nil }

        let latLonArgument = String(format: "%f,%f", lat, lon)
        guard let apiKey = ALUserDefaultsHandler.getGoogleMapAPIKey()
        else { return nil }
        // swiftlint:disable:next line_length
        let urlString = "https://maps.googleapis.com/maps/api/staticmap?center=\(latLonArgument)&zoom=17&size=375x295&maptype=roadmap&format=png&visual_refresh=true&markers=\(latLonArgument)&key=\(apiKey)"
        return URL(string: urlString)
    }

    private func placeholderForPreviewImage(message: ALKMessageViewModel) -> UIImage? {
        switch message.messageType {
        case .video:
            if let filepath = message.filePath {
                let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let path = docDirPath.appendingPathComponent(filepath)
                let fileUtills = ALKFileUtils()
                return fileUtills.getThumbnail(filePath: path)
            }
            return UIImage(named: "VIDEO", in: Bundle.applozic, compatibleWith: nil)
        case .location:
            return UIImage(named: "map_no_data", in: Bundle.applozic, compatibleWith: nil)
        default:
            return nil
        }
    }
}
