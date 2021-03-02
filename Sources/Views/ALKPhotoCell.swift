//
//  ALKPhotoCell.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import Foundation
import Kingfisher
import UIKit

// MARK: - ALKPhotoCell

class ALKPhotoCell: ALKChatBaseCell<ALKMessageViewModel>,
    ALKReplyMenuItemProtocol, ALKReportMessageMenuItemProtocol
{
    var photoView: UIImageView = {
        let mv = UIImageView()
        mv.backgroundColor = .clear
        mv.contentMode = .scaleAspectFill
        mv.clipsToBounds = true
        return mv
    }()

    var timeLabel: UILabel = {
        let lb = UILabel()
        return lb
    }()

    var fileSizeLabel: UILabel = {
        let lb = UILabel()
        return lb
    }()

    var bubbleView: UIView = {
        let bv = UIView()
        bv.isUserInteractionEnabled = false
        return bv
    }()

    private var frontView: ALKTappableView = {
        let view = ALKTappableView()
        view.alpha = 1.0
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()

    fileprivate var downloadButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "DownloadiOS", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.black
        return button
    }()

    var uploadButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "UploadiOS2", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.black
        return button
    }()

    fileprivate let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)

    var captionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    static var maxWidth = UIScreen.main.bounds.width

    // To be changed from the class that is subclassing `ALKPhotoCell`
    class var messageTextFont: UIFont {
        return Font.normal(size: 12).font()
    }

    // This will be used to calculate the size of the photo view.
    static var heightPercentage: CGFloat = 0.5
    static var widthPercentage: CGFloat = 0.48

    enum Padding {
        enum CaptionLabel {
            static var bottom: CGFloat = 10.0
            static var left: CGFloat = 5.0
            static var right: CGFloat = 5.0
        }
    }

    var url: URL?
    enum State {
        case upload(filePath: String)
        case uploading(filePath: String)
        case uploaded
        case download
        case downloading
        case downloaded(filePath: String)
    }

    var uploadTapped: ((Bool) -> Void)?
    var uploadCompleted: ((_ responseDict: Any?) -> Void)?

    var downloadTapped: ((Bool) -> Void)?

    class func topPadding() -> CGFloat {
        return 12
    }

    class func bottomPadding() -> CGFloat {
        return 16
    }

    override class func rowHeigh(
        viewModel: ALKMessageViewModel,
        width: CGFloat
    ) -> CGFloat {
        var height: CGFloat

        height = ceil(width * heightPercentage)
        if let message = viewModel.message, !message.isEmpty {
            height += message.rectWithConstrainedWidth(
                width * widthPercentage,
                font: messageTextFont
            ).height.rounded(.up) + Padding.CaptionLabel.bottom
        }

        return topPadding() + height + bottomPadding()
    }

    override func update(viewModel: ALKMessageViewModel) {
        self.viewModel = viewModel
        activityIndicator.color = .black
        print("Update ViewModel filePath:: %@", viewModel.filePath ?? "")
        if viewModel.isMyMessage {
            if viewModel.isSent || viewModel.isAllRead || viewModel.isAllReceived {
                if let filePath = viewModel.filePath, !filePath.isEmpty {
                    updateView(for: State.downloaded(filePath: filePath))
                } else {
                    updateView(for: State.download)
                }
            } else {
                if let filePath = viewModel.filePath, !filePath.isEmpty {
                    updateView(for: .upload(filePath: filePath))
                }
            }
        } else {
            if let filePath = viewModel.filePath, !filePath.isEmpty {
                updateView(for: State.downloaded(filePath: filePath))
            } else {
                updateView(for: State.download)
            }
        }
        timeLabel.text = viewModel.time
        captionLabel.text = viewModel.message
    }

    @objc func actionTapped(button: UIButton) {
        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.mediaViewer, bundle: Bundle.applozic)

        let nav = storyboard.instantiateInitialViewController() as? UINavigationController
        let vc = nav?.viewControllers.first as? ALKMediaViewerViewController
        let dbService = ALMessageDBService()
        guard let messages = dbService.getAllMessagesWithAttachment(
            forContact: viewModel?.contactId,
            andChannelKey: viewModel?.channelKey,
            onlyDownloadedAttachments: true
        ) as? [ALMessage] else { return }

        let messageModels = messages.map { $0.messageModel }
        NSLog("Messages with attachment: ", messages)

        guard let viewModel = viewModel as? ALKMessageModel,
              let currentIndex = messageModels.firstIndex(of: viewModel) else { return }
        vc?.viewModel = ALKMediaViewerViewModel(messages: messageModels, currentIndex: currentIndex, localizedStringFileName: localizedStringFileName)
        UIViewController.topViewController()?.present(nav!, animated: true, completion: {
            button.isEnabled = true
        })
    }

    override func setupStyle() {
        super.setupStyle()

        timeLabel.setStyle(ALKMessageStyle.time)
        fileSizeLabel.setStyle(ALKMessageStyle.time)
    }

    override func setupViews() {
        super.setupViews()
        frontView.addGestureRecognizer(longPressGesture)
        uploadButton.isHidden = true
        uploadButton.addTarget(self, action: #selector(ALKPhotoCell.uploadButtonAction(_:)), for: .touchUpInside)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(actionTapped))
        singleTap.numberOfTapsRequired = 1
        frontView.addGestureRecognizer(singleTap)

        downloadButton.addTarget(self, action: #selector(ALKPhotoCell.downloadButtonAction(_:)), for: .touchUpInside)
        contentView.addViewsForAutolayout(views:
            [frontView,
             photoView,
             bubbleView,
             timeLabel,
             fileSizeLabel,
             captionLabel,
             uploadButton,
             downloadButton,
             activityIndicator])
        contentView.bringSubviewToFront(photoView)
        contentView.bringSubviewToFront(frontView)
        contentView.bringSubviewToFront(downloadButton)
        contentView.bringSubviewToFront(uploadButton)
        contentView.bringSubviewToFront(activityIndicator)

        frontView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        frontView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        frontView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        frontView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true

        bubbleView.topAnchor.constraint(equalTo: photoView.topAnchor).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: captionLabel.bottomAnchor).isActive = true
        bubbleView.leftAnchor.constraint(equalTo: photoView.leftAnchor).isActive = true
        bubbleView.rightAnchor.constraint(equalTo: photoView.rightAnchor).isActive = true

        fileSizeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: 40).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: 50).isActive = true
        activityIndicator.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true

        uploadButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        uploadButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        uploadButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        uploadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        downloadButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        downloadButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        downloadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

        // CaptionLabel's Bottom Padding calculation:
        //
        // First understand how total view's(ContentView) height is calculated:
        // ContentView => topPadding + PhotoView + CaptionLabel
        //               + captionLabelBottomPadding(if caption is there) + bottomPadding
        //
        // Here's how CaptionLabel's vertical Constraints are calculated:
        // CaptionLabelTop -> PhotoView.top
        //
        // CaptionLabelBottom -> (contentView - bottomPadding) which is equal to
        // (CaptionLabel + captionLabelBottom)

        captionLabel.layout {
            $0.leading == photoView.leadingAnchor + Padding.CaptionLabel.left
            $0.trailing == photoView.trailingAnchor - Padding.CaptionLabel.right
            $0.top == photoView.bottomAnchor
            $0.bottom == contentView.bottomAnchor - ALKPhotoCell.bottomPadding()
        }
    }

    @objc private func downloadButtonAction(_: UIButton) {
        downloadTapped?(true)
    }

    func updateView(for state: State) {
        DispatchQueue.main.async {
            self.updateView(state: state)
        }
    }

    private func updateView(state: State) {
        switch state {
        case let .upload(filePath):
            frontView.isUserInteractionEnabled = false
            activityIndicator.isHidden = true
            downloadButton.isHidden = true
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(filePath)
            setPhotoViewImageFromFileURL(path)
            uploadButton.isHidden = false
        case .uploaded:
            if activityIndicator.isAnimating {
                activityIndicator.stopAnimating()
            }
            frontView.isUserInteractionEnabled = true
            uploadButton.isHidden = true
            activityIndicator.isHidden = true
            downloadButton.isHidden = true
        case .uploading:
            uploadButton.isHidden = true
            frontView.isUserInteractionEnabled = false
            activityIndicator.isHidden = false
            if !activityIndicator.isAnimating {
                activityIndicator.startAnimating()
            }
            downloadButton.isHidden = true
        case .download:
            downloadButton.isHidden = false
            frontView.isUserInteractionEnabled = false
            activityIndicator.isHidden = true
            uploadButton.isHidden = true
            loadThumbnail()
        case .downloading:
            uploadButton.isHidden = true
            activityIndicator.isHidden = false
            if !activityIndicator.isAnimating {
                activityIndicator.startAnimating()
            }
            downloadButton.isHidden = true
            frontView.isUserInteractionEnabled = false
        case let .downloaded(filePath):
            activityIndicator.isHidden = false
            if !activityIndicator.isAnimating {
                activityIndicator.startAnimating()
            }
            if activityIndicator.isAnimating {
                activityIndicator.stopAnimating()
            }
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(filePath)
            setPhotoViewImageFromFileURL(path)
            frontView.isUserInteractionEnabled = true
            uploadButton.isHidden = true
            activityIndicator.isHidden = true
            downloadButton.isHidden = true
        }
    }

    func loadThumbnail() {
        guard let message = viewModel, let metadata = message.fileMetaInfo else {
            return
        }
        guard ALApplozicSettings.isS3StorageServiceEnabled() || ALApplozicSettings.isGoogleCloudServiceEnabled() else {
            photoView.kf.setImage(with: message.thumbnailURL)
            return
        }
        guard let thumbnailPath = metadata.thumbnailFilePath else {
            ALMessageClientService().downloadImageThumbnailUrl(metadata.thumbnailUrl, blobKey: metadata.thumbnailBlobKey) { url, error in
                guard error == nil,
                      let url = url
                else {
                    print("Error downloading thumbnail url")
                    return
                }
                let httpManager = ALKHTTPManager()
                httpManager.downloadDelegate = self
                let task = ALKDownloadTask(downloadUrl: url, fileName: metadata.name)
                task.identifier = ThumbnailIdentifier.addPrefix(to: message.identifier)
                httpManager.downloadAttachment(task: task)
            }
            return
        }
        setThumbnail(thumbnailPath)
    }

    func setImage(imageView: UIImageView, name: String) {
        DispatchQueue.global(qos: .background).async {
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(name)
            do {
                let data = try Data(contentsOf: path)
                DispatchQueue.main.async {
                    imageView.image = UIImage(data: data)
                }
            } catch {
                DispatchQueue.main.async {
                    imageView.image = nil
                }
            }
        }
    }

    @objc private func uploadButtonAction(_: UIButton) {
        uploadTapped?(true)
    }

    fileprivate func updateThumbnailPath(_ key: String, filePath: String) {
        let messageKey = ThumbnailIdentifier.removePrefix(from: key)
        guard let dbMessage = ALMessageDBService().getMessageByKey("key", value: messageKey) as? DB_Message else { return }
        dbMessage.fileMetaInfo.thumbnailFilePath = filePath

        let dbHandler = ALDBHandler.sharedInstance()
        let error = dbHandler?.saveContext()
        if error != nil {
            print("Not saved due to error \(String(describing: error))")
        }
    }

    fileprivate func setThumbnail(_ path: String) {
        let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let path = docDirPath.appendingPathComponent(path)
        setPhotoViewImageFromFileURL(path)
    }

    func menuReply(_: Any) {
        menuAction?(.reply)
    }

    func setPhotoViewImageFromFileURL(_ fileURL: URL) {
        let provider = LocalFileImageDataProvider(fileURL: fileURL)
        photoView.kf.setImage(with: provider)
    }

    func menuReport(_: Any) {
        menuAction?(.report)
    }
}

