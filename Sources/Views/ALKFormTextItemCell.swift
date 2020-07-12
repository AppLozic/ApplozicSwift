//
//  ALKFormTextItemCell.swift
//  ApplozicSwift
//
//  Created by Mukesh on 08/07/20.
//

import UIKit

class ALKFormTextItemCell: UITableViewCell {
    var item: FormViewModelItem? {
        didSet {
            guard let item = item as? FormViewModelTextItem else {
                return
            }
            nameLabel.text = item.name
            valueTextField.placeholder = item.placeholder
        }
    }

    let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = Font.medium(size: 15).font()
        label.textColor = .black
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

    let valueTextField: UITextField = {
        let textfield = UITextField(frame: .zero)
        return textfield
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addConstraints() {
        addViewsForAutolayout(views: [nameLabel, valueTextField])
        nameLabel.layout {
            $0.leading == leadingAnchor + 10
            $0.trailing == trailingAnchor - 30
            $0.top == topAnchor + 10
        }
        valueTextField.layout {
            $0.leading == nameLabel.leadingAnchor
            $0.trailing == nameLabel.trailingAnchor
            $0.top == nameLabel.bottomAnchor + 5
            $0.bottom <= bottomAnchor - 10
        }
    }
}

class ALKFormMultiSelectItemCell: UITableViewCell {
    var item: FormViewModelMultiselectItem.Option? {
        didSet {
            guard let item = item else {
                return
            }
            nameLabel.text = item.value
        }
    }

    let nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = Font.medium(size: 17).font()
        label.textColor = .black
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onSelection))
        contentView.addGestureRecognizer(tapRecognizer)
        addConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onSelection() {
        accessoryType = (accessoryType == .none) ? .checkmark:.none
    }

    private func addConstraints() {
        addViewsForAutolayout(views: [nameLabel])
        nameLabel.layout {
            $0.leading == leadingAnchor + 10
            $0.trailing == trailingAnchor - 30
            $0.top == topAnchor + 10
            $0.bottom <= bottomAnchor - 10
        }
    }
}

class ALKFormItemHeaderView: UITableViewHeaderFooterView {
    var item: FormViewModelItem? {
        didSet {
            guard let item = item else {
                return
            }
            titleLabel.text = item.sectionTitle
        }
    }

    var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = Font.normal(size: 17).font()
        label.textColor = .black
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .white
        addConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addConstraints() {
        addViewsForAutolayout(views: [titleLabel])
        titleLabel.layout {
            $0.leading == leadingAnchor + 10
            $0.trailing == trailingAnchor - 30
            $0.top == topAnchor + 10
            $0.bottom <= bottomAnchor - 10
        }
    }
}
