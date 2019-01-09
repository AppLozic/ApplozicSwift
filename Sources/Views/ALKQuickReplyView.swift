//
//  ALKQuickReplyCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 07/01/19.
//
struct QuickReplySettings {
    static let font = UIFont.systemFont(ofSize: 14)
}

class ALKQuickReplyView: UIView {

    let font = QuickReplySettings.font
    let maxWidth: CGFloat

    let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.distribution = .fill
        return stackView
    }()

    public var quickReplySelected: ((_ index: Int?, _ name: String, _ dict: Dictionary<String, Any>?) -> ())?

    init(frame: CGRect, maxWidth: CGFloat) {
        self.maxWidth = maxWidth
        super.init(frame: frame)
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(quickReplyArray: [Dictionary<String, Any>]) {
        setupQuickReplyButtons(quickReplyArray)
    }

    class func rowHeight(quickReplyArray: [Dictionary<String, Any>], maxWidth: CGFloat) -> CGFloat {
        let font = QuickReplySettings.font
        var width: CGFloat = 0
        var height: CGFloat = 0
        var size = CGSize(width: 0, height: 0)

        for dict in quickReplyArray {
            let title = dict["title"] as? String ?? ""
            size = ALKCurvedButton.buttonSize(text: title, maxWidth: maxWidth, font: font)
            let currWidth = size.width

            if width + currWidth > maxWidth {
                width = width > 0 ? currWidth : 0
                height += size.height + 10
                size = CGSize(width: 0, height: 0) //Empty size
            } else {
                width += currWidth + 10 //spacing
            }
        }

        height += size.height
        return height
    }

    private func setupConstraints() {
        self.addViewsForAutolayout(views: [mainStackView])
        mainStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        mainStackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }

    private func setupQuickReplyButtons(_ quickReplyArray: [Dictionary<String, Any>]) {
        mainStackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }
        var width: CGFloat = 0
        var subviews = [UIView]()
        var index: Int = 0
        for quickReply in quickReplyArray {
            guard let title = quickReply["title"] as? String else {
                continue
            }
            index += 1
            let button = curvedButton(title: title, index: index, metadata: quickReply["replyMetadata"] as? Dictionary<String, Any>)
            width += button.buttonWidth()

            if width >= maxWidth {
                guard subviews.count > 0 else {
                    let stackView = horizontalStackView(subviews: [button])
                    mainStackView.addArrangedSubview(stackView)
                    width = 0
                    continue
                }
                let hiddenView = hiddenViewUsing(currWidth: width - button.buttonWidth(), maxWidth: maxWidth, subViews: subviews)
                subviews.append(hiddenView)
                width = button.buttonWidth()
                let stackView = horizontalStackView(subviews: subviews)
                mainStackView.addArrangedSubview(stackView)
                subviews.removeAll()
                subviews.append(button)
            } else {
                width += 10
                subviews.append(button)
            }
        }
        let hiddenView = hiddenViewUsing(currWidth: width, maxWidth: maxWidth, subViews: subviews)
        subviews.append(hiddenView)
        let stackView = horizontalStackView(subviews: subviews)
        mainStackView.addArrangedSubview(stackView)
    }

    private func horizontalStackView(subviews: [UIView]) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: subviews)
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.distribution = .fill
        return stackView
    }

    private func hiddenViewUsing(currWidth: CGFloat, maxWidth: CGFloat, subViews: [UIView]) -> UIView {
        let unusedWidth = maxWidth - currWidth - 20
        let height = (subviews[0] as? ALKCurvedButton)?.buttonHeight() ?? 0
        let size = CGSize(width: unusedWidth, height: height)

        let view = UIView()
        view.backgroundColor = .clear
        view.frame.size = size
        return view
    }

    private func curvedButton(title: String, index: Int, metadata: Dictionary<String, Any>?) -> ALKCurvedButton {
        let button = ALKCurvedButton(title: title, font: font, maxWidth: maxWidth)
        button.index = index
        button.buttonSelected = { [weak self] index, title in
            self?.quickReplySelected?(index, title, metadata)
        }
        return button
    }
}
