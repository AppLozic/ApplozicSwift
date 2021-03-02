//
//  ALKGenericCardCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 28/03/18.
//

import Kingfisher
import UIKit

open class ALKGenericCardCollectionView: ALKIndexedCollectionView {
    open var cardTemplate: [CardTemplate]?

    override open func setMessage(viewModel: ALKMessageViewModel) {
        super.setMessage(viewModel: viewModel)
        // set card template
        guard let templates = ALKGenericCardCollectionView.getCardTemplate(message: viewModel) else { return }
        cardTemplate = templates
    }

    override open class func rowHeightFor(message: ALKMessageViewModel, width: CGFloat) -> CGFloat {
        guard let template = getCardTemplate(message: message),
              let card = template.first
        else {
            return 0
        }
        let maxHeight = template
            .map { ALKGenericCardCell.rowHeight(card: $0, maxWidth: width) }
            .max { $0 < $1 }
        let defaultHeight = ALKGenericCardCell.rowHeight(card: card, maxWidth: width)
        return maxHeight ?? defaultHeight
    }

    class func getCardTemplate(message: ALKMessageViewModel) -> [CardTemplate]? {
        guard
            let metadata = message.metadata,
            let templateId = metadata["templateId"] as? String
        else { return nil }
        switch templateId {
        case ActionableMessageType.cardTemplate.rawValue:
            do {
                let templates = try TemplateDecoder.decode([CardTemplate].self, from: metadata)
                return templates
            } catch {
                print("\(error)")
                return nil
            }
        case ActionableMessageType.genericCard.rawValue:
            do {
                let cards = try TemplateDecoder.decode([ALKGenericCard].self, from: metadata)
                var templates = [CardTemplate]()
                for card in cards {
                    templates.append(Util().cardTemplate(from: card))
                }
                return templates
            } catch {
                print("\(error)")
                return nil
            }
        default:
            print("Do nothing")
            return nil
        }
    }
}

open class ALKGenericCardCell: UICollectionViewCell {
    public enum Font {
        public static var overlayText = UIFont(name: "HelveticaNeue-Medium", size: 16) ??
            UIFont.systemFont(ofSize: 16)

        public static var rating = UIFont(name: "HelveticaNeue", size: 12) ??
            UIFont.systemFont(ofSize: 12)

        public static var title = UIFont(name: "HelveticaNeue-Medium", size: 18) ??
            UIFont.boldSystemFont(ofSize: 18)

        public static var subtitle = UIFont(name: "HelveticaNeue", size: 14) ??
            UIFont.systemFont(ofSize: 14)

        public static var description = UIFont(name: "HelveticaNeue-Light", size: 14) ??
            UIFont.systemFont(ofSize: 14)

        public static var button = UIFont.systemFont(ofSize: 15, weight: .medium)
    }

    public enum Config {
        public static let buttonHeight: CGFloat = 40

        public static let imageHeight: CGFloat = 100

        public static let spacing: CGFloat = 3

        public static let buttonStackViewSpacing: CGFloat = 1

        public enum OverlayText {
            public static let width: CGFloat = 80
            public static let height: CGFloat = 35
        }

        /// The number of lines for the card description label. The default value for this is 3.
        public static var descriptionMaxLines = 3
    }

    enum ConstraintIdentifier: String {
        case titleView
        case subtitleView
        case descriptionView
        case buttonsView
    }

    let maxButtonCount = 8

    lazy var coverImageHeight = self.coverImageView.heightAnchor.constraint(equalToConstant: Config.imageHeight)

