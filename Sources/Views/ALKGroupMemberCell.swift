//
//  ALKGroupMemberCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 08/05/19.
//

import Foundation
import Kingfisher

struct GroupMemberInfo {
    let id: String
    let name: String
    let image: String?
    var isAdmin: Bool
    let addCell: Bool
    let adminText: String?

    init(id: String, name: String, image: String?, isAdmin: Bool = false, addCell: Bool = false, adminText: String) {
        self.id = id
        self.name = name
        self.image = image
        self.isAdmin = isAdmin
        self.addCell = addCell
        self.adminText = adminText
    }

    init(name: String, addCell: Bool = true) {
        id = ""
        self.name = name
        self.addCell = addCell
        isAdmin = false
        image = nil
        adminText = nil
    }
}

class ALKGroupMemberCell: UICollectionViewCell {
    var channelDetailConfig = ALKChannelDetailViewConfiguration()

    enum Padding {
        enum Profile {
            static let left: CGFloat = 20
            static let width: CGFloat = 40
            static let height: CGFloat = 40
            static let top: CGFloat = 10
            static let bottom: CGFloat = 10
        }

        enum Name {
            static let left: CGFloat = 10
            static let right: CGFloat = 10
        }

        enum Admin {
            static let right: CGFloat = 20
        }
    }

    let profile: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "contactPlaceholder", in: Bundle.applozic, compatibleWith: nil)
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        return imageView
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor(red: 89, green: 87, blue: 87)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    let adminLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "HelveticaNeue", size: 13)
        label.textColor = UIColor(red: 131, green: 128, blue: 128)
        label.numberOfLines = 1
        label.isHidden = true
        return label
    }()

    let activityIndicator = UIActivityIndicatorView(style: .gray)

    var model: GroupMemberInfo?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showLoading() {
        activityIndicator.startAnimating()
        adminLabel.isHidden = true
    }

    func updateView(model: GroupMemberInfo) {
        self.model = model
        nameLabel.text = model.name
        nameLabel.setTextColor(channelDetailConfig.memberName.text)
        nameLabel.setFont(channelDetailConfig.memberName.font)
        adminLabel.isHidden = !model.isAdmin
        adminLabel.text = model.adminText

        guard !model.addCell else {
            let image = channelDetailConfig.addMemberIcon?.scale(with: CGSize(width: 25, height: 25))
            profile.image = image
            return
        }

        let placeHolder = UIImage(named: "contactPlaceholder", in: Bundle.applozic, compatibleWith: nil)
        guard let urlString = model.image, let url = URL(string: urlString) else {
            profile.image = placeHolder
            return
        }
        let resource = ImageResource(downloadURL: url, cacheKey: url.absoluteString)
        profile.kf.setImage(with: resource, placeholder: placeHolder)
    }

    class func rowHeight() -> CGFloat {
        return Padding.Profile.top + Padding.Profile.bottom + Padding.Profile.height
    }

    private func setupConstraints() {
        contentView.addViewsForAutolayout(views: [profile, adminLabel, nameLabel, activityIndicator])
        contentView.bringSubviewToFront(activityIndicator)
        profile.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.Profile.left).isActive = true
        profile.widthAnchor.constraint(equalToConstant: Padding.Profile.width).isActive = true
        profile.heightAnchor.constraint(equalToConstant: Padding.Profile.height).isActive = true
        profile.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.Profile.top).isActive = true
        profile.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Padding.Profile.bottom).isActive = true

        adminLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.Admin.right).isActive = true
        adminLabel.centerYAnchor.constraint(equalTo: profile.centerYAnchor).isActive = true

        activityIndicator.centerXAnchor.constraint(equalTo: adminLabel.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: adminLabel.centerYAnchor).isActive = true

        nameLabel.leadingAnchor.constraint(equalTo: profile.trailingAnchor, constant: Padding.Name.left).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profile.centerYAnchor).isActive = true
        nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: adminLabel.leadingAnchor, constant: -Padding.Name.right).isActive = true
    }
}
