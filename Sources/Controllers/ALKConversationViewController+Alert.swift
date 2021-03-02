//
//  ALKConversationViewController+Alert.swift
//  ApplozicSwift
//
//  Created by Mukesh on 19/09/19.
//

import ApplozicCore
import Foundation

extension ALKConversationViewController: ALAlertButtonClickProtocol {
    func confirmButtonClick(action: String, messageKey: String) {
        let alPushAssist = ALPushAssist()

        if action == ALKAlertViewController.Action.reportMessage {
            alPushAssist.topViewController.dismiss(animated: true, completion: nil)

            guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                return
            }

            let userService = ALUserService()
            let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
            activityIndicator.center = CGPoint(x: view.bounds.size.width / 2,
                                               y: view.bounds.size.height / 2)
            activityIndicator.color = UIColor.gray
            view.addSubview(activityIndicator)
            activityIndicator.startAnimating()

            let message = localizedString(forKey: "ReportMessageSuccess", withDefaultValue: SystemMessage.Information.ReportMessageSuccess, fileName: configuration.localizedStringFileName)

            let errorMessage = localizedString(forKey: "ReportMessageError", withDefaultValue: SystemMessage.Information.ReportMessageError, fileName: configuration.localizedStringFileName)

            userService.reportUser(withMessageKey: messageKey) { _, error in
                activityIndicator.stopAnimating()
                if error == nil {
                    self.showAlert(alertTitle: "", alertMessage: message)
                } else {
                    self.showAlert(alertTitle: "", alertMessage: errorMessage)
                }
            }
        }
    }

    func showAlert(alertTitle: String, alertMessage: String) {
        let alPushAssist = ALPushAssist()
        let title = localizedString(forKey: "OkMessage", withDefaultValue: SystemMessage.ButtonName.ok, fileName: configuration.localizedStringFileName)
        let alert = UIAlertController(
            title: alertTitle,
            message: alertMessage,
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(title: title, style: UIAlertAction.Style.default, handler: nil))
        alPushAssist.topViewController.present(alert, animated: true, completion: nil)
    }

    func menuItemSelected(
        action: ALKChatBaseCell<ALKMessageViewModel>.MenuOption,
        message: ALKMessageViewModel
    ) {
        switch action {
        case .reply:
            print("Reply selected")
            viewModel.setSelectedMessageToReply(message)
            replyMessageView.update(message: message)
            showReplyMessageView()
        case .report:
            let muteConversationVC = ALKAlertViewController(action: ALKAlertViewController.Action.reportMessage, delegate: self, messageKey: message.identifier, configuration: configuration)
            let title = localizedString(forKey: "ReportAlertTitle", withDefaultValue: SystemMessage.Information.ReportAlertTitle, fileName: configuration.localizedStringFileName)
            let message = localizedString(forKey: "ReportAlertMessage", withDefaultValue: SystemMessage.Information.ReportAlertMessage, fileName: configuration.localizedStringFileName)
            muteConversationVC.updateTitleAndMessage(title, message: message)
            muteConversationVC.modalPresentationStyle = .overCurrentContext
            present(muteConversationVC, animated: true, completion: nil)
        case .copy:
            UIPasteboard.general.string = message.message ?? ""
        }
    }
}