    open var coverImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect.zero)
        imageView.layer.cornerRadius = 0
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    open var overlayText: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = Font.overlayText
        label.numberOfLines = 1
        label.textAlignment = .center
        label.layer.cornerRadius = 5
        label.clipsToBounds = true
        label.layer.masksToBounds = false
        label.layer.shadowOpacity = 0.5
        label.layer.shadowOffset = .zero
        return label
    }()

    open var ratingLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = Font.rating
        label.numberOfLines = 1
        return label
    }()

    open var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.numberOfLines = 1
        label.font = Font.title
        return label
    }()

    open var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.numberOfLines = 1
        label.font = Font.subtitle
        return label
    }()

    open var descriptionLabel: VerticalAlignLabel = {
        let label = VerticalAlignLabel()
        label.text = ""
        label.numberOfLines = ALKGenericCardCell.Config.descriptionMaxLines
        label.font = Font.description
        label.textColor = UIColor(red: 121, green: 116, blue: 116)
        return label
    }()

    open var titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    open var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = Config.buttonStackViewSpacing
        return stackView
    }()

    open var buttonsBackground: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .lightGray
        return view
    }()

    open var actionButtons = [UIButton]()
    open var card: CardTemplate!
    open var buttonSelected: ((_ index: Int, _ name: String, _ card: CardTemplate) -> Void)?

    override open func awakeFromNib() {
        super.awakeFromNib()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setUpButtons()
        setupConstraints()
        setupStyle()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private class func headerHeight(_ header: CardTemplate.Header) -> CGFloat {
        guard let urlString = header.imgSrc,
              URL(string: urlString) != nil
        else {
            if let text = header.overlayText, !text.isEmpty {
                return Config.OverlayText.height
            } else {
                return CGFloat(0)
            }
        }
        return Config.imageHeight
    }

    private class func textHeight(_ text: String?, size: CGSize, font: UIFont) -> CGFloat {
        guard let text = text, !text.isEmpty else { return 0 }
        return text.rectWithConstrainedSize(size, font: font).height.rounded(.up)
    }

    open class func rowHeight(card: CardTemplate, maxWidth: CGFloat) -> CGFloat {
        var headerHt: CGFloat = 0
        if let header = card.header {
            headerHt = headerHeight(header)
        }
        let titleConstraint = CGSize(width: maxWidth, height: Font.title.lineHeight)
        let titleHeight = textHeight(card.title, size: titleConstraint, font: Font.title)

        let subtitleConstraint = CGSize(width: maxWidth, height: Font.subtitle.lineHeight)
        let subtitleHeight = textHeight(card.subtitle, size: subtitleConstraint, font: Font.subtitle)

        let descriptionConstraint = CGSize(width: maxWidth, height: Font.description.lineHeight)
        let descriptionHeight = textHeight(card.description, size: descriptionConstraint, font: Font.description) * CGFloat(ALKGenericCardCell.Config.descriptionMaxLines)

        let totalButtonHeight = Config.buttonHeight * CGFloat(card.buttons?.count ?? 0)

        var stackViewSpacing = (Config.spacing * 2)
        stackViewSpacing += (card.buttons != nil) ? Config.spacing : 0
        stackViewSpacing += (card.description != nil) ? Config.spacing : 0
        if let count = card.buttons?.count {
            stackViewSpacing += CGFloat(count) - Config.buttonStackViewSpacing // 1 space between 2 buttons.
        }

        return headerHt + titleHeight + subtitleHeight + descriptionHeight + totalButtonHeight + CGFloat(stackViewSpacing)
    }

    @objc func buttonSelected(_ action: UIButton) {
        buttonSelected?(action.tag, action.currentTitle ?? "", card)
    }

    open func update(card: CardTemplate) {
        self.card = card
        setTitle(card.title)
        setSubtitle(card.subtitle)
        setDescription(card)
        setRatingLabel(card)
        setOverlayText(card.header)
        setCoverImage(card.header)
        contentView.layoutIfNeeded()
        guard let buttons = card.buttons, !buttons.isEmpty else { return }
        updateViewFor(buttons)
        contentView.layoutIfNeeded()
    }

    private func setupStyle() {
        let style = CardStyle.shared
        titleLabel.textColor = style.titleLabel.textColor
        overlayText.textColor = style.overlayLabel.textColor
        overlayText.layer.shadowColor = style.overlayLabel.shadowColor
        overlayText.backgroundColor = style.overlayLabel.background
        ratingLabel.textColor = style.ratingLabel.textColor
        subtitleLabel.textColor = style.subtitleLabel.textColor
        descriptionLabel.textColor = style.descriptionLabel.textColor
    }

    private func setTitle(_ text: String?) {
        guard let text = text, !text.isEmpty else {
            titleStackView.constraint(withIdentifier: ConstraintIdentifier.titleView.rawValue)?.constant = 0
            return
        }
        titleLabel.text = text
        let titleConstraint = CGSize(width: 200, height: Font.title.lineHeight)
        let height = text.rectWithConstrainedSize(titleConstraint, font: Font.title).height.rounded(.up)
        titleStackView.constraint(withIdentifier: ConstraintIdentifier.titleView.rawValue)?.constant = height
    }

    private func setSubtitle(_ text: String?) {
        guard let text = text, !text.isEmpty else {
            subtitleLabel.constraint(withIdentifier: ConstraintIdentifier.subtitleView.rawValue)?.constant = 0
            return
        }
        subtitleLabel.text = text
        let subtitleConstraint = CGSize(width: 200, height: Font.subtitle.lineHeight)
        let height = text.rectWithConstrainedSize(subtitleConstraint, font: Font.subtitle).height.rounded(.up)
        subtitleLabel.constraint(withIdentifier: ConstraintIdentifier.subtitleView.rawValue)?.constant = height
    }

    private func setOverlayText(_ header: CardTemplate.Header?) {
        guard let text = header?.overlayText, !text.isEmpty else {
            overlayText.isHidden = true
            return
        }
        overlayText.isHidden = false
        overlayText.text = text
    }

    private func setCoverImage(_ header: CardTemplate.Header?) {
        guard let header = header else {
            coverImageView.isHidden = true
            coverImageHeight.constant = 0
            return
        }
        coverImageHeight.constant = ALKGenericCardCell.headerHeight(header)

        guard let urlString = header.imgSrc, let url = URL(string: urlString) else {
            coverImageView.isHidden = true
            overlayText.backgroundColor = UIColor(red: 230, green: 229, blue: 236)
            overlayText.layer.masksToBounds = true
            return
        }
        coverImageView.isHidden = false
        coverImageView.kf.setImage(with: url)
    }

    private func setRatingLabel(_ card: CardTemplate) {
        guard let rating = card.titleExt, !rating.isEmpty else {
            ratingLabel.isHidden = true
            return
        }
        ratingLabel.isHidden = false
        ratingLabel.text = String(rating)
    }

    private func setDescription(_ card: CardTemplate) {
        guard let description = card.description, !description.isEmpty else {
            descriptionLabel.constraint(withIdentifier: ConstraintIdentifier.descriptionView.rawValue)?.constant = 0
            descriptionLabel.isHidden = true
            return
        }
        descriptionLabel.isHidden = false
        descriptionLabel.text = description
        let descriptionConstraint = CGSize(width: 200, height: Font.description.lineHeight * 1)
        let height = description.rectWithConstrainedSize(descriptionConstraint, font: Font.description).height.rounded(.up) * CGFloat(ALKGenericCardCell.Config.descriptionMaxLines)
        descriptionLabel.constraint(withIdentifier: ConstraintIdentifier.descriptionView.rawValue)?.constant = height
    }

    private func updateViewFor(_ buttons: [CardTemplate.Button]?) {
        guard let buttons = buttons else { return }
        // Hide extra buttons
        actionButtons.enumerated().forEach {
            if $0 >= buttons.count { $1.isHidden = true } else { $1.isHidden = false; $1.setTitle(buttons[$0].name, for: .normal) }
        }
        let count = CGFloat(min(buttons.count, actionButtons.count))
        buttonStackView.constraint(withIdentifier: ConstraintIdentifier.buttonsView.rawValue)?.constant = count * Config.buttonHeight
    }

    private func setUpButtons() {
        let style = CardStyle.shared
        actionButtons = (0 ..< maxButtonCount).map {
            let button = UIButton()
            button.setTitleColor(style.actionButton.textColor, for: .normal)
            button.setFont(font: Font.button)
            button.setTitle("Button", for: .normal)
            button.addTarget(self, action: #selector(buttonSelected(_:)), for: .touchUpInside)
            button.tag = $0
            button.backgroundColor = .white
            return button
        }
    }

    private func setupConstraints() {
        let view = contentView
        view.backgroundColor = UIColor.white
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(ratingLabel)
        actionButtons.forEach {
            buttonStackView.addArrangedSubview($0)
            $0.heightAnchor.constraint(equalToConstant: Config.buttonHeight).isActive = true
        }
        view.addViewsForAutolayout(views: [coverImageView, overlayText, titleStackView, subtitleLabel, descriptionLabel, buttonsBackground, buttonStackView])
        view.bringSubviewToFront(overlayText)
        view.bringSubviewToFront(buttonStackView)

        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.layer.borderWidth = 1

        coverImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        coverImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        coverImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        coverImageHeight.isActive = true

        overlayText.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        overlayText.centerYAnchor.constraint(equalTo: coverImageView.centerYAnchor, constant: 0).isActive = true
        overlayText.widthAnchor.constraint(equalToConstant: Config.OverlayText.width).isActive = true
        overlayText.heightAnchor.constraint(equalToConstant: Config.OverlayText.height).isActive = true

        titleStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        titleStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        titleStackView.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: Config.spacing).isActive = true
        titleStackView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.titleView.rawValue).isActive = true

        ratingLabel.trailingAnchor.constraint(equalTo: titleStackView.trailingAnchor, constant: -10).isActive = true
        ratingLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 40).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: titleStackView.leadingAnchor).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: ratingLabel.leadingAnchor, constant: -10).isActive = true

        subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        subtitleLabel.topAnchor.constraint(equalTo: titleStackView.bottomAnchor, constant: Config.spacing).isActive = true
        subtitleLabel.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.subtitleView.rawValue).isActive = true

        descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        descriptionLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: Config.spacing).isActive = true
        descriptionLabel.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.descriptionView.rawValue).isActive = true

        buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        buttonStackView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: Config.spacing).isActive = true
        buttonStackView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: ConstraintIdentifier.buttonsView.rawValue).isActive = true

        buttonsBackground.leadingAnchor.constraint(equalTo: buttonStackView.leadingAnchor).isActive = true
        buttonsBackground.trailingAnchor.constraint(equalTo: buttonStackView.trailingAnchor).isActive = true
        buttonsBackground.topAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -1).isActive = true
        buttonsBackground.bottomAnchor.constraint(equalTo: buttonStackView.bottomAnchor).isActive = true
    }
}

