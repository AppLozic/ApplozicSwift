//
//  ALKMediaViewerViewController.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 24/08/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import AVFoundation
import AVKit
import Foundation
import Kingfisher

final class ALKMediaViewerViewController: UIViewController {
    // to be injected
    var viewModel: ALKMediaViewerViewModel?

    @IBOutlet private var fakeView: UIView!

    fileprivate let scrollView: UIScrollView = {
        let sv = UIScrollView(frame: .zero)
        sv.backgroundColor = UIColor.clear
        sv.isUserInteractionEnabled = true
        sv.maximumZoomScale = 5.0
        sv.isScrollEnabled = true
        return sv
    }()

    fileprivate let imageView: UIImageView = {
        let mv = UIImageView(frame: .zero)
        mv.contentMode = .scaleAspectFit
        mv.isUserInteractionEnabled = false
        mv.backgroundColor = UIColor.clear
        return mv
    }()

    fileprivate let playButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "PLAY", in: Bundle.applozic, compatibleWith: nil)
        button.setImage(image, for: .normal)
        return button
    }()

    fileprivate let audioPlayButton: UIButton = {
        let button = UIButton(type: .custom)
        let image = UIImage(named: "audioPlay", in: Bundle.applozic, compatibleWith: nil)
        button.imageView?.tintColor = UIColor.gray
        button.setImage(image, for: .normal)
        return button
    }()

    fileprivate let audioIcon: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.image = UIImage(named: "mic", in: Bundle.applozic, compatibleWith: nil)
        return imageView
    }()

    private weak var imageViewBottomConstraint: NSLayoutConstraint?
    private weak var imageViewTopConstraint: NSLayoutConstraint?
    private weak var imageViewTrailingConstraint: NSLayoutConstraint?
    private weak var imageViewLeadingConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        guard let message = viewModel?.getMessageForCurrentIndex() else { return }
        updateView(message: message)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel?.delegate = self
    }

    fileprivate func setupView() {
        scrollView.delegate = self

        playButton.addTarget(self, action: #selector(ALKMediaViewerViewController.playButtonAction(_:)), for: .touchUpInside)
        audioPlayButton.addTarget(self, action: #selector(ALKMediaViewerViewController.audioPlayButtonAction(_:)), for: .touchUpInside)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(ALKMediaViewerViewController.swipeRightAction)) // put : at the end of method name
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        view.addGestureRecognizer(swipeRight)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(tap:)))

        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(ALKMediaViewerViewController.swipeLeftAction))
        swipeLeft.direction = UISwipeGestureRecognizer.Direction.left
        view.addGestureRecognizer(swipeLeft)

        view.addViewsForAutolayout(views: [scrollView])
        scrollView.addViewsForAutolayout(views: [imageView, playButton, audioPlayButton, audioIcon])

        imageView.bringSubviewToFront(playButton)
        view.bringSubviewToFront(audioPlayButton)
        view.bringSubviewToFront(audioIcon)

        var bottomAnchor: NSLayoutYAxisAnchor {
            if #available(iOS 11.0, *) {
                return self.view.safeAreaLayoutGuide.bottomAnchor
            } else {
                return view.bottomAnchor
            }
        }

        var topAnchor = view.topAnchor
        if #available(iOS 11, *) {
            topAnchor = view.safeAreaLayoutGuide.topAnchor
        }

        scrollView.topAnchor.constraint(equalTo: topAnchor, constant: -70).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        playButton.heightAnchor.constraint(equalToConstant: 80).isActive = true
        playButton.widthAnchor.constraint(equalToConstant: 80).isActive = true

        imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: scrollView.topAnchor)
        imageViewTopConstraint?.isActive = true

        imageViewBottomConstraint = imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        imageViewBottomConstraint?.isActive = true

        imageViewLeadingConstraint = imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
        imageViewLeadingConstraint?.isActive = true

        imageViewTrailingConstraint = imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
        imageViewTrailingConstraint?.isActive = true

        audioPlayButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30).isActive = true
        audioPlayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        audioPlayButton.heightAnchor.constraint(equalToConstant: 100).isActive = true
        audioPlayButton.widthAnchor.constraint(equalToConstant: 100).isActive = true

        audioIcon.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        audioIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        audioIcon.heightAnchor.constraint(equalToConstant: 80).isActive = true
        audioIcon.widthAnchor.constraint(equalToConstant: 50).isActive = true
    }

    @IBAction private func dismissPress(_: Any) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func swipeRightAction() {
        viewModel?.updateCurrentIndex(by: -1)
    }

    @objc private func swipeLeftAction() {
        viewModel?.updateCurrentIndex(by: +1)
    }

    func showPhotoView(message: ALKMessageViewModel) {
        guard let filePath = message.filePath,
              let url = viewModel?.getURLFor(name: filePath),
              let imageData = try? Data(contentsOf: url),
              let image = UIImage(data: imageData)
        else {
            return
        }
        imageView.image = image
        imageView.sizeToFit()
        playButton.isHidden = true
        audioPlayButton.isHidden = true
        audioIcon.isHidden = true
    }

    func showVideoView(message: ALKMessageViewModel) {
        guard let filePath = message.filePath,
              let url = viewModel?.getURLFor(name: filePath) else { return }
        let fileUtills = ALKFileUtils()
        imageView.image = fileUtills.getThumbnail(filePath: url)
        imageView.sizeToFit()
        playButton.isHidden = false
        audioPlayButton.isHidden = true
        audioIcon.isHidden = true
        guard let viewModel = viewModel,
              viewModel.isAutoPlayTrueForCurrentIndex() else { return }
        playVideo()
        viewModel.currentIndexAudioVideoPlayed()
    }

    func showAudioView(message _: ALKMessageViewModel) {
        imageView.image = nil
        audioPlayButton.isHidden = false
        playButton.isHidden = true
        audioIcon.isHidden = false
        guard let viewModel = viewModel,
              viewModel.isAutoPlayTrueForCurrentIndex() else { return }
        playAudio()
        viewModel.currentIndexAudioVideoPlayed()
    }

    fileprivate func updateView(message: ALKMessageViewModel) {
        guard let viewModel = viewModel else { return }
        navigationItem.rightBarButtonItem = nil
        switch message.messageType {
        case .photo:
            print("Photo type")
            updateTitle(title: viewModel.getTitle())
            showPhotoView(message: message)
            updateMinZoomScaleForSize(size: windowSize())
            updateConstraintsForSize(size: windowSize())
            let image = UIImage(named: "DownloadiOS", in: Bundle.applozic, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            let button = UIBarButtonItem(image: image?.scale(with: CGSize(width: 24, height: 24)), style: .plain, target: self, action: #selector(downlaodImgPress(_:)))
            button.tintColor = UINavigationBar.appearance().tintColor
            navigationItem.rightBarButtonItem = button
        case .video:
            print("Video type")
            updateTitle(title: viewModel.getTitle())
            showVideoView(message: message)
            updateMinZoomScaleForSize(size: windowSize())
            updateConstraintsForSize(size: windowSize())
        case .voice:
            print("Audio type")
            updateTitle(title: viewModel.getTitle())
            showAudioView(message: message)
        default:
            print("Other type")
        }
    }

    @IBAction private func downlaodImgPress(_: Any) {
        guard let viewModel = viewModel else { return }

        let showSuccessAlert: () -> Void = {
            let photoAlbumSuccessTitleMsg = viewModel.localizedString(forKey: "PhotoAlbumSuccessTitle", withDefaultValue: SystemMessage.PhotoAlbum.SuccessTitle, fileName: viewModel.localizedStringFileName)
            let photoAlbumSuccessMsg = viewModel.localizedString(forKey: "PhotoAlbumSuccess", withDefaultValue: SystemMessage.PhotoAlbum.Success, fileName: viewModel.localizedStringFileName)
            let alert = UIAlertController(title: photoAlbumSuccessTitleMsg, message: photoAlbumSuccessMsg, preferredStyle: UIAlertController.Style.alert)
            let photoAlbumOkMsg = viewModel.localizedString(forKey: "PhotoAlbumOk", withDefaultValue: SystemMessage.PhotoAlbum.Ok, fileName: viewModel.localizedStringFileName)
            alert.addAction(UIAlertAction(title: photoAlbumOkMsg, style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        let showFailureAlert: (Error) -> Void = { _ in
            let photoAlbumFailureTitleMsg = viewModel.localizedString(forKey: "PhotoAlbumFailureTitle", withDefaultValue: SystemMessage.PhotoAlbum.FailureTitle, fileName: viewModel.localizedStringFileName)
            let photoAlbumFailMsg = viewModel.localizedString(forKey: "PhotoAlbumFail", withDefaultValue: SystemMessage.PhotoAlbum.Fail, fileName: viewModel.localizedStringFileName)
            let alert = UIAlertController(title: photoAlbumFailureTitleMsg, message: photoAlbumFailMsg, preferredStyle: UIAlertController.Style.alert)
            let photoAlbumOkMsg = viewModel.localizedString(forKey: "PhotoAlbumOk", withDefaultValue: SystemMessage.PhotoAlbum.Ok, fileName: viewModel.localizedStringFileName)
            alert.addAction(UIAlertAction(title: photoAlbumOkMsg, style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        viewModel.saveImage(
            image: imageView.image,
            successBlock: showSuccessAlert,
            failBlock: showFailureAlert
        )
    }

    func windowSize() -> CGSize {
        if #available(iOS 11.0, *) {
            let safeAreaInsets = self.view.safeAreaInsets
            return CGSize(width: UIScreen.main.bounds.width - (safeAreaInsets.left + safeAreaInsets.right), height: UIScreen.main.bounds.height - (safeAreaInsets.top + safeAreaInsets.bottom))
        } else {
            // Fallback on earlier versions
            return CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        }
    }

    private func updateTitle(title: String) {
        navigationItem.title = title
    }

    private func playVideo() {
        guard let message = viewModel?.getMessageForCurrentIndex(), let filePath = message.filePath,
              let url = viewModel?.getURLFor(name: filePath) else { return }
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        UIViewController.topViewController()?.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }

    private func playAudio() {
        guard let message = viewModel?.getMessageForCurrentIndex(), let filePath = message.filePath,
              let url = viewModel?.getURLFor(name: filePath) else { return }
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        UIViewController.topViewController()?.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
    }

    @objc private func playButtonAction(_: UIButton) {
        playVideo()
    }

    @objc private func audioPlayButtonAction(_: UIButton) {
        playAudio()
    }

    @objc func doubleTapped(tap: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.5, animations: {
            let view = self.imageView
            let viewFrame = view.frame
            let location = tap.location(in: view)
            let viewWidth = viewFrame.size.width / 2.0
            let viewHeight = viewFrame.size.height / 2.0

            let rect = CGRect(x: location.x - (viewWidth / 2), y: location.y - (viewHeight / 2), width: viewWidth, height: viewHeight)

            if self.scrollView.minimumZoomScale == self.scrollView.zoomScale {
                self.scrollView.zoom(to: rect, animated: false)
            } else {
                self.updateMinZoomScaleForSize(size: self.view.bounds.size)
            }

        }, completion: nil)
    }

    func updateMinZoomScaleForSize(size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)

        guard minScale > 0, minScale <= 5.0 else {
            return
        }

        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }

    func updateConstraintsForSize(size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        updateImageViewConstraintsWith(xOffset: xOffset, yOffset: yOffset)
    }

    func updateImageViewConstraintsWith(xOffset: CGFloat, yOffset: CGFloat) {
        imageViewTopConstraint?.constant = yOffset
        imageViewBottomConstraint?.constant = yOffset

        imageViewLeadingConstraint?.constant = xOffset
        imageViewTrailingConstraint?.constant = xOffset
    }
}

extension ALKMediaViewerViewController: ALKMediaViewerViewModelDelegate {
    func reloadView() {
        guard let message = viewModel?.getMessageForCurrentIndex() else { return }
        updateView(message: message)
    }
}

extension ALKMediaViewerViewController: UIScrollViewDelegate {
    func viewForZooming(in _: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_: UIScrollView) {
        updateConstraintsForSize(size: view.bounds.size)
        view.layoutIfNeeded()
    }
}
