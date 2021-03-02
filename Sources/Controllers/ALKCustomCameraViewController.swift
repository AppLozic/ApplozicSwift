//
//  ALKCustomCameraViewController.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import AVFoundation
import Photos
import UIKit

enum ALKCameraPhotoType {
    case noCropOption
    case cropOption
}

enum ALKCameraType {
    case front
    case back
}

var camera = ALKCameraType.back

protocol ALKCustomCameraProtocol: AnyObject {
    func customCameraDidTakePicture(cropedImage: UIImage)
}

final class ALKCustomCameraViewController: ALKBaseViewController, AVCapturePhotoCaptureDelegate, Localizable {
    // delegate
    weak var customCamDelegate: ALKCustomCameraProtocol?
    var camera = ALKCameraType.back

    // photo library
    var asset: PHAsset!
    var allPhotos: PHFetchResult<PHAsset>!
    var selectedImage: UIImage!
    var cameraMode: ALKCameraPhotoType = .noCropOption
    let option = PHImageRequestOptions()

    var cameraOutput: Any? = {
        AVCapturePhotoOutput()
    }()

    lazy var imageRequestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.version = .current
        options.isNetworkAccessAllowed = true
        return options
    }()

    @IBOutlet private var previewView: UIView!
    @IBOutlet private var btnCapture: UIButton!
    @IBOutlet private var previewGallery: UICollectionView!
    @IBOutlet private var btnSwitchCam: UIButton!

    private var captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    // If we find a device we'll store it here for later use
    private var captureDevice: AVCaptureDevice?
    private var captureDeviceInput: AVCaptureDeviceInput?
    fileprivate let indicatorSize = ALKActivityIndicator.Size(width: 50, height: 50)
    fileprivate lazy var activityIndicator = ALKActivityIndicator(
        frame: .zero,
        backgroundColor: .lightGray,
        indicatorColor: .white,
        size: indicatorSize
    )
    fileprivate var isUserControlEnable = true

    fileprivate lazy var localizedStringFileName: String = configuration.localizedStringFileName

    override func viewDidLoad() {
        super.viewDidLoad()
        title = localizedString(forKey: "Camera", withDefaultValue: SystemMessage.LabelName.Camera, fileName: localizedStringFileName)
        btnSwitchCam.isHidden = true
        checkPhotoLibraryPermission()
        reloadCamera()
        addConstraints()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
        setupView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // ask for permission
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
        case .denied:
            // ask for permissions

            let camNotAvailable = localizedString(forKey: "CamNotAvaiable", withDefaultValue: SystemMessage.Warning.CamNotAvaiable, fileName: localizedStringFileName)
            let pleaseAllowCamera = localizedString(forKey: "PleaseAllowCamera", withDefaultValue: SystemMessage.Camera.PleaseAllowCamera, fileName: localizedStringFileName)
            let alertController = UIAlertController(title: camNotAvailable, message: pleaseAllowCamera, preferredStyle: .alert)
            let settingsTitle = localizedString(forKey: "Settings", withDefaultValue: SystemMessage.LabelName.Settings, fileName: localizedStringFileName)
            let settingsAction = UIAlertAction(title: settingsTitle, style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }
            alertController.addAction(settingsAction)
            let cancelTitle = localizedString(forKey: "Cancel", withDefaultValue: SystemMessage.LabelName.Cancel, fileName: localizedStringFileName)
            let cancelAction = UIAlertAction(title: cancelTitle, style: .default, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        default: ()
        }
    }

    static func makeInstanceWith(delegate: ALKCustomCameraProtocol, and configuration: ALKConfiguration) -> ALKBaseNavigationViewController? {
        let storyboard = UIStoryboard.name(storyboard: UIStoryboard.Storyboard.camera, bundle: Bundle.applozic)
        guard
            let vc = storyboard.instantiateViewController(withIdentifier: "CustomCameraNavigationController")
            as? ALKBaseNavigationViewController,
            let cameraVC = vc.viewControllers.first as? ALKCustomCameraViewController else { return nil }
        cameraVC.setCustomCamDelegate(camMode: .noCropOption, camDelegate: delegate)
        cameraVC.configuration = configuration
        return vc
    }

    func capturePhoto() {
        let cameraOutput = self.cameraOutput as? AVCapturePhotoOutput
        if let connection = cameraOutput?.connection(with: AVMediaType.video) {
            if connection.isVideoOrientationSupported,
               let orientation = AVCaptureVideoOrientation(orientation: UIDevice.current.orientation)
            {
                connection.videoOrientation = orientation
            }

            let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])

            if connection.isActive {
                cameraOutput?.capturePhoto(with: settings, delegate: self)
                // connection is active
            } else {
                // connection is not active
                // try to change self.captureSession.sessionPreset,
                // or change videoDevice.activeFormat
            }
        }
    }

    public func photoOutput(
        _: AVCapturePhotoOutput,
        didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
        previewPhoto _: CMSampleBuffer?,
        resolvedSettings _: AVCaptureResolvedPhotoSettings,
        bracketSettings _: AVCaptureBracketedStillImageSettings?,
        error: Swift.Error?
    ) {
        if let error = error {
            print(error)
        } else if let buffer = photoSampleBuffer,
                  let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(
                      forJPEGSampleBuffer: buffer,
                      previewPhotoSampleBuffer: nil
                  ),
                  let image = UIImage(data: data)
        {
            selectedImage = image
            switch cameraMode {
            case .cropOption:
                performSegue(withIdentifier: "goToCropImageView", sender: nil)
            default:
                performSegue(withIdentifier: "pushToALKCustomCameraPreviewViewController", sender: nil)
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLayoutSubviews() {
        // set frame
        previewLayer?.frame = previewView.frame
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Set protocol and Observer

    func setCustomCamDelegate(camMode: ALKCameraPhotoType, camDelegate: ALKCustomCameraProtocol) {
        cameraMode = camMode
        customCamDelegate = camDelegate
    }

    // MARK: - UI control

    private func setupNavigation() {
        var backImage = UIImage(named: "icon_back", in: Bundle.applozic, compatibleWith: nil)
        backImage = backImage?.imageFlippedForRightToLeftLayoutDirection()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(dismissCameraPress(_:)))
    }

    private func setupView() {
        btnCapture.imageView?.tintColor = UIColor.white
        btnSwitchCam.imageView?.tintColor = UIColor.white
    }

    private func addConstraints() {
        view.addViewsForAutolayout(views: [activityIndicator])
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        activityIndicator.widthAnchor.constraint(equalToConstant: indicatorSize.width).isActive = true
        activityIndicator.heightAnchor.constraint(equalToConstant: indicatorSize.height).isActive = true
    }

    private func reloadCamera() {
        // stop previous capture session
        captureSession.stopRunning()
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.removeFromSuperlayer()
        self.previewLayer?.removeFromSuperlayer()

        // Do any additional setup after loading the view.
        captureSession.sessionPreset = AVCaptureSession.Preset.high

        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        ).devices
        for device in devices {
            if camera == .back {
                if device.position == AVCaptureDevice.Position.back {
                    captureDevice = device
                    if captureDevice != nil {
                        checkCameraPermission()
                    }
                }
            } else {
                if device.position == AVCaptureDevice.Position.front {
                    captureDevice = device
                    if captureDevice != nil {
                        checkCameraPermission()
                    }
                }
            }
        }
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
            print("Unknown Photo Library Permission state")
        }
    }

    private func checkCameraPermission() {
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
        case .authorized:
            btnSwitchCam.isHidden = false
            beginSession()
        case .denied:
            // ask for permissions

            let camNotAvailable = localizedString(forKey: "CamNotAvaiable", withDefaultValue: SystemMessage.Warning.CamNotAvaiable, fileName: localizedStringFileName)
            let pleaseAllowCamera = localizedString(forKey: "PleaseAllowCamera", withDefaultValue: SystemMessage.Camera.PleaseAllowCamera, fileName: localizedStringFileName)

            let alertController = UIAlertController(title: camNotAvailable, message: pleaseAllowCamera, preferredStyle: .alert)
            let settingsTitle = localizedString(forKey: "Settings", withDefaultValue: SystemMessage.LabelName.Settings, fileName: localizedStringFileName)
            let settingsAction = UIAlertAction(title: settingsTitle, style: .default) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }

                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }
            alertController.addAction(settingsAction)
            let cancelTitle = localizedString(forKey: "Cancel", withDefaultValue: SystemMessage.LabelName.Cancel, fileName: localizedStringFileName)
            let cancelAction = UIAlertAction(title: cancelTitle, style: .default, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        case .notDetermined:
            // ask for permissions
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { [weak self] isGrant in
                guard let weakSelf = self else { return }
                if isGrant {
                    DispatchQueue.main.async {
                        weakSelf.btnSwitchCam.isHidden = false
                    }
                }
            })
            beginSession()
        default: ()
        }
    }

    @IBAction private func actionCameraCapture(_: AnyObject) {
        saveToCamera()
    }

    private func beginSession() {
        do {
            if let captureDevice = captureDevice {
                let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                captureSession.addInput(captureDeviceInput)
                let cameraOutput = self.cameraOutput as? AVCapturePhotoOutput
                cameraOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])], completionHandler: nil)

                if captureSession.canAddOutput(cameraOutput!) {
                    captureSession.addOutput(cameraOutput!)
                }
            } else {
                return
            }
        } catch {
            print("Error while adding camera input: \(error)")
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

        // orientation of video
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        var initialVideoOrientation = AVCaptureVideoOrientation.portrait
        if statusBarOrientation != UIInterfaceOrientation.unknown {
            initialVideoOrientation = AVCaptureVideoOrientation(rawValue: statusBarOrientation.rawValue)!
        }

        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoOrientation = initialVideoOrientation
        self.previewLayer = previewLayer
        // add camera view
        previewView.layer.addSublayer(previewLayer)
        captureSession.startRunning()
    }

    private func saveToCamera() {
        if isUserControlEnable {
            isUserControlEnable = false
            capturePhoto()
            enableCameraControl(inSec: 1)
        }
    }

    private func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        return context.createCGImage(inputImage, from: inputImage.extent)
    }

    @IBAction private func switchCamPress(_: Any) {
        if isUserControlEnable {
            isUserControlEnable = false

            if camera == .back {
                camera = .front
            } else {
                camera = .back
            }

            let devices = AVCaptureDevice.DiscoverySession(
                deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                mediaType: .video,
                position: .unspecified
            ).devices

            let newCamera: AVCaptureDevice?
            if camera == .front {
                newCamera = cameraWithPosition(
                    position: AVCaptureDevice.Position.front,
                    in: devices
                )
            } else {
                newCamera = cameraWithPosition(
                    position: AVCaptureDevice.Position.back,
                    in: devices
                )
            }

            guard let newCam = newCamera else { return }

            let currentCameraInput: AVCaptureInput = captureSession.inputs[0]
            captureSession.removeInput(currentCameraInput)

            do {
                try captureSession.addInput(AVCaptureDeviceInput(device: newCam))
                let cameraOutput = self.cameraOutput as? AVCapturePhotoOutput

                cameraOutput?.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecJPEG])], completionHandler: nil)

                if captureSession.canAddOutput(cameraOutput!) {
                    captureSession.addOutput(cameraOutput!)
                }

            } catch {
                print("Error while adding camera input: \(error)")
            }
            captureSession.commitConfiguration()

            enableCameraControl(inSec: 1)
        }
    }

    private func cameraWithPosition(
        position: AVCaptureDevice.Position,
        in devices: [AVCaptureDevice]
    ) -> AVCaptureDevice? {
        for device in devices where (device as AnyObject).position == position {
            return device
        }
        return AVCaptureDevice(uniqueID: "")
    }

    @IBAction private func dismissCameraPress(_: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    private func enableCameraControl(inSec: Double) {
        let disT = DispatchTime.now() + inSec
        DispatchQueue.main.asyncAfter(deadline: disT) {
            self.isUserControlEnable = true
        }
    }

    // MARK: - Access to gallery images

    private func getAllImage(completion: (_ success: Bool) -> Void) {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.includeHiddenAssets = false
        allPhotosOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        (allPhotos != nil) ? completion(true) : completion(false)
    }

    private func createScrollGallery(isGrant: Bool) {
        if isGrant {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.previewGallery.reloadData()
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        var destination = segue.destination
        if let topViewController = (destination as? UINavigationController)?.topViewController {
            destination = topViewController
        }

        if let cropView = destination as? ALKCustomCropImageViewController {
            cropView.configuration = configuration
            cropView.setSelectedImage(pickImage: selectedImage, camDelegate: customCamDelegate)

        } else if let customCameraPreviewVC = destination as? ALKCustomCameraPreviewViewController {
            customCameraPreviewVC.configuration = configuration
            customCameraPreviewVC.setSelectedImage(pickImage: selectedImage, camDelegate: customCamDelegate)
        }
    }
}

extension ALKCustomCameraViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: CollectionViewEnvironment

    private enum CollectionViewEnvironment {
        enum Spacing {
            static let lineitem: CGFloat = 5.0
            static let interitem: CGFloat = 0.0
            static let inset = UIEdgeInsets(top: 0.0, left: 6.0, bottom: 0.0, right: 6.0)
        }
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = allPhotos.object(at: indexPath.item)
        activityIndicator.startAnimating()
        PHCachingImageManager.default().requestImageData(
            for: asset,
            options: imageRequestOptions
        ) { imageData, _, _, _ in
            self.activityIndicator.stopAnimating()
            guard let imageData = imageData, let image = UIImage(data: imageData) else {
                self.showImageExportFailureAlert()
                return
            }
            self.selectedImage = image
            switch self.cameraMode {
            case .cropOption:
                self.performSegue(withIdentifier: "goToCropImageView", sender: nil)
            default:
                self.performSegue(withIdentifier: "pushToALKCustomCameraPreviewViewController", sender: nil)
            }
        }
    }

    // MARK: UICollectionViewDataSource

    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        if allPhotos == nil {
            return 0
        } else {
            return allPhotos.count // horizontal
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ALKPhotoCollectionCell", for: indexPath) as! ALKPhotoCollectionCell

        let asset = allPhotos.object(at: indexPath.item)
        let thumbnailSize = CGSize(width: 200, height: 200)
        option.isSynchronous = true
        PHCachingImageManager.default().requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: option, resultHandler: { image, _ in
            cell.imgPreview.image = image
        })

        cell.imgPreview.backgroundColor = UIColor.white

        return cell
    }

    func numberOfSections(in _: UICollectionView) -> Int {
        return 1 // the vertical side
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

extension ALKCustomCameraViewController {
    func showImageExportFailureAlert() {
        let alertTitle = localizedString(
            forKey: "PhotoAlbumFailureTitle",
            withDefaultValue: SystemMessage.PhotoAlbum.FailureTitle,
            fileName: localizedStringFileName
        )
        let alertMessage = localizedString(
            forKey: "VideoExportError",
            withDefaultValue: SystemMessage.Warning.videoExportError,
            fileName: localizedStringFileName
        )
        let buttonTitle = localizedString(
            forKey: "OkMessage",
            withDefaultValue: SystemMessage.ButtonName.ok,
            fileName: localizedStringFileName
        )
        let alert = UIAlertController(
            title: alertTitle,
            message: alertMessage,
            preferredStyle: UIAlertController.Style.alert
        )
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default))
        present(alert, animated: true, completion: nil)
    }
}
