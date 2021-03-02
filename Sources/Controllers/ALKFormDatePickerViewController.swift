//
//  ALKFormDatePickerViewController.swift
//  ApplozicSwift
//
//  Created by Sunil on 30/09/20.
//

import Foundation

@objc protocol ALKDatePickerButtonClickProtocol {
    func confirmButtonClick(position: Int, date: Date, messageKey: String, datePickerMode: UIDatePicker.Mode)
}

class ALKFormDatePickerViewController: UIViewController, Localizable {
    enum Padding {
        enum ModelView {
            static let left: CGFloat = 30.0
            static let right: CGFloat = 30.0
            static let bottomY: CGFloat = 50.0
        }

        enum TitleLabel {
            static let top: CGFloat = 20.0
            static let left: CGFloat = 10.0
            static let right: CGFloat = 10.0
        }

        enum DatePickerView {
            static let top: CGFloat = 20.0
            static let left: CGFloat = 10.0
            static let right: CGFloat = 10.0
            static let bottom: CGFloat = 30.0
        }

        enum ButtonUIView {
            static let height: CGFloat = 40.0
            static let top: CGFloat = 10.0
        }

        enum CancelButton {
            static let height: CGFloat = 40.0
        }

        enum ConfirmButton {
            static let height: CGFloat = 40.0
            static let left: CGFloat = 3.0
        }
    }

    weak var delegate: ALKDatePickerButtonClickProtocol?
    var action: String!
    var messageKey: String!
    var datePickerMode: UIDatePicker.Mode!
    var localizedStringFileName: String!
    var position: Int!

