//
//  ALKDocumentCell.swift
//  ApplozicSwift
//
//  Created by Sunil on 05/03/19.
//

import ApplozicCore
import Foundation
import Kingfisher
import UIKit

class ALKDocumentCell: ALKChatBaseCell<ALKMessageViewModel> {
    enum CommonPadding {
        enum FrameUIView {
            static let top: CGFloat = 5
            static let leading: CGFloat = 5
            static let height: CGFloat = 40
            static let trailing: CGFloat = 5
        }

        enum DocumentView {
            static let top: CGFloat = 7
            static let leading: CGFloat = 10
            static let height: CGFloat = 22
            static let width: CGFloat = 14
        }

        enum FileNameLabel {
            static let leading: CGFloat = 5
            static let trailing: CGFloat = 40
        }

        enum DownloadButton {
            static let top: CGFloat = 5
            static let trailing: CGFloat = 5
            static let height: CGFloat = 27
            static let width: CGFloat = 27
        }

        enum FileTypeView {
            static let height: CGFloat = 20
        }
    }

    enum State {
        case download
        case downloading(progress: Double, totalCount: Int64)
        case downloaded(filePath: String)
        case upload
    }

    var uploadTapped: ((Bool) -> Void)?
    var uploadCompleted: ((_ responseDict: Any?) -> Void)?
    var downloadTapped: ((Bool) -> Void)?

    var docImageView: UIImageView = {
        let imv = UIImageView()
        imv.image = UIImage(named: "ic_alk_document", in: Bundle.applozic, compatibleWith: nil)
        imv.backgroundColor = .clear
        imv.clipsToBounds = true
        return imv
    }()

