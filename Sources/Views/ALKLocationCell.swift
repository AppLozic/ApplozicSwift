//
//  ALKLocationCell.swift
//
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import ApplozicCore
import Kingfisher
import UIKit

protocol ALKLocationCellDelegate: AnyObject {
    func displayLocation(location: ALKLocationPreviewViewModel)
}

class ALKLocationCell: ALKChatBaseCell<ALKMessageViewModel>,
    ALKReplyMenuItemProtocol, ALKReportMessageMenuItemProtocol
{
    weak var delegate: ALKLocationCellDelegate?

    // MARK: - Declare Variables or Types

    // MARK: Environment in chat

    internal var timeLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    internal var bubbleView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        return view
    }()

    private var frontView: ALKTappableView = {
        let view = ALKTappableView()
        view.alpha = 1.0
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()

    private lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(withTapGesture:)))
        tapGesture.numberOfTapsRequired = 1
        return tapGesture
    }()

    private var topViewController: UIViewController? {
        guard var topViewController = UIApplication.shared.keyWindow?.rootViewController else { return nil }

        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        return topViewController
    }

    // MARK: Content in chat

    private var tempLocation: Geocode?

    private var locationImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private var addressLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.setFont(UIFont.font(.normal(size: 14.0)))
        label.setBackgroundColor(.color(Color.Background.none))
        return label
    }()

    // MARK: - Lifecycle

    override func setupViews() {
        super.setupViews()

        // setup view with gesture
        frontView.addGestureRecognizer(tapGesture)
        frontView.addGestureRecognizer(longPressGesture)

        // add view to contenview and setup constraint
        contentView.addViewsForAutolayout(views: [bubbleView, timeLabel])

        bubbleView.addViewsForAutolayout(views: [frontView, locationImageView, addressLabel])
        bubbleView.bringSubviewToFront(frontView)

        frontView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 0.0).isActive = true
        frontView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 0.0).isActive = true
        frontView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 0.0).isActive = true
        frontView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: 0.0).isActive = true

        locationImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 0.0).isActive = true
        locationImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 0.0).isActive = true
        locationImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: 0.0).isActive = true
        locationImageView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.64).isActive = true

        addressLabel.topAnchor.constraint(equalTo: locationImageView.bottomAnchor, constant: 4.0).isActive = true
        addressLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -4.0).isActive = true
        addressLabel.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8.0).isActive = true
        addressLabel.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -8.0).isActive = true
        addressLabel.heightAnchor.constraint(equalToConstant: 18.0).isActive = true
    }

    override func setupStyle() {
        super.setupStyle()
        timeLabel.setStyle(ALKMessageStyle.time)
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)

        // timeLable
        timeLabel.text = viewModel.time

        // addressLabel
        if let geocode = viewModel.geocode {
            addressLabel.text = geocode.formattedAddress
        }

        // locationImageView
        locationImageView.image = nil
        guard let lat = viewModel.geocode?.location.latitude, let lon = viewModel.geocode?.location.longitude else {
            return
        }
        let latLonArgument = String(format: "%f,%f", lat, lon)
        guard let apiKey = ALUserDefaultsHandler.getGoogleMapAPIKey() else { return }

        // swiftlint:disable:next line_length
        let urlString = "https://maps.googleapis.com/maps/api/staticmap?center=\(latLonArgument)&zoom=17&size=375x295&maptype=roadmap&format=png&visual_refresh=true&markers=\(latLonArgument)&key=\(apiKey)"
        locationImageView.kf.setImage(
            with: URL(string: urlString),
            placeholder: UIImage(
                named: "map_no_data",
                in: Bundle.applozic,
                compatibleWith: nil
            )
        )
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel, width: CGFloat) -> CGFloat {
        let heigh: CGFloat = ceil((width * 0.64) / viewModel.ratio)
        return heigh + 26.0
    }

    // MARK: - Method of class

    func setDelegate(locDelegate: ALKLocationCellDelegate) {
        delegate = locDelegate
    }

    @objc func handleTap(withTapGesture gesture: UITapGestureRecognizer) {
        if let geocode = viewModel?.geocode, gesture.state == .ended {
            tempLocation = geocode
            openMap(withLocation: geocode, completion: nil)
        }
    }

    func openMap(withLocation _: Geocode, completion _: ((_ isSuccess: Bool) -> Swift.Void)? = nil) {
        if let locDelegate = delegate, locationPreviewViewModel().isReady {
            locDelegate.displayLocation(location: locationPreviewViewModel())
        }
    }

    // MARK: - ALKPreviewLocationViewControllerDelegate

    func locationPreviewViewModel() -> ALKLocationPreviewViewModel {
        guard let loc = tempLocation else {
            let unspecifiedLocaltionMsg = localizedString(forKey: "UnspecifiedLocation", withDefaultValue: SystemMessage.UIError.unspecifiedLocation, fileName: localizedStringFileName)
            return ALKLocationPreviewViewModel(addressText: unspecifiedLocaltionMsg, localizedStringFileName: localizedStringFileName)
        }
        return ALKLocationPreviewViewModel(geocode: loc, localizedStringFileName: localizedStringFileName)
    }

    func menuReply(_: Any) {
        menuAction?(.reply)
    }

    func menuReport(_: Any) {
        menuAction?(.report)
    }
}

class ALKTappableView: UIView {
    // To highlight when long pressed
    override open var canBecomeFirstResponder: Bool {
        return true
    }
}