extension ALKPhotoCell: ALKHTTPManagerUploadDelegate {
    func dataUploaded(task: ALKUploadTask) {
        NSLog("VIDEO CELL DATA UPDATED AND FILEPATH IS: %@", viewModel?.filePath ?? "")
        DispatchQueue.main.async {
            print("task filepath:: ", task.filePath ?? "")
            self.updateView(for: .uploading(filePath: task.filePath ?? ""))
        }
    }

    func dataUploadingFinished(task: ALKUploadTask) {
        NSLog("VIDEO CELL DATA UPLOADED FOR PATH: %@", viewModel?.filePath ?? "")
        if task.uploadError == nil, task.completed == true, task.filePath != nil {
            DispatchQueue.main.async {
                self.updateView(for: State.uploaded)
            }
        } else {
            DispatchQueue.main.async {
                self.updateView(for: .upload(filePath: task.filePath ?? ""))
            }
        }
    }
}

extension ALKPhotoCell: ALKHTTPManagerDownloadDelegate {
    func dataDownloaded(task: ALKDownloadTask) {
        NSLog("Image Bytes downloaded: %i", task.totalBytesDownloaded)
        guard
            let identifier = task.identifier,
            !ThumbnailIdentifier.hasPrefix(in: identifier)
        else {
            return
        }
        DispatchQueue.main.async {
            self.updateView(for: .downloading)
        }
    }

    func dataDownloadingFinished(task: ALKDownloadTask) {
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier, viewModel != nil else {
            return
        }
        guard !ThumbnailIdentifier.hasPrefix(in: identifier) else {
            DispatchQueue.main.async {
                self.setThumbnail(filePath)
            }
            updateThumbnailPath(identifier, filePath: filePath)
            return
        }
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        DispatchQueue.main.async {
            self.updateView(for: .downloaded(filePath: filePath))
        }
    }
}
