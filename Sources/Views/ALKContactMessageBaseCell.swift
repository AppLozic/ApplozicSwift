//
//  ALKContactMessageBaseCell.swift
//  ApplozicSwift
//
//  Created by Shivam Pokhriyal on 19/04/19.
//

import ApplozicCore
import Contacts

class ALKContactMessageBaseCell: ALKChatBaseCell<ALKMessageViewModel>, ALKHTTPManagerDownloadDelegate {
    let contactView = ContactView(frame: .zero)
    let loadingIndicator = ALKLoadingIndicator(frame: .zero, color: UIColor.red)

    func updateContactDetails(key: String, filePath: String) {
        guard let contact = CNContact.fetchContact(using: filePath) else { return }
        loadingIndicator.stopLoading()
        let contactModel = ContactModel(
            identifier: key,
            contact: contact
        )
        contactView.update(contactModel: contactModel)
        contactView.isHidden = false
    }

    func dataDownloaded(task: ALKDownloadTask) {
        print("Bytes downloaded: %i", task.totalBytesDownloaded)
    }

    func dataDownloadingFinished(task: ALKDownloadTask) {
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier else {
            return
        }
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        DispatchQueue.main.async {
            self.updateContactDetails(key: identifier, filePath: filePath)
        }
    }
}
