//
//  ALKConversationViewController+UIImagePicker.swift
//  ApplozicSwift
//
//  Created by Mukesh on 08/11/19.
//

import ApplozicCore
import Foundation

extension ALKConversationViewController:
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate
{
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        // Video attachment
        if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
           mediaType == "public.movie"
        {
            guard let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL else { return }
            print("video path is: ", url.path)
            viewModel.encodeVideo(videoURL: url, completion: {
                path in
                guard let newPath = path else { return }
                var indexPath: IndexPath?
                DispatchQueue.main.async {
                    (_, indexPath) = self.viewModel.sendVideo(atPath: newPath, sourceType: picker.sourceType, metadata: self.configuration.messageMetadata)
                    self.tableView.beginUpdates()
                    self.tableView.insertSections(IndexSet(integer: (indexPath?.section)!), with: .automatic)
                    self.tableView.endUpdates()
                    self.tableView.scrollToBottom(animated: false)
                    guard let newIndexPath = indexPath,
                          let cell = self.tableView.cellForRow(at: newIndexPath) as? ALKMyVideoCell else { return }
                    guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
                        let notificationView = ALNotificationView()
                        notificationView.noDataConnectionNotificationView()
                        return
                    }
                    self.viewModel.uploadVideo(view: cell, indexPath: newIndexPath)
                }
            })
        }

        picker.dismiss(animated: true, completion: nil)
    }
}
