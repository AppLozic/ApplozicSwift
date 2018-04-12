//
//  ALKLocationCell.swift
//  
//
//  Created by Mukesh Thawani on 04/05/17.
//  Copyright © 2017 Applozic. All rights reserved.
//

import UIKit
import Kingfisher
import Applozic

protocol ALKLocationCellDelegate: class {
    func displayLocation(location:ALKLocationPreviewViewModel)
}

class ALKLocationCell: ALKChatBaseCell<ALKMessageViewModel>,
                        ALKReplyMenuItemProtocol {
    weak var delegate:ALKLocationCellDelegate?

    // MARK: - Declare Variables or Types
    // MARK: Environment in chat
    internal var timeLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    internal var bubbleView: UIImageView = {
        let bv = UIImageView()
        let image = UIImage.init(named: "chat_bubble_red", in: Bundle.applozic, compatibleWith: nil)
        bv.image = image?.imageFlippedForRightToLeftLayoutDirection()
        bv.tintColor =   UIColor(red: 92.0 / 255.0, green: 90.0 / 255.0, blue:167.0 / 255.0, alpha: 1.0)
        bv.isUserInteractionEnabled = false
        bv.isOpaque = true
        return bv
    }()

    private var frontView: ALKTappableView = {
        let view = ALKTappableView()
        view.alpha = 1.0
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }()

    private lazy var tapGesture: UITapGestureRecognizer = {
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(handleTap(withTapGesture:)))
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
        label.setFont(font: .normal(size: 14.0))
        label.setBackgroundColor(color: .none)
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
        bubbleView.bringSubview(toFront: frontView)

        frontView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 0.0).isActive = true
        frontView.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: 0.0).isActive = true
        frontView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 0.0).isActive = true
        frontView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: 0.0).isActive = true

        locationImageView.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8).isActive = true
        locationImageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8).isActive = true
        locationImageView.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -10).isActive = true
        locationImageView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * 0.60).isActive = true

        addressLabel.topAnchor.constraint(equalTo: locationImageView.bottomAnchor, constant: 4.0).isActive = true
        addressLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -4.0).isActive = true
        addressLabel.leftAnchor.constraint(equalTo: bubbleView.leftAnchor, constant: 8.0).isActive = true
        addressLabel.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: -8.0).isActive = true
        addressLabel.heightAnchor.constraint(equalToConstant: 18.0).isActive = true
    }

    override func setupStyle() {
        super.setupStyle()
    }

    override func update(viewModel: ALKMessageViewModel) {
        super.update(viewModel: viewModel)

        // timeLable
        var attributedString = NSMutableAttributedString()
        if(viewModel.isMyMessage){
            
            attributedString = NSMutableAttributedString(string: viewModel.time!, attributes: [
                .font: UIFont(name: "Roboto-Regular", size: 10.0)!,
                .foregroundColor: UIColor(red: 237.0 / 255.0, green: 230.0 / 255.0, blue: 230.0 / 255.0, alpha: 1.0),
                .kern: -0.1
                ])
        }else{
            attributedString = NSMutableAttributedString(string: viewModel.time!, attributes: [
                .font: UIFont(name: "Roboto-Regular", size: 10.0)!,
                .foregroundColor: UIColor(red: 138.0 / 255.0, green: 134.0 / 255.0, blue: 134.0 / 255.0, alpha: 1.0),
                .kern: -0.1
                ])
        }
        
        
        self.timeLabel.attributedText   = attributedString
        

        // addressLabel
        if let geocode = viewModel.geocode {
            addressLabel.text = geocode.formattedAddress
        }

        // locationImageView
        locationImageView.image = nil
        guard let lat = viewModel.geocode?.location.latitude,let lon = viewModel.geocode?.location.longitude else {
            return
        }
        let latLonArgument = String(format: "%f,%f", lat, lon)
        guard let apiKey = ALUserDefaultsHandler.getGoogleMapAPIKey() else { return }
        let urlString = "https://maps.googleapis.com/maps/api/staticmap?center=\(latLonArgument)&zoom=17&size=375x295&maptype=roadmap&format=png&visual_refresh=true&markers=\(latLonArgument)&key=\(apiKey)"
        locationImageView.kf.setImage(with: URL(string: urlString), placeholder: UIImage(named: "map_no_data", in: Bundle.applozic, compatibleWith: nil), options: nil, progressBlock: nil, completionHandler: nil)
    }

    override class func rowHeigh(viewModel: ALKMessageViewModel,width: CGFloat) -> CGFloat {
        let heigh: CGFloat
        
        if viewModel.ratio < 1 {
            heigh = viewModel.ratio == 0 ? (width*0.48) : ceil((width*0.48)/viewModel.ratio)
        } else {
            heigh = ceil((width*0.64)/viewModel.ratio)
        }
        
        return topPadding()+heigh+bottomPadding()
    }
    
    class func topPadding() -> CGFloat {
        return 12
    }
    
    class func bottomPadding() -> CGFloat {
        return 16
    }
    
    

    // MARK: - Method of class
    func setDelegate(locDelegate:ALKLocationCellDelegate) {
        delegate = locDelegate
    }

    @objc func handleTap(withTapGesture gesture: UITapGestureRecognizer) {
        if let geocode = viewModel?.geocode ,gesture.state == .ended {
            tempLocation = geocode
            openMap(withLocation: geocode, completion: nil)
        }
    }

    func openMap(withLocation geocode: Geocode, completion: ((_ isSuccess: Bool) -> Swift.Void)? = nil) {
        if let locDelegate = delegate , locationPreviewViewModel().isReady{
            locDelegate.displayLocation(location: locationPreviewViewModel())
        }
    }

    // MARK: - ALKPreviewLocationViewControllerDelegate
    func locationPreviewViewModel() -> ALKLocationPreviewViewModel {
        guard let loc = tempLocation else {
            let unspecifiedLocaltionMsg = NSLocalizedString("UnspecifiedLocation", value: SystemMessage.UIError.unspecifiedLocation, comment: "")
            return ALKLocationPreviewViewModel(addressText: unspecifiedLocaltionMsg)
        }
        return ALKLocationPreviewViewModel(geocode:loc)
    }

    func menuReply(_ sender: Any) {
        menuAction?(.reply)
    }

}

class ALKTappableView: UIView {

    // To highlight when long pressed
    override open var canBecomeFirstResponder: Bool {
        return true
    }
}
