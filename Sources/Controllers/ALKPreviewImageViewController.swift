//
//  ViewController.swift
//  TestScrollView
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit

final class ALKPreviewImageViewController: ALKBaseViewController, Localizable {
    // to be injected
    var viewModel: ALKPreviewImageViewModel?

    @IBOutlet private var fakeView: UIView!

    fileprivate let scrollView: UIScrollView = {
        let sv = UIScrollView(frame: .zero)
        sv.backgroundColor = UIColor.clear
        sv.isUserInteractionEnabled = true
        sv.isScrollEnabled = true
        return sv
    }()

    fileprivate let imageView: UIImageView = {
        let mv = UIImageView(frame: .zero)
        mv.contentMode = .scaleAspectFit
        mv.backgroundColor = UIColor.clear
        mv.isUserInteractionEnabled = false
        return mv
    }()

    private weak var imageViewBottomConstraint: NSLayoutConstraint?
    private weak var imageViewTopConstraint: NSLayoutConstraint?
    private weak var imageViewTrailingConstraint: NSLayoutConstraint?
    private weak var imageViewLeadingConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    private func setupNavigation() {
        guard let viewModel = viewModel else { return }
        let title = localizedString(forKey: "RichMessageImagePreviewTitle", withDefaultValue: SystemMessage.PhotoAlbum.PreviewTitle, fileName: viewModel.localizedStringFileName)
        navigationItem.title = title
        let image = UIImage(named: "DownloadiOS", in: Bundle.applozic, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        let button = UIBarButtonItem(image: image?.scale(with: CGSize(width: 24, height: 24)), style: .plain, target: self, action: #selector(downlaodImgPress(_:)))
        button.tintColor = UINavigationBar.appearance().tintColor
        navigationItem.rightBarButtonItem = button
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
        updateMinZoomScaleForSize(size: view.bounds.size)
        updateConstraintsForSize(size: view.bounds.size)
    }

    fileprivate func setupView() {
        guard let viewModel = viewModel else { return }

        scrollView.delegate = self

        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTapped))
        singleTap.numberOfTapsRequired = 1
        scrollView.addGestureRecognizer(singleTap)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(tap:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)

        singleTap.require(toFail: doubleTap)

        imageView.kf.setImage(with: viewModel.imageUrl)
        imageView.sizeToFit()

        view.addViewsForAutolayout(views: [scrollView])
        scrollView.addViewsForAutolayout(views: [imageView])

        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: scrollView.topAnchor)
        imageViewTopConstraint?.isActive = true

        imageViewBottomConstraint = imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        imageViewBottomConstraint?.isActive = true

        imageViewLeadingConstraint = imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
        imageViewLeadingConstraint?.isActive = true

        imageViewTrailingConstraint = imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
        imageViewTrailingConstraint?.isActive = true

        view.layoutIfNeeded()
    }

    private func updateMinZoomScaleForSize(size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)

        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
    }

    fileprivate func updateConstraintsForSize(size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        updateConstraintsXY(xOffset: xOffset, yOffset: yOffset)
    }

    fileprivate func updateConstraintsXY(xOffset: CGFloat, yOffset: CGFloat) {
        imageViewTopConstraint?.constant = yOffset
        imageViewBottomConstraint?.constant = yOffset

        imageViewLeadingConstraint?.constant = xOffset
        imageViewTrailingConstraint?.constant = xOffset
    }

    @IBAction private func dismissPress(_: Any) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction private func downlaodImgPress(_: Any) {
        guard let viewModel = viewModel else { return }

        let showSuccessAlert: () -> Void = {
            let photoAlbumSuccessTitleMsg = self.localizedString(forKey: "PhotoAlbumSuccessTitle", withDefaultValue: SystemMessage.PhotoAlbum.SuccessTitle, fileName: viewModel.localizedStringFileName)
            let photoAlbumSuccessMsg = self.localizedString(forKey: "PhotoAlbumSuccess", withDefaultValue: SystemMessage.PhotoAlbum.Success, fileName: viewModel.localizedStringFileName)
            let alert = UIAlertController(title: photoAlbumSuccessTitleMsg, message: photoAlbumSuccessMsg, preferredStyle: UIAlertController.Style.alert)
            let photoAlbumOkMsg = self.localizedString(forKey: "PhotoAlbumOk", withDefaultValue: SystemMessage.PhotoAlbum.Ok, fileName: viewModel.localizedStringFileName)
            alert.addAction(UIAlertAction(title: photoAlbumOkMsg, style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        let showFailureAlert: (Error) -> Void = { _ in
            let photoAlbumFailureTitleMsg = self.localizedString(forKey: "PhotoAlbumFailureTitle", withDefaultValue: SystemMessage.PhotoAlbum.FailureTitle, fileName: viewModel.localizedStringFileName)
            let photoAlbumFailMsg = self.localizedString(forKey: "PhotoAlbumFail", withDefaultValue: SystemMessage.PhotoAlbum.Fail, fileName: viewModel.localizedStringFileName)
            let alert = UIAlertController(title: photoAlbumFailureTitleMsg, message: photoAlbumFailMsg, preferredStyle: UIAlertController.Style.alert)
            let photoAlbumOkMsg = self.localizedString(forKey: "PhotoAlbumOk", withDefaultValue: SystemMessage.PhotoAlbum.Ok, fileName: viewModel.localizedStringFileName)
            alert.addAction(UIAlertAction(title: photoAlbumOkMsg, style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        viewModel.saveImage(
            image: imageView.image,
            successBlock: showSuccessAlert,
            failBlock: showFailureAlert
        )
    }

    @objc private func doubleTapped(tap: UITapGestureRecognizer) {
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

    @objc private func singleTapped(tap _: UITapGestureRecognizer) {
        if scrollView.minimumZoomScale == scrollView.zoomScale {
            dismiss(animated: true, completion: nil)
        }
    }
}

extension ALKPreviewImageViewController: UIScrollViewDelegate {
    func scrollViewDidZoom(_: UIScrollView) {
        updateConstraintsForSize(size: view.bounds.size)
        view.layoutIfNeeded()
    }

    func viewForZooming(in _: UIScrollView) -> UIView? {
        return imageView
    }
}