    private let modalView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 5
        return view
    }()

    private let popupTitle: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.black
        label.numberOfLines = 3
        label.font = Font.bold(size: 18.0).font()
        return label
    }()

    private let uiDatePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.autoresizingMask = .flexibleRightMargin
        if #available(iOS 14.0, *) {
            datePicker.preferredDatePickerStyle = .inline
        } else if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .compact
        }
        datePicker.date = Date()
        return datePicker
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        let title = localizedString(forKey: "DoneButton",
                                    withDefaultValue: SystemMessage.ButtonName.Done,
                                    fileName: localizedStringFileName).uppercased()
        button.setTitle(title, for: .normal)
        button.isUserInteractionEnabled = true
        button.setTitleColor(UIView().tintColor, for: .normal)
        button.setFont(font: Font.normal(size: 16.0).font())
        button.setBackgroundColor(UIColor(red: 242.0 / 255.0, green: 242.0 / 255.0, blue: 242.0 / 255.0, alpha: 1.0))
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        let title = localizedString(forKey: "CapitalLetterCancelText",
                                    withDefaultValue: SystemMessage.ButtonName.CapitalLetterCancelText,
                                    fileName: localizedStringFileName)
        button.setTitle(title, for: .normal)
        button.isUserInteractionEnabled = true
        button.setFont(font: Font.normal(size: 16.0).font())
        button.setTitleColor(UIColor.black, for: .normal)
        button.setBackgroundColor(UIColor(red: 242.0 / 255.0, green: 242.0 / 255.0, blue: 242.0 / 255.0, alpha: 1.0))
        return button
    }()

    private let buttonUIView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 93.7, green: 93.7, blue: 93.7, alpha: 1.0)
        return view
    }()

    init(delegate: ALKDatePickerButtonClickProtocol,
         messageKey: String,
         position: Int,
         datePickerMode: UIDatePicker.Mode,
         localizedStringFileName: String)
    {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        self.messageKey = messageKey
        self.position = position
        self.datePickerMode = datePickerMode
        self.localizedStringFileName = localizedStringFileName
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addConstraints()
        setupViews()
    }

    private func addConstraints() {
        view.addViewsForAutolayout(views: [modalView])
        modalView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        modalView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -Padding.ModelView.bottomY).isActive = true
        modalView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Padding.ModelView.left).isActive = true
        modalView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Padding.ModelView.right).isActive = true

        modalView.addViewsForAutolayout(views: [popupTitle,
                                                uiDatePicker,
                                                buttonUIView,
                                                cancelButton,
                                                confirmButton])
        popupTitle.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: Padding.TitleLabel.left).isActive = true
        popupTitle.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -Padding.TitleLabel.right).isActive = true
        popupTitle.topAnchor.constraint(equalTo: modalView.topAnchor, constant: Padding.TitleLabel.top).isActive = true

        uiDatePicker.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: Padding.DatePickerView.left).isActive = true
        uiDatePicker.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -Padding.DatePickerView.right).isActive = true
        uiDatePicker.topAnchor.constraint(equalTo: popupTitle.bottomAnchor, constant: Padding.DatePickerView.top).isActive = true
        uiDatePicker.bottomAnchor.constraint(equalTo: modalView.bottomAnchor, constant: -Padding.DatePickerView.bottom).isActive = true

        buttonUIView.heightAnchor.constraint(equalToConstant: Padding.ButtonUIView.height).isActive = true
        buttonUIView.leadingAnchor.constraint(equalTo: modalView.leadingAnchor).isActive = true
        buttonUIView.trailingAnchor.constraint(equalTo: modalView.trailingAnchor).isActive = true
        buttonUIView.topAnchor.constraint(equalTo: uiDatePicker.bottomAnchor, constant: Padding.ButtonUIView.top).isActive = true

        let halfWidth = (UIScreen.main.bounds.width - 60) / 2

        cancelButton.heightAnchor.constraint(equalToConstant: Padding.CancelButton.height).isActive = true
        cancelButton.leadingAnchor.constraint(equalTo: modalView.leadingAnchor).isActive = true
        cancelButton.widthAnchor.constraint(equalToConstant: halfWidth).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: buttonUIView.bottomAnchor).isActive = true

        confirmButton.heightAnchor.constraint(equalToConstant: Padding.ConfirmButton.height).isActive = true
        confirmButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: Padding.ConfirmButton.left).isActive = true
        confirmButton.trailingAnchor.constraint(equalTo: buttonUIView.trailingAnchor).isActive = true
        confirmButton.bottomAnchor.constraint(equalTo: buttonUIView.bottomAnchor).isActive = true

        cancelButton.addTarget(self, action: #selector(tappedCancel), for: .touchUpInside)

        confirmButton.addTarget(self, action: #selector(tappedConfirmButton), for: .touchUpInside)
    }

    private func setupViews() {
        view.backgroundColor = UIColor(10, green: 10, blue: 10, alpha: 0.2)
        view.isOpaque = false
        view.isUserInteractionEnabled = true
        uiDatePicker.datePickerMode = datePickerMode
        switch datePickerMode {
        case .time:
            popupTitle.text = localizedString(forKey: "DatePickerTimeTitle",
                                              withDefaultValue: SystemMessage.LabelName.DatePickerTimeTitle,
                                              fileName: localizedStringFileName)
        case .date:
            popupTitle.text = localizedString(forKey: "DatePickerDateTitle",
                                              withDefaultValue: SystemMessage.LabelName.DatePickerDateTitle,
                                              fileName: localizedStringFileName)
        case .dateAndTime:
            popupTitle.text = localizedString(forKey: "DatePickerDateAndTimeTitle",
                                              withDefaultValue: SystemMessage.LabelName.DatePickerDateAndTimeTitle,
                                              fileName: localizedStringFileName)
        default:
            popupTitle.text = ""
        }
    }

    @objc private func tappedCancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func tappedConfirmButton() {
        delegate?.confirmButtonClick(position: position,
                                     date: uiDatePicker.date,
                                     messageKey: messageKey,
                                     datePickerMode: datePickerMode)
        dismiss(animated: true, completion: nil)
    }
}
