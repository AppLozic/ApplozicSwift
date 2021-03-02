//
//  ALKEmailCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 13/03/19.
//

import UIKit

class ALKEmailTopView: UIView {
    static let height: CGFloat = 20

    // MARK: - Private properties

    fileprivate var emailImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "alk_replied_icon",
                                  in: Bundle.applozic,
                                  compatibleWith: nil)
        imageView.isUserInteractionEnabled = false
        imageView.contentMode = .center
        imageView.isHidden = true
        return imageView
    }()

    fileprivate var emailLabel: UILabel = {
        let label = UILabel()
        label.text = "via email"
        label.numberOfLines = 1
        label.font = UIFont(name: "Helvetica", size: 12)
        label.isOpaque = true
        label.isHidden = true
        return label
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal APIs

    func show(_ show: Bool) {
        emailImage.isHidden = !show
        emailLabel.isHidden = !show
    }

    // MARK: - Private helper methods

    private func setupConstraints() {
        backgroundColor = .clear
        addViewsForAutolayout(views: [emailImage, emailLabel])

        NSLayoutConstraint.activate([
            emailImage.topAnchor.constraint(equalTo: topAnchor),
            emailImage.leadingAnchor.constraint(equalTo: leadingAnchor),
            emailImage.heightAnchor.constraint(equalToConstant: ALKEmailTopView.height),
            emailImage.widthAnchor.constraint(equalToConstant: ALKEmailTopView.height),

            emailLabel.topAnchor.constraint(equalTo: topAnchor),
            emailLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            emailLabel.leadingAnchor.constraint(equalTo: emailImage.trailingAnchor),
            emailLabel.heightAnchor.constraint(equalToConstant: ALKEmailTopView.height),
        ])
    }
}

class ALKEmailBottomView: UIView {
    enum Padding {
        enum View {
            static let height: CGFloat = 20
        }

        enum EmailInfo {
            static let height: CGFloat = 20.0
            static let width: CGFloat = 124.0
        }

        enum EmailLink {
            static let height: CGFloat = 20.0
            static let left: CGFloat = 3.0
        }
    }

    var emailInfo: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        let attributedStringforNowLabel = NSMutableAttributedString(string: "Have trouble viewing?", attributes: [
            .font: UIFont(name: "HelveticaNeue-Light", size: 13.0)!,
            .foregroundColor: UIColor(red: 53.0 / 255.0, green: 53.0 / 255.0, blue: 52.0 / 255.0, alpha: 1.0),
            .kern: 0.04,
        ])
        label.attributedText = attributedStringforNowLabel
        label.isOpaque = true
        label.isHidden = true
        return label
    }()

    var emailLinkLabel: UILabel = {
        let label = UILabel()
        let attributedStringforNowLabel = NSMutableAttributedString(string: "See it in full view", attributes: [
            .font: UIFont(name: "HelveticaNeue-Light", size: 13.0)!,
            .foregroundColor: UIColor(red: 81.0 / 255.0, green: 78.0 / 255.0, blue: 239.0 / 255.0, alpha: 1.0),
            .kern: 0.04,
        ])
        label.isUserInteractionEnabled = true
        label.attributedText = attributedStringforNowLabel
        label.numberOfLines = 1
        label.isOpaque = true
        label.isHidden = true
        return label
    }()

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Internal APIs

    func show(_ show: Bool) {
        emailInfo.isHidden = !show
        emailLinkLabel.isHidden = !show
    }

    // MARK: - Private helper methods

    private func setupConstraints() {
        backgroundColor = .clear
        addViewsForAutolayout(views: [emailInfo, emailLinkLabel])
        bringSubviewToFront(emailLinkLabel)

        NSLayoutConstraint.activate([
            emailInfo.topAnchor.constraint(equalTo: topAnchor),
            emailInfo.leadingAnchor.constraint(equalTo: leadingAnchor),
            emailInfo.heightAnchor.constraint(equalToConstant: Padding.EmailInfo.height),
            emailInfo.widthAnchor.constraint(equalToConstant: Padding.EmailInfo.width),

            emailLinkLabel.topAnchor.constraint(equalTo: topAnchor),
            emailLinkLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            emailLinkLabel.leadingAnchor.constraint(equalTo: emailInfo.trailingAnchor, constant: Padding.EmailLink.left),
            emailLinkLabel.heightAnchor.constraint(equalToConstant: Padding.EmailLink.height),
        ])
    }
}
