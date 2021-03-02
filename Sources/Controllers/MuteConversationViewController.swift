//
//  MuteConversationViewController.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 15/10/18.
//

import ApplozicCore
import Foundation

@objc protocol Muteable: AnyObject {
    @objc func mute(conversation: ALMessage, forTime: Int64, atIndexPath: IndexPath)
}

class MuteConversationViewController: UIViewController, Localizable {
    var configuration: ALKConfiguration!

    weak var delegate: Muteable?
    var conversation: ALMessage!
    var indexPath: IndexPath!

    private let modalView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.layer.cornerRadius = 20
        return view
    }()

    private let popupTitle: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.black
        label.numberOfLines = 3
        label.font = UIFont(name: "Helvetica", size: 14)
        return label
    }()

    private let timePicker: UIPickerView = {
        let picker = UIPickerView()
        picker.showsSelectionIndicator = true
        return picker
    }()

    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        let title = localizedString(forKey: "ConfirmButton", withDefaultValue: SystemMessage.ButtonName.Confirm, fileName: configuration.localizedStringFileName)
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        let title = localizedString(forKey: "ButtonCancel", withDefaultValue: SystemMessage.ButtonName.Cancel, fileName: configuration.localizedStringFileName)
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        return button
    }()

    private lazy var actionButtons: UIStackView = {
        let buttons = UIStackView(arrangedSubviews: [self.cancelButton, self.confirmButton])
        buttons.axis = .horizontal
        buttons.alignment = .center
        buttons.distribution = .fillEqually
        buttons.spacing = 10.0
        buttons.backgroundColor = UIColor.black
        return buttons
    }()

    lazy var timeValues: [String] = {
        let values = [
            localizedString(forKey: "EightHour", withDefaultValue: SystemMessage.MutePopup.EightHour, fileName: configuration.localizedStringFileName),
            localizedString(forKey: "OneWeek", withDefaultValue: SystemMessage.MutePopup.OneWeek, fileName: configuration.localizedStringFileName),
            localizedString(forKey: "OneYear", withDefaultValue: SystemMessage.MutePopup.OneYear, fileName: configuration.localizedStringFileName),
        ]
        return values
    }()

    init(delegate: Muteable, conversation: ALMessage, atIndexPath: IndexPath, configuration: ALKConfiguration) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        self.conversation = conversation
        indexPath = atIndexPath
        self.configuration = configuration
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupViews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(10, green: 10, blue: 10, alpha: 0.2)
        view.isOpaque = false
    }

    func updateTitle(_ text: String) {
        popupTitle.text = text
    }

    func selectPickerRow(_ row: Int) {
        timePicker.selectRow(row, inComponent: 0, animated: true)
    }

    func setUpPickerView() {
        // Picker view delegate and datasource
        timePicker.delegate = self
        timePicker.dataSource = self

        // Default set first row i.e. 8 hours
        selectPickerRow(0)
    }

    @objc func tappedConfirm() {
        switch timePicker.selectedRow(inComponent: 0) {
        case 0:
            // 8 hours
            let time: Int64 = 8 * 60 * 60 * 1000
            delegate?.mute(conversation: conversation, forTime: Int64(time), atIndexPath: indexPath)

        case 1:
            // 1 week
            let time: Int64 = 7 * 24 * 60 * 60 * 1000
            delegate?.mute(conversation: conversation, forTime: Int64(time), atIndexPath: indexPath)

        case 2:
            // 1 year
            let time: Int64 = 365 * 24 * 60 * 60 * 1000
            delegate?.mute(conversation: conversation, forTime: Int64(time), atIndexPath: indexPath)

        default:
            print("This won't occur")
        }

        dismiss(animated: true, completion: nil)
    }

    @objc func tappedCancel() {
        dismiss(animated: true, completion: nil)
    }

    func setupViews() {
        view.addViewsForAutolayout(views: [modalView])

        modalView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        modalView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        modalView.heightAnchor.constraint(equalToConstant: 200).isActive = true
        modalView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        modalView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true

        modalView.addViewsForAutolayout(views: [popupTitle, timePicker, actionButtons])

        popupTitle.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: 10).isActive = true
        popupTitle.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -10).isActive = true
        popupTitle.topAnchor.constraint(equalTo: modalView.topAnchor, constant: 10).isActive = true

        timePicker.topAnchor.constraint(equalTo: popupTitle.bottomAnchor, constant: 2).isActive = true
        timePicker.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: 2).isActive = true
        timePicker.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: 2).isActive = true

        actionButtons.topAnchor.constraint(equalTo: timePicker.bottomAnchor, constant: 2).isActive = true
        actionButtons.leadingAnchor.constraint(equalTo: modalView.leadingAnchor, constant: 2).isActive = true
        actionButtons.trailingAnchor.constraint(equalTo: modalView.trailingAnchor, constant: -2).isActive = true
        actionButtons.bottomAnchor.constraint(equalTo: modalView.bottomAnchor).isActive = true

        setUpPickerView()

        // Add button actions
        confirmButton.addTarget(self, action: #selector(tappedConfirm), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(tappedCancel), for: .touchUpInside)
    }
}

extension MuteConversationViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in _: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        return timeValues.count
    }

    func pickerView(_: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        return timeValues[row]
    }
}
