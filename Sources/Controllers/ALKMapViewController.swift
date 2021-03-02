//
//  ALKMapViewController.swift
//  ApplozicSwift
//
//  Created by Mukesh Thawani on 10/10/17.
//

import ApplozicCore
import Kingfisher
import MapKit
import UIKit

protocol ALKShareLocationViewControllerDelegate: AnyObject {
    func locationDidSelected(geocode: Geocode, image: UIImage)
}

class ALKMapViewController: UIViewController, Localizable {
    var configuration: ALKConfiguration!

    @IBOutlet var mapView: MKMapView!

    @IBOutlet var shareLocationButton: UIButton!

    var locationManager = CLLocationManager()
    var region = MKCoordinateRegion()
    var isInitialized = false
    weak var delegate: ALKShareLocationViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_: Bool) {
        title = localizedString(forKey: "ShareLocationTitle", withDefaultValue: SystemMessage.Map.ShareLocationTitle, fileName: configuration.localizedStringFileName)
        let locationButtonTitle = localizedString(forKey: "SendLocationButton", withDefaultValue: SystemMessage.Map.SendLocationButton, fileName: configuration.localizedStringFileName)
        shareLocationButton.setTitle(locationButtonTitle, for: UIControl.State.normal)
        shareLocationButton.setTitle(locationButtonTitle, for: UIControl.State.selected)
    }

    override func viewDidAppear(_: Bool) {
        determineCurrentLocation()
    }

    func determineCurrentLocation() {
//        mapView.delegate = self
        mapView.showsUserLocation = true
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestLocation()
            locationManager.startUpdatingLocation()
        }
    }

    @IBAction func closeButtonAction(_: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    @IBAction func sendLocationAction(_: UIButton) {
        region = mapView.region
        let location = CLLocationCoordinate2D(latitude: region.center.latitude, longitude: region.center.longitude)
        let geoCode = Geocode(coordinates: location)
        delegate?.locationDidSelected(geocode: geoCode, image: UIImage())
        dismiss(animated: true, completion: nil)
    }

    public func setConfiguration(_ configuration: ALKConfiguration) {
        self.configuration = configuration
    }
}

extension ALKMapViewController: CLLocationManagerDelegate {
    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isInitialized else { return }
        isInitialized = true
        let userLoction: CLLocation = locations[0]
        let latitude = userLoction.coordinate.latitude
        let longitude = userLoction.coordinate.longitude
        let latDelta: CLLocationDegrees = 0.05
        let lonDelta: CLLocationDegrees = 0.05
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let location: CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        mapView.showsUserLocation = true
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        print("Error \(error)")
    }
}