public class VerticalAlignLabel: UILabel {
    enum VerticalAlignment {
        case top
        case middle
        case bottom
    }

    var verticalAlignment: VerticalAlignment = .top {
        didSet {
            setNeedsDisplay()
        }
    }

    override public func textRect(forBounds bounds: CGRect, limitedToNumberOfLines: Int) -> CGRect {
        let rect = super.textRect(forBounds: bounds, limitedToNumberOfLines: limitedToNumberOfLines)

        if UIView.userInterfaceLayoutDirection(for: .unspecified) == .rightToLeft {
            switch verticalAlignment {
            case .top:
                return CGRect(x: self.bounds.size.width - rect.size.width, y: bounds.origin.y, width: rect.size.width, height: rect.size.height)
            case .middle:
                return CGRect(x: self.bounds.size.width - rect.size.width, y: bounds.origin.y + (bounds.size.height - rect.size.height) / 2, width: rect.size.width, height: rect.size.height)
            case .bottom:
                return CGRect(x: self.bounds.size.width - rect.size.width, y: bounds.origin.y + (bounds.size.height - rect.size.height), width: rect.size.width, height: rect.size.height)
            }
        } else {
            switch verticalAlignment {
            case .top:
                return CGRect(x: bounds.origin.x, y: bounds.origin.y, width: rect.size.width, height: rect.size.height)
            case .middle:
                return CGRect(x: bounds.origin.x, y: bounds.origin.y + (bounds.size.height - rect.size.height) / 2, width: rect.size.width, height: rect.size.height)
            case .bottom:
                return CGRect(x: bounds.origin.x, y: bounds.origin.y + (bounds.size.height - rect.size.height), width: rect.size.width, height: rect.size.height)
            }
        }
    }

    override public func drawText(in rect: CGRect) {
        let textRect = self.textRect(forBounds: rect, limitedToNumberOfLines: numberOfLines)
        super.drawText(in: textRect)
    }
}

public class InsetLabel: UILabel {
    var insets = UIEdgeInsets()

    convenience init(insets: UIEdgeInsets) {
        self.init(frame: CGRect.zero)
        self.insets = insets
    }

    convenience init(dx: CGFloat, dy: CGFloat) {
        let insets = UIEdgeInsets(top: dy, left: dx, bottom: dy, right: dx)
        self.init(insets: insets)
    }

    override public func drawText(in _: CGRect) {
        super.drawText(in: frame.inset(by: insets))
    }

    override public var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width += insets.left + insets.right
        size.height += insets.top + insets.bottom
        return size
    }
}
