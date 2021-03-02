//
//  ALKVideoCell.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 10/07/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import AVKit
import UIKit

class ALKVideoCell: ALKChatBaseCell<ALKMessageViewModel>,
    ALKReplyMenuItemProtocol, ALKReportMessageMenuItemProtocol
{
    enum State {
        case download
        case downloading(progress: Double, totalCount: Int64)
        case downloaded(filePath: String)
        case upload
    }

    var photoView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    var timeLabel: UILabel = {
        let lb = UILabel()
        return lb
    }()

    var fileSizeLabel: UILabel = {
        let lb = UILabel()
        return lb
    }()

    fileprivate var actionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.isHidden = true
        return button
    }()

    fileprivate var downloadButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "DownloadiOS", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.black
        return button
    }()

    fileprivate var playButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "PLAY", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        return button
    }()

    fileprivate var uploadButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "UploadiOS2", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        button.backgroundColor = UIColor.black
        return button
    }()

    var bubbleView: UIView = {
        let bv = UIView()
        bv.clipsToBounds = true
        bv.isUserInteractionEnabled = false
        return bv
    }()

    var progressView: KDCircularProgress = {
        let view = KDCircularProgress(frame: .zero)
        view.startAngle = -90
        view.clockwise = true
        return view
    }()

    private var frontView: ALKTappableView = {
        let view = ALKTappableView()
        view.alpha = 1.0
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()

    var url: URL?

    var uploadTapped: ((Bool) -> Void)?
    var uploadCompleted: ((_ responseDict: Any?) -> Void)?

    var downloadTapped: ((Bool) -> Void)?

    class func topPadding() -> CGFloat {
        return 12
    }

    class func bottomPadding() -> CGFloat {
        return 16
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel, width: CGFloat) -> CGFloat {
        let heigh: CGFloat

        if viewModel.ratio < 1 {
            heigh = viewModel.ratio == 0 ? (width * 0.48) : ceil((width * 0.48) / viewModel.ratio)
        } else {
            heigh = ceil((width * 0.64) / viewModel.ratio)
        }

        return topPadding() + heigh + bottomPadding()
    }

    override func update(viewModel: ALKMessageViewModel) {
        self.viewModel = viewModel
        timeLabel.text = viewModel.time

        if viewModel.isMyMessage {
            if viewModel.isSent || viewModel.isAllRead || viewModel.isAllReceived {
                if let filePath = viewModel.filePath, !filePath.isEmpty {
                    updateView(for: State.downloaded(filePath: filePath))
                } else {
                    updateView(for: State.download)
                }
            } else {
                updateView(for: .upload)
            }
        } else {
            if let filePath = viewModel.filePath, !filePath.isEmpty {
                updateView(for: State.downloaded(filePath: filePath))
            } else {
                updateView(for: State.download)
            }
        }
    }

    @objc func actionTapped(button: UIButton) {
        button.isEnabled = false
    }

    override func setupStyle() {
        super.setupStyle()

        timeLabel.setStyle(ALKMessageStyle.time)
        fileSizeLabel.setStyle(ALKMessageStyle.time)
    }

    override func setupViews() {
        super.setupViews()
        playButton.isHidden = true
        progressView.isHidden = true
        uploadButton.isHidden = true

        frontView.addGestureRecognizer(longPressGesture)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        downloadButton.addTarget(self, action: #selector(ALKVideoCell.downloadButtonAction(_:)), for: UIControl.Event.touchUpInside)
        uploadButton.addTarget(self, action: #selector(ALKVideoCell.uploadButtonAction(_:)), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(ALKVideoCell.playButtonAction(_:)), for: .touchUpInside)

        contentView.addViewsForAutolayout(views: [frontView, photoView, bubbleView, timeLabel, fileSizeLabel, downloadButton, playButton, progressView, uploadButton])
        contentView.bringSubviewToFront(photoView)
        contentView.bringSubviewToFront(frontView)
        contentView.bringSubviewToFront(actionButton)
        contentView.bringSubviewToFront(downloadButton)
        contentView.bringSubviewToFront(playButton)
        contentView.bringSubviewToFront(progressView)
        contentView.bringSubviewToFront(uploadButton)

        frontView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        frontView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        frontView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        frontView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true

        bubbleView.topAnchor.constraint(equalTo: photoView.topAnchor).isActive = true
        bubbleView.bottomAnchor.constraint(equalTo: photoView.bottomAnchor).isActive = true
        bubbleView.leftAnchor.constraint(equalTo: photoView.leftAnchor).isActive = true
        bubbleView.rightAnchor.constraint(equalTo: photoView.rightAnchor).isActive = true

        downloadButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        downloadButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        downloadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

        uploadButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        uploadButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        uploadButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        uploadButton.widthAnchor.constraint(equalToConstant: 50).isActive = true

        playButton.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 60).isActive = true

        progressView.centerXAnchor.constraint(equalTo: photoView.centerXAnchor).isActive = true
        progressView.centerYAnchor.constraint(equalTo: photoView.centerYAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        progressView.widthAnchor.constraint(equalToConstant: 60).isActive = true

        fileSizeLabel.topAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 2).isActive = true
    }

    deinit {
        actionButton.removeTarget(self, action: #selector(actionTapped), for: .touchUpInside)
    }

    func menuReply(_: Any) {
        menuAction?(.reply)
    }

    func menuReport(_: Any) {
        menuAction?(.report)
    }

    @objc private func downloadButtonAction(_: UIButton) {
        downloadTapped?(true)
    }

    @objc private func playButtonAction(_: UIButton) {
        let initialVC = UIStoryboard.name(
            storyboard: UIStoryboard.Storyboard.mediaViewer,
            bundle: Bundle.applozic
        )
        .instantiateInitialViewController()
        guard let nav = initialVC as? ALKBaseNavigationViewController,
              let vc = nav.viewControllers.first as? ALKMediaViewerViewController
        else {
            return
        }
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
        vc.viewModel = ALKMediaViewerViewModel(messages: messageModels, currentIndex: currentIndex, localizedStringFileName: localizedStringFileName)
        UIViewController.topViewController()?.present(nav, animated: true, completion: {
            self.playButton.isEnabled = true
        })
    }

    @objc private func uploadButtonAction(_: UIButton) {
        uploadTapped?(true)
    }

    fileprivate func updateView(for state: State) {
        switch state {
        case .download:
            uploadButton.isHidden = true
            downloadButton.isHidden = false
            photoView.image = UIImage(named: "VIDEO", in: Bundle.applozic, compatibleWith: nil)
            playButton.isHidden = true
            progressView.isHidden = true
        case let .downloaded(filePath):
            uploadButton.isHidden = true
            downloadButton.isHidden = true
            progressView.isHidden = true
            playButton.isHidden = false
            let docDirPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let path = docDirPath.appendingPathComponent(filePath)
            let fileUtills = ALKFileUtils()
            photoView.image = fileUtills.getThumbnail(filePath: path)
        case let .downloading(progress, _):
            // show progress bar
            print("downloading")
            uploadButton.isHidden = true
            downloadButton.isHidden = true
            progressView.isHidden = false
            progressView.angle = progress
            photoView.image = UIImage(named: "VIDEO", in: Bundle.applozic, compatibleWith: nil)
        case .upload:
            downloadButton.isHidden = true
            progressView.isHidden = true
            playButton.isHidden = true
            photoView.image = UIImage(named: "VIDEO", in: Bundle.applozic, compatibleWith: nil)
            uploadButton.isHidden = false
        }
    }

    fileprivate func convertToDegree(total: Int64, written: Int64) -> Double {
        let divergence = Double(total) / 360.0
        let degree = Double(written) / divergence
        return degree
    }
}

extension ALKVideoCell: ALKHTTPManagerUploadDelegate {
    func dataUploaded(task: ALKUploadTask) {
        NSLog("Data uploaded: \(task.totalBytesUploaded) out of total: \(task.totalBytesExpectedToUpload)")
        let progress = convertToDegree(total: task.totalBytesExpectedToUpload, written: task.totalBytesUploaded)
        updateView(for: .downloading(progress: progress, totalCount: task.totalBytesExpectedToUpload))
    }

    func dataUploadingFinished(task: ALKUploadTask) {
        NSLog("VIDEO CELL DATA UPLOADED FOR PATH: %@", viewModel?.filePath ?? "")
        if task.uploadError == nil, task.completed == true, task.filePath != nil {
            DispatchQueue.main.async {
                self.updateView(for: State.downloaded(filePath: task.filePath ?? ""))
            }
        } else {
            DispatchQueue.main.async {
                self.updateView(for: .upload)
            }
        }
    }
}

extension ALKVideoCell: ALKHTTPManagerDownloadDelegate {
    func dataDownloaded(task: ALKDownloadTask) {
        NSLog("VIDEO CELL DATA UPDATED AND FILEPATH IS: %@", viewModel?.filePath ?? "")
        let total = task.totalBytesExpectedToDownload
        let progress = convertToDegree(total: total, written: task.totalBytesDownloaded)
        updateView(for: .downloading(progress: progress, totalCount: total))
    }

    func dataDownloadingFinished(task: ALKDownloadTask) {
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier, viewModel != nil else {
            updateView(for: .download)
            return
        }
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        DispatchQueue.main.async {
            self.updateView(for: .downloaded(filePath: filePath))
        }
    }
}
