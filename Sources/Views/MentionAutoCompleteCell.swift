//
//  MentionAutoSuggestionCell.swift
//  ApplozicSwift
//
//  Created by Mukesh on 11/09/19.
//

import Kingfisher
import UIKit

class MentionAutoCompleteCell: UITableViewCell, AutoCompletionItemCell {
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
        label.font = UIFont(name: "HelveticaNeue", size: 15)
        label.textColor = UIColor(red: 89, green: 87, blue: 87)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    var item: AutoCompleteItem?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateView(item: AutoCompleteItem) {
        self.item = item
        nameLabel.text = item.content

        let placeHolder = UIImage(named: "contactPlaceholder", in: Bundle.applozic, compatibleWith: nil)
        guard let url = item.displayImageURL else {
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
        contentView.addViewsForAutolayout(views: [profile, nameLabel])
        NSLayoutConstraint.activate([
            profile.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Padding.Profile.left),
            profile.widthAnchor.constraint(equalToConstant: Padding.Profile.width),
            profile.heightAnchor.constraint(equalToConstant: Padding.Profile.height),
            profile.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Padding.Profile.top),
            profile.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Padding.Profile.bottom),
            nameLabel.leadingAnchor.constraint(equalTo: profile.trailingAnchor, constant: Padding.Name.left),
            nameLabel.centerYAnchor.constraint(equalTo: profile.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Padding.Name.right),
        ])
    }
}