    var downloadButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "ic_alk_download", in: Bundle.applozic, compatibleWith: nil)
        button.isUserInteractionEnabled = true
        button.setImage(image, for: .normal)
        return button
    }()

    var bubbleView: UIImageView = {
        let imv = UIImageView()
        imv.backgroundColor = .clear
        imv.contentMode = .scaleAspectFill
        imv.clipsToBounds = true
        return imv
    }()

    var fileNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 12)
        label.isOpaque = true
        label.textColor = .black
        return label
    }()

    var sizeAndFileType: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 12)
        label.isOpaque = true
        label.textColor = .black
        return label
    }()

    var timeLabel: UILabel = {
        let lb = UILabel()
        return lb
    }()

    var frameUIView: UIView = {
        let uiView = UIView()
        uiView.backgroundColor = UIColor(231, green: 231, blue: 232)
        return uiView
    }()

    var progressView: KDCircularProgress = {
        let view = KDCircularProgress(frame: .zero)
        view.startAngle = -90
        view.isHidden = true
        view.clockwise = true
        return view
    }()

    let frontView: ALKTappableView = {
        let view = ALKTappableView()
        view.backgroundColor = .clear
        return view
    }()

    override func setupStyle() {
        super.setupStyle()
        timeLabel.setStyle(ALKMessageStyle.time)
    }

    override func setupViews() {
        super.setupViews()

        contentView.addViewsForAutolayout(views: [bubbleView, frameUIView, downloadButton, fileNameLabel, docImageView, sizeAndFileType, frontView, progressView])

        contentView.bringSubviewToFront(downloadButton)
        contentView.bringSubviewToFront(progressView)
        frontView.addGestureRecognizer(longPressGesture)

        let topToOpen = UITapGestureRecognizer(target: self, action: #selector(openWKWebView(gesture:)))

        frontView.isUserInteractionEnabled = true
        frontView.addGestureRecognizer(topToOpen)

        downloadButton.addTarget(self, action: #selector(downloadButtonAction(_:)), for: UIControl.Event.touchUpInside)

        frameUIView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: CommonPadding.FrameUIView.top).isActive = true

        frameUIView.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: CommonPadding.FrameUIView.leading).isActive = true

        frameUIView.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -CommonPadding.FrameUIView.trailing).isActive = true

        frameUIView.heightAnchor.constraint(equalToConstant: CommonPadding.FrameUIView.height).isActive = true

        frontView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        frontView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor).isActive = true
        frontView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        frontView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor).isActive = true

        docImageView.topAnchor.constraint(equalTo: frameUIView.topAnchor, constant: CommonPadding.DocumentView.top).isActive = true
        docImageView.leadingAnchor.constraint(equalTo: frameUIView.leadingAnchor, constant: CommonPadding.DocumentView.leading).isActive = true
        docImageView.widthAnchor.constraint(equalToConstant: CommonPadding.DocumentView.width).isActive = true
        docImageView.heightAnchor.constraint(equalToConstant: CommonPadding.DocumentView.height).isActive = true

        fileNameLabel.centerYAnchor.constraint(equalTo: frameUIView.centerYAnchor).isActive = true
        fileNameLabel.leadingAnchor.constraint(equalTo: docImageView.trailingAnchor, constant: CommonPadding.FileNameLabel.leading).isActive = true
        fileNameLabel.trailingAnchor.constraint(equalTo: frameUIView.trailingAnchor, constant: -CommonPadding.FileNameLabel.trailing).isActive = true

        downloadButton.topAnchor.constraint(equalTo: frameUIView.topAnchor, constant: CommonPadding.DownloadButton.top).isActive = true
        downloadButton.trailingAnchor.constraint(equalTo: frameUIView.trailingAnchor, constant: -CommonPadding.DownloadButton.trailing).isActive = true

        downloadButton.widthAnchor.constraint(equalToConstant: CommonPadding.DownloadButton.width).isActive = true
        downloadButton.heightAnchor.constraint(equalToConstant: CommonPadding.DownloadButton.height).isActive = true

        sizeAndFileType.topAnchor.constraint(equalTo: frameUIView.bottomAnchor).isActive = true
        sizeAndFileType.leadingAnchor.constraint(equalTo: frameUIView.leadingAnchor).isActive = true
        sizeAndFileType.trailingAnchor.constraint(equalTo: frameUIView.trailingAnchor).isActive = true
        sizeAndFileType.heightAnchor.constraint(equalToConstant: CommonPadding.FileTypeView.height).isActive = true

        progressView.topAnchor.constraint(equalTo: downloadButton.topAnchor).isActive = true
        progressView.trailingAnchor.constraint(equalTo: downloadButton.trailingAnchor).isActive = true
        progressView.heightAnchor.constraint(equalToConstant: 27).isActive = true
        progressView.widthAnchor.constraint(equalToConstant: 27).isActive = true
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel, width: CGFloat) -> CGFloat {
        return super.rowHeigh(viewModel: viewModel, width: width)
    }

    @objc func openWKWebView(gesture _: UITapGestureRecognizer) {
        guard (viewModel?.filePath) != nil else {
            print("File is not downloaded")
            return
        }
        let docViewController = ALKDocumentViewerController()
        docViewController.filePath = viewModel?.filePath ?? ""
        docViewController.fileName = viewModel?.fileMetaInfo?.name ?? ""
        let pushAssist = ALPushAssist()
        pushAssist.topViewController.navigationController?.pushViewController(docViewController, animated: true)
    }

    class func commonHeightPadding() -> CGFloat {
        return CommonPadding.FrameUIView.height + CommonPadding.FrameUIView.top
            + CommonPadding.FileTypeView.height
    }

    override func update(viewModel: ALKMessageViewModel) {
        self.viewModel = viewModel
        timeLabel.text = viewModel.time

        fileNameLabel.text = ALKFileUtils().getFileName(filePath: viewModel.filePath, fileMeta: viewModel.fileMetaInfo)

        let size = ALKFileUtils().getFileSize(filePath: viewModel.filePath, fileMetaInfo: viewModel.fileMetaInfo) ?? ""

        let fileType = ALKFileUtils().getFileExtenion(filePath: viewModel.filePath, fileMeta: viewModel.fileMetaInfo)

        if !size.isEmpty {
            sizeAndFileType.text = size + " \u{2022} " + fileType
        }

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

    @objc private func downloadButtonAction(_: UIButton) {
        downloadTapped?(true)
    }

    func updateView(for state: State) {
        switch state {
        case .download:
            downloadButton.isHidden = false
            progressView.isHidden = true
        case let .downloaded(filePath):
            downloadButton.isHidden = true
            progressView.isHidden = true
            viewModel?.filePath = filePath
        case let .downloading(progress, _):
            // show progress bar
            downloadButton.isHidden = true
            progressView.isHidden = false
            progressView.angle = progress
        case .upload:
            downloadButton.isHidden = true
            progressView.isHidden = true
        }
    }

    fileprivate func convertToDegree(total: Int64, written: Int64) -> Double {
        let divergence = Double(total) / 360.0
        let degree = Double(written) / divergence
        return degree
    }
}

extension ALKDocumentCell: ALKHTTPManagerUploadDelegate {
    func dataUploaded(task: ALKUploadTask) {
        print("Data uploaded: \(task.totalBytesUploaded) out of total: \(task.totalBytesExpectedToUpload)")
        let progress = convertToDegree(total: task.totalBytesExpectedToUpload, written: task.totalBytesUploaded)
        updateView(for: .downloading(progress: progress, totalCount: task.totalBytesExpectedToUpload))
    }

    func dataUploadingFinished(task: ALKUploadTask) {
        print("Document CELL DATA UPLOADED FOR PATH: %@", viewModel?.filePath ?? "")
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

extension ALKDocumentCell: ALKHTTPManagerDownloadDelegate {
    func dataDownloaded(task: ALKDownloadTask) {
        print("Document CELL DATA UPDATED AND FILEPATH IS", viewModel?.filePath ?? "")
        let total = task.totalBytesExpectedToDownload
        let progress = convertToDegree(total: total, written: task.totalBytesDownloaded)
        updateView(for: .downloading(progress: progress, totalCount: total))
    }

    func dataDownloadingFinished(task: ALKDownloadTask) {
        guard task.downloadError == nil, let filePath = task.filePath, let identifier = task.identifier, viewModel != nil else {
            DispatchQueue.main.async {
                self.updateView(for: .download)
            }
            return
        }
        ALMessageDBService().updateDbMessageWith(key: "key", value: identifier, filePath: filePath)
        DispatchQueue.main.async {
            self.updateView(for: .downloaded(filePath: filePath))
        }
    }
}
