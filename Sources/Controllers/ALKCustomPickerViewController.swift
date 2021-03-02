//
//  CustomPickerView.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 14/07/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import Photos
import UIKit

protocol ALKCustomPickerDelegate: AnyObject {
    func filesSelected(images: [UIImage], videos: [String])
}

class ALKCustomPickerViewController: ALKBaseViewController, Localizable {
    // photo library
    var asset: PHAsset!
    var allPhotos: PHFetchResult<PHAsset>!
    var selectedImage: UIImage!
    var cameraMode: ALKCameraPhotoType = .noCropOption
    let option = PHImageRequestOptions()
    var selectedRows = [Int]()
    var selectedFiles = [IndexPath]()
    lazy var imageRequestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.version = .current
        options.isNetworkAccessAllowed = true
        return options
    }()

    @IBOutlet var doneButton: UIBarButtonItem!
    weak var delegate: ALKCustomPickerDelegate?

    @IBOutlet var previewGallery: UICollectionView!

    private lazy var localizedStringFileName: String = configuration.localizedStringFileName

    fileprivate let indicatorSize = ALKActivityIndicator.Size(width: 50, height: 50)
    fileprivate lazy var activityIndicator = ALKActivityIndicator(frame: .zero, backgroundColor: .lightGray, indicatorColor: .white, size: indicatorSize)

    override func viewDidLoad() {
        super.viewDidLoad()

        doneButton.title = localizedString(forKey: "DoneButton", withDefaultValue: SystemMessage.ButtonName.Done, fileName: localizedStringFileName)
        title = localizedString(forKey: "PhotosTitle", withDefaultValue: SystemMessage.LabelName.Photos, fileName: localizedStringFileName)
        checkPhotoLibraryPermission()
        previewGallery.delegate = self
        previewGallery.dataSource = self
        previewGallery.allowsMultipleSelection = true

        view.addViewsForAutolayout(views: [activityIndicator])
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: indicatorSize.width).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: indicatorSize.height).isActive = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
    }

    static func makeInstanceWith(delegate: ALKCustomPickerDelegate, and configuration: ALKConfiguration) -> ALKBaseNavigationViewController? {
        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.picker, bundle: Bundle.applozic)
        guard
            let vc = storyboard.instantiateViewController(withIdentifier: "CustomPickerNavigationViewController")
            as? ALKBaseNavigationViewController,
            let cameraVC = vc.viewControllers.first as? ALKCustomPickerViewController else { return nil }
        cameraVC.delegate = delegate
        cameraVC.configuration = configuration
        return vc
    }

    // MARK: - UI control

    private func setupNavigation() {
        var backImage = UIImage(named: "icon_back", in: Bundle.applozic, compatibleWith: nil)
        backImage = backImage?.imageFlippedForRightToLeftLayoutDirection()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(dismissAction(_:)))
    }

    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            getAllImage(completion: { [weak self] isGrant in
                guard let weakSelf = self else { return }
                weakSelf.createScrollGallery(isGrant: isGrant)
            })
        // handle authorized status
        case .denied, .restricted:
            break
        // handle denied status
        case .notDetermined:
            // ask for permissions
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    self.getAllImage(completion: { [weak self] isGrant in
                        guard let weakSelf = self else { return }
                        weakSelf.createScrollGallery(isGrant: isGrant)
                    })
                // as above
                case .denied, .restricted:
                    break
                default: break
                    // whatever
                }
            }
        @unknown default:
            print("Unknown Permission for photo Library")
        }
    }

    // MARK: - Access to gallery images

    private func getAllImage(completion: (_ success: Bool) -> Void) {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.includeHiddenAssets = false

        let p1 = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        let p2 = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
        allPhotosOptions.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: [p1, p2])
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        (allPhotos != nil) ? completion(true) : completion(false)
    }

    private func createScrollGallery(isGrant: Bool) {
        if isGrant {
            selectedRows = Array(repeating: 0, count: (allPhotos != nil) ? allPhotos.count : 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.previewGallery.reloadData()
            }
        }
    }

    func exportVideoAsset(_ asset: PHAsset, _ completion: @escaping ((_ video: String?) -> Void)) {
        let filename = String(format: "VID-%f.mp4", Date().timeIntervalSince1970 * 1000)
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        var fileurl = URL(fileURLWithPath: documentsUrl.absoluteString).appendingPathComponent(filename)
        print("exporting video to ", fileurl)
        fileurl = fileurl.standardizedFileURL

        let options = PHVideoRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true

        // remove any existing file at that location
        do {
            try FileManager.default.removeItem(at: fileurl)
        } catch {
            // most likely, the file didn't exist.  Don't sweat it
        }

        PHImageManager.default().requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPresetHighestQuality) {
            (exportSession: AVAssetExportSession?, _) in

            if exportSession == nil {
                print("COULD NOT CREATE EXPORT SESSION")
                completion(nil)
                return
            }

            exportSession!.outputURL = fileurl
            exportSession!.outputFileType = AVFileType.mp4 // file type encode goes here, you can change it for other types

            exportSession!.exportAsynchronously {
                switch exportSession!.status {
                case .completed:
                    print("Video exported successfully")
                    completion(fileurl.path)
                case .failed, .cancelled:
                    print("Error while selecting video \(String(describing: exportSession?.error))")
                    completion(nil)
                default:
                    print("Video exporting status \(String(describing: exportSession?.status))")
                    completion(nil)
                }
            }
        }
    }

    @IBAction func doneButtonAction(_: UIBarButtonItem) {
        activityIndicator.startAnimating()
        export { images, videos, error in
            self.activityIndicator.stopAnimating()
            if error {
                let alertTitle = self.localizedString(
                    forKey: "PhotoAlbumFailureTitle",
                    withDefaultValue: SystemMessage.PhotoAlbum.FailureTitle,
                    fileName: self.localizedStringFileName
                )
                let alertMessage = self.localizedString(
                    forKey: "VideoExportError",
                    withDefaultValue: SystemMessage.Warning.videoExportError,
                    fileName: self.localizedStringFileName
                )
                let buttonTitle = self.localizedString(
                    forKey: "OkMessage",
                    withDefaultValue: SystemMessage.ButtonName.ok,
                    fileName: self.localizedStringFileName
                )
                let alert = UIAlertController(
                    title: alertTitle,
                    message: alertMessage,
                    preferredStyle: UIAlertController.Style.alert
                )
                alert.addAction(UIAlertAction(title: buttonTitle, style: UIAlertAction.Style.default, handler: { _ in
                    self.delegate?.filesSelected(images: images, videos: videos)
                    self.navigationController?.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.delegate?.filesSelected(images: images, videos: videos)
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }

    func export(_ completion: @escaping ((_ images: [UIImage], _ videos: [String], _ error: Bool) -> Void)) {
        var selectedImages = [UIImage]()
        var selectedVideos = [String]()
        var error: Bool = false
        let group = DispatchGroup()
        DispatchQueue.global(qos: .background).async {
            for indexPath in self.selectedFiles {
                group.wait()
                group.enter()
                let asset = self.allPhotos.object(at: indexPath.item)
                if asset.mediaType == .video {
                    self.exportVideoAsset(asset) { video in
                        guard let video = video else {
                            error = true
                            group.leave()
                            return
                        }
                        selectedVideos.append(video)
                        group.leave()
                    }
                } else {
                    PHCachingImageManager.default().requestImageData(
                        for: asset,
                        options: self.imageRequestOptions
                    ) { imageData, _, _, _ in
                        guard let imageData = imageData, let image = UIImage(data: imageData) else {
                            error = true
                            group.leave()
                            return
                        }
                        selectedImages.append(image)
                        group.leave()
                    }
                }
            }
            group.wait()
            DispatchQueue.main.async {
                completion(selectedImages, selectedVideos, error)
            }
        }
    }

    @IBAction func dismissAction(_: UIBarButtonItem) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension ALKCustomPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: CollectionViewEnvironment

    private enum CollectionViewEnvironment {
        enum Spacing {
            static let lineitem: CGFloat = 5.0
            static let interitem: CGFloat = 0.0
            static let inset = UIEdgeInsets(top: 0.0, left: 3.0, bottom: 0.0, right: 3.0)
        }
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // grab all the images
        _ = allPhotos.object(at: indexPath.item)
        if selectedRows[indexPath.row] == 1 {
            selectedFiles.remove(object: indexPath)
            selectedRows[indexPath.row] = 0
        } else {
            selectedFiles.append(indexPath)
            selectedRows[indexPath.row] = 1
        }

        previewGallery.reloadItems(at: [indexPath])
    }

    // MARK: UICollectionViewDataSource

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        if allPhotos == nil {
            return 0
        } else {
            return allPhotos.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ALKPhotoCollectionCell", for: indexPath) as! ALKPhotoCollectionCell

//        cell.selectedIcon.isHidden = true
        cell.videoIcon.isHidden = true
        cell.selectedIcon.isHidden = true
        if selectedRows[indexPath.row] == 1 {
            cell.selectedIcon.isHidden = false
        }

        let asset = allPhotos.object(at: indexPath.item)
        if asset.mediaType == .video {
            cell.videoIcon.isHidden = false
        }
        let thumbnailSize = CGSize(width: 200, height: 200)
        option.isSynchronous = true
        PHCachingImageManager.default().requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: option, resultHandler: { image, _ in
            cell.imgPreview.image = image
        })

        cell.imgPreview.backgroundColor = UIColor.white

        return cell
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        return 1
    }

    // MARK: UICollectionViewDelegateFlowLayout

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumLineSpacingForSectionAt _: Int) -> CGFloat {
        return CollectionViewEnvironment.Spacing.lineitem
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, minimumInteritemSpacingForSectionAt _: Int) -> CGFloat {
        return CollectionViewEnvironment.Spacing.interitem
    }

    func collectionView(_: UICollectionView, layout _: UICollectionViewLayout, insetForSectionAt _: Int) -> UIEdgeInsets {
        return CollectionViewEnvironment.Spacing.inset
    }
}
