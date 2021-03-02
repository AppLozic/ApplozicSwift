//
//  ContactView.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 16/04/19.
//

import Contacts

struct ContactModel {
    let identifier: String
    let contact: CNContact
    init(identifier: String, contact: CNContact) {
        self.identifier = identifier
        self.contact = contact
    }
}

class ContactView: UIView {
    enum Padding {
        enum ContactImage {
            static let left: CGFloat = 10
            static let width: CGFloat = 30
            static let height: CGFloat = 30
        }

        enum ContactName {
            static let left: CGFloat = 10
            static let right: CGFloat = 10
        }

        enum ContactSaveIcon {
            static let right: CGFloat = 10
            static let width: CGFloat = 10
            static let height: CGFloat = 15
        }

        static let height: CGFloat = 50
    }

    let contactImage: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 15
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    let contactName: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.font = UIFont(name: "HelveticaNeue", size: 17)
        return label
    }()

    let contactSaveIcon: UIButton = {
        let button = UIButton()
        var image = UIImage(
            named: "icon_arrow",
            in: Bundle.applozic,
            compatibleWith: nil
        )?
            .withRenderingMode(.alwaysTemplate)
        image = image?.imageFlippedForRightToLeftLayoutDirection()
        button.setImage(image, for: .normal)
        return button
    }()

    var contactSelected: ((ContactModel) -> Void)?

    var contactModel: ContactModel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
        setTarget()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setStyle(itemColor: UIColor, bubbleStyle: ALKMessageStyle.Bubble, isReceiverSide: Bool) {
        contactName.textColor = itemColor
        contactSaveIcon.tintColor = itemColor
        setBubbleStyle(bubbleStyle, isReceiverSide: isReceiverSide)
    }

    func update(contactModel: ContactModel) {
        self.contactModel = contactModel
        let contact = contactModel.contact
        contactName.text = "\(contact.givenName) \(contact.familyName)"
        guard
            let data = contact.imageData,
            let image = UIImage(data: data)
        else {
            contactImage.image = UIImage(named: "placeholder", in: Bundle.applozic, compatibleWith: nil)
            return
        }
        contactImage.image = image
    }

    class func height() -> CGFloat {
        return Padding.height
    }

    @objc func tapped() {
        guard let contactSelected = contactSelected else {
            return
        }
        contactSelected(contactModel)
    }

    private func setupConstraints() {
        layer.cornerRadius = 10
        clipsToBounds = true
        heightAnchor.constraint(equalToConstant: Padding.height).isActive = true
        addViewsForAutolayout(views: [contactImage, contactName, contactSaveIcon])

        contactImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Padding.ContactImage.left).isActive = true
        contactImage.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        contactImage.widthAnchor.constraint(equalToConstant: Padding.ContactImage.width).isActive = true
        contactImage.heightAnchor.constraint(equalToConstant: Padding.ContactImage.height).isActive = true

        contactSaveIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Padding.ContactSaveIcon.right).isActive = true
        contactSaveIcon.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        contactSaveIcon.widthAnchor.constraint(equalToConstant: Padding.ContactSaveIcon.width).isActive = true
        contactSaveIcon.heightAnchor.constraint(equalToConstant: Padding.ContactSaveIcon.height).isActive = true

        contactName.leadingAnchor.constraint(equalTo: contactImage.trailingAnchor, constant: Padding.ContactName.left).isActive = true
        contactName.trailingAnchor.constraint(equalTo: contactSaveIcon.leadingAnchor, constant: -Padding.ContactName.right).isActive = true
        contactName.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    private func setTarget() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)
    }
}
