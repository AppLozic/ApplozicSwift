//
//  ALKAttatchmentView.swift
//  ApplozicSwift
//
//  Created by apple on 18/10/19.
//

import ApplozicCore
import Foundation
import Kingfisher
import UIKit

class ALKAttatchmentView: UIView {
    let loadingIndicator = ALKLoadingIndicator(frame: .zero, color: UIColor.gray)
    var message: ALMessage?

    enum Padding {
        enum ImgaeView {
            static let bottom: CGFloat = 5.0
            static let left: CGFloat = 5.0
            static let right: CGFloat = 5.0
            static let height: CGFloat = 5.0
        }
    }

    private var attachmentImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(message: ALMessage, localizationFileName: String) {
        self.message = message
        loadingIndicator.startLoading(localizationFileName: localizationFileName)
        if message.imageFilePath == nil, message.contentType != Int16(ALMESSAGE_CONTENT_LOCATION) {
            download()
        } else if let filePath = message.imageFilePath {
            updateView(filePath: filePath)
        } else if message.contentType == Int16(ALMESSAGE_CONTENT_LOCATION) {
            showLocation()
        }
    }

    func setupConstraints() {
        addViewsForAutolayout(views: [attachmentImage, loadingIndicator])
        bringSubviewToFront(loadingIndicator)

        attachmentImage.heightAnchor.constraint(equalTo: heightAnchor, constant: -Padding.ImgaeView.height).isActive = true
        attachmentImage.leadingAnchor.constraint(equalTo: leadingAnchor, constant: -Padding.ImgaeView.left).isActive = true
        attachmentImage.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Padding.ImgaeView.right).isActive = true
        attachmentImage.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Padding.ImgaeView.bottom).isActive = true

        loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        loadingIndicator.topAnchor.constraint(equalTo: topAnchor).isActive = true
        loadingIndicator.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    func download() {
        guard ALDataNetworkConnection.checkDataNetworkAvailable() else {
            let notificationView = ALNotificationView()
            notificationView.noDataConnectionNotificationView()
            return
        }

        guard let messageObject = message else {
            return
        }
        // if ALApplozicSettings.isS3StorageServiceEnabled or ALApplozicSettings.isGoogleCloudServiceEnabled is true its private url we wont be able to download it directly.
        let serviceEnabled = ALApplozicSettings.isS3StorageServiceEnabled() || ALApplozicSettings.isGoogleCloudServiceEnabled()

        if let url = messageObject.fileMetaInfo?.url,
           !serviceEnabled
        {
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = self
            let task = ALKDownloadTask(downloadUrl: url, fileName: messageObject.fileMetaInfo?.name)
            task.identifier = messageObject.identifier
            task.totalBytesExpectedToDownload = messageObject.size
            httpManager.downloadImage(task: task)
            return
        }
        ALMessageClientService().downloadImageUrl(messageObject.fileMetaInfo?.blobKey) { fileUrl, error in
            guard error == nil, let fileUrl = fileUrl else {
                print("Error downloading attachment :: \(String(describing: error))")
                return
            }
            let httpManager = ALKHTTPManager()
            httpManager.downloadDelegate = self
            let task = ALKDownloadTask(downloadUrl: fileUrl, fileName: messageObject.fileMetaInfo?.name)
            task.identifier = messageObject.identifier
            task.totalBytesExpectedToDownload = messageObject.size
            httpManager.downloadAttachment(task: task)
        }
    }

    func updateView(filePath _: String) {
        loadingIndicator.stopLoading()
        guard let metaContentType = message?.fileMeta.contentType else {
            return
        }
        if metaContentType.hasPrefix("image") {
            showImageView()
        } else if metaContentType.hasPrefix("video") {
            showVideoView()
        }
    }

    func showImageView() {
        let fileUtills = ALKFileUtils()
        guard let filePath = message?.filePath else { return }
        let path = fileUtills.getDocumentDirectory(fileName: filePath)
        let provider = LocalFileImageDataProvider(fileURL: path)
        attachmentImage.kf.setImage(with: provider)
    }

    func showVideoView() {
        let fileUtills = ALKFileUtils()
        guard let filePath = message?.filePath else { return }
        let url = fileUtills.getDocumentDirectory(fileName: filePath)
        attachmentImage.image = fileUtills.getThumbnail(filePath: url)
        attachmentImage.sizeToFit()
    }

    func showLocation() {
        loadingIndicator.stopLoading()
        let mapUrl = getMapImageURL()
        attachmentImage.kf.setImage(with: mapUrl, placeholder: UIImage(
            named: "map_no_data",
            in: Bundle.applozic,
            compatibleWith: nil
        ))
    }

    func getMapImageURL() -> URL? {
        guard message?.contentType == Int16(ALMESSAGE_CONTENT_LOCATION) else { return nil }
        let url = ALUtilityClass.getLocationUrl(message) as String
        return URL(string: url)
    }
}

extension ALKAttatchmentView: ALKHTTPManagerDownloadDelegate {
    func dataDownloaded(task _: ALKDownloadTask) {}

    func dataDownloadingFinished(task: ALKDownloadTask) {
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier, message != nil else {
            return
        }
        DispatchQueue.main.async {
            ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
            self.message?.imageFilePath = filePath
            self.updateView(filePath: filePath)
        }
    }
}
