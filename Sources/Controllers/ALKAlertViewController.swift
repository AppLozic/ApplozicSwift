//
//  ALKReportMessageViewController.swift
//  ApplozicSwift
//
//  Created by apple on 01/07/19.
//

import Foundation

import ApplozicCore

class ALKAlertViewController: UIViewController, Localizable {
    public enum Action {
        static let reportMessage: String = "REPORT_MESSAGE"
    }

    public enum Padding {
        enum ModelView {
            static let height: CGFloat = 200.0
            static let left: CGFloat = 30.0
            static let right: CGFloat = 30.0
        }

        enum TitleLabel {
            static let top: CGFloat = 30.0
            static let left: CGFloat = 10.0
            static let right: CGFloat = 10.0
        }

        enum MessageLabel {
            static let top: CGFloat = 12.0
            static let left: CGFloat = 20.0
            static let right: CGFloat = 20.0
        }

        enum ButtonUIView {
            static let height: CGFloat = 50.0
        }

        enum CancelButton {
            static let height: CGFloat = 50.0
        }

        enum ConfirmButton {
            static let height: CGFloat = 50.0
            static let left: CGFloat = 3.0
        }
    }

    weak var delegate: ALAlertButtonClickProtocol?
    var action: String!
    var configuration: ALKConfiguration!
    var messageKey: String!

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

    private let alertMessageLabel: UILabel = {
        let picker = UILabel()
        picker.numberOfLines = 4
        picker.font = Font.light(size: 14.0).font()
        return picker
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        let title = localizedString(forKey: "ReportMessage", withDefaultValue: SystemMessage.ButtonName.ReportMessage, fileName: configuration.localizedStringFileName).uppercased()
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIView().tintColor, for: .normal)
        button.setFont(font: Font.normal(size: 16.0).font())
        button.setBackgroundColor(UIColor(red: 242.0 / 255.0, green: 242.0 / 255.0, blue: 242.0 / 255.0, alpha: 1.0))
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        let title = localizedString(forKey: "CapitalLetterCancelText", withDefaultValue: SystemMessage.ButtonName.CapitalLetterCancelText, fileName: configuration.localizedStringFileName)
        button.setTitle(title, for: .normal)
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

    init(action: String, delegate: ALAlertButtonClickProtocol, messageKey: String, configuration: ALKConfiguration) {
        super.init(nibName: nil, bundle: nil)
        self.messageKey = messageKey
        self.action = action
        self.delegate = delegate
        self.configuration = configuration
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        view.backgroundColor = UIColor(10, green: 10, blue: 10, alpha: 0.2)
        view.isOpaque = false
    }

    func updateTitleAndMessage(_ text: String, message: String) {
        popupTitle.text = text
        alertMessageLabel.text = message
    }

    @objc func tappedCancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc func tappedConfirmButton() {
        delegate?.confirmButtonClick(action: action, messageKey: messageKey)
    }

    func setupViews() {
        view.addViewsForAutolayout(views: [modalView])

        modalView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        modalView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        modalView.heightAnchor.constraint(equalToConstant: Padding.ModelView.height).isActive = true
        modalView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Padding.ModelView.left).isActive = true
        modalView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Padding.ModelView.right).isActive = true

        modalView.addViewsForAutolayout(views: [popupTitle, alertMessageLabel, buttonUIView, cancelButton, confirmButton])

        popupTitle.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: Padding.TitleLabel.left).isActive = true
        popupTitle.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -Padding.TitleLabel.right).isActive = true
        popupTitle.topAnchor.constraint(equalTo: modalView.topAnchor, constant: Padding.TitleLabel.top).isActive = true

        alertMessageLabel.topAnchor.constraint(equalTo: popupTitle.bottomAnchor, constant: Padding.MessageLabel.top).isActive = true
        alertMessageLabel.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: Padding.MessageLabel.left).isActive = true
        alertMessageLabel.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -Padding.MessageLabel.right).isActive = true

        buttonUIView.heightAnchor.constraint(equalToConstant: Padding.ButtonUIView.height).isActive = true
        buttonUIView.leadingAnchor.constraint(equalTo: modalView.leadingAnchor).isActive = true
        buttonUIView.trailingAnchor.constraint(equalTo: modalView.trailingAnchor).isActive = true
        buttonUIView.bottomAnchor.constraint(equalTo: modalView.bottomAnchor).isActive = true

        let halfWidth = (UIScreen.main.bounds.width - 60) / 2

        cancelButton.heightAnchor.constraint(equalToConstant: Padding.CancelButton.height).isActive = true
        cancelButton.leadingAnchor.constraint(equalTo: modalView.leadingAnchor).isActive = true
        cancelButton.widthAnchor.constraint(equalToConstant: halfWidth).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: modalView.bottomAnchor).isActive = true

        confirmButton.heightAnchor.constraint(equalToConstant: Padding.ConfirmButton.height).isActive = true
        confirmButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: Padding.ConfirmButton.left).isActive = true
        confirmButton.trailingAnchor.constraint(equalTo: buttonUIView.trailingAnchor).isActive = true
        confirmButton.bottomAnchor.constraint(equalTo: modalView.bottomAnchor).isActive = true

        cancelButton.addTarget(self, action: #selector(tappedCancel), for: .touchUpInside)

        confirmButton.addTarget(self, action: #selector(tappedConfirmButton), for: .touchUpInside)
    }
}

@objc protocol ALAlertButtonClickProtocol {
    func confirmButtonClick(action: String, messageKey: String)
}
