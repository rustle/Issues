//
//  NewIssueLocationCell.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit
import MapKit

class NewIssueLocationCell : NewIssueCell {
    @IBOutlet var map: MKMapView?
    @IBOutlet var dot: UIView?
    @IBOutlet var label: UILabel?
    @IBOutlet var userLocationImageView: UIImageView?
    @IBOutlet var lockImageView: UIImageView?
    var mapCenterDidChange: ((NewIssueLocationCell, CLLocationCoordinate2D) -> Void)?
    override func awakeFromNib() {
        super.awakeFromNib()
        if let dot = dot {
            dot.layer.cornerRadius = dot.bounds.size.width / 2.0
            dot.layer.borderWidth = 1.0
            dot.layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        }
        userLocationImageView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(moveToUserLocation(sender:))))
        lockImageView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleLock(sender:))))
        configureMapDingi()
        NotificationCenter.default
            .addObserver(forName: .UIAccessibilityReduceTransparencyStatusDidChange, object: nil, queue: nil) { [weak self] note in
                self?.configureMapDingi()
        }
        NotificationCenter.default
            .addObserver(forName: .UIAccessibilityDarkerSystemColorsStatusDidChange, object: nil, queue: nil) { [weak self] note in
                self?.configureMapDingi()
        }
    }
    func configureMapDingi() {
        func configureMapDingus(layer: CALayer) {
            if UIAccessibilityIsReduceTransparencyEnabled() {
                layer.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5047624144)
                layer.borderWidth = 1.0
                layer.borderColor = UIView.appearance().tintColor.cgColor
                layer.cornerRadius = 2.0
            } else {
                layer.backgroundColor = nil
                layer.borderWidth = 0.0
                layer.borderColor = nil
                layer.cornerRadius = 0.0
            }
        }
        if let lockLayer = lockImageView?.layer {
            configureMapDingus(layer: lockLayer)
        }
        if let userLocationLayer = userLocationImageView?.layer {
            configureMapDingus(layer: userLocationLayer)
        }
    }
    var shouldZoomToCoordinate = true
    var gen = 1
    let geoCoder = CLGeocoder()
    func zoomToCoordinate(coordinate: CLLocationCoordinate2D, animated: Bool = true) {
        self.map?.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)), animated: animated)
    }
    override func prepareForReuse() {
        shouldZoomToCoordinate = true
        gen += 1
        geoCoder.cancelGeocode()
    }
    override func willDisplay() {
        super.willDisplay()
        if shouldZoomToCoordinate, let coordinate = map?.userLocation.location?.coordinate {
            zoomToCoordinate(coordinate: coordinate)
            shouldZoomToCoordinate = false
        }
    }
    var locked = false
    @IBAction func toggleLock(sender: Any?) {
        locked = !locked
        map?.isUserInteractionEnabled = !locked
        if locked {
            lockImageView?.image = #imageLiteral(resourceName: "Closed")
        } else {
            lockImageView?.image = #imageLiteral(resourceName: "Open")
        }
    }
    @IBAction func moveToUserLocation(sender: Any?) {
        guard !locked, let coordinate = map?.userLocation.location?.coordinate else {
            return
        }
        zoomToCoordinate(coordinate: coordinate)
    }
}

extension NewIssueLocationCell : MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        if shouldZoomToCoordinate, let coordinate = userLocation.location?.coordinate {
            zoomToCoordinate(coordinate: coordinate)
            shouldZoomToCoordinate = false
        }
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard let center = map?.centerCoordinate else {
            return
        }
        let location = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let currentGen = gen
        geoCoder.issues_reverseGeocode(location: location).then(on: DispatchQueue.main, { [weak self] placemarks in
            guard placemarks.count > 0, let postalAddress = placemarks[0].postalAddress, let gen = self?.gen, gen == currentGen else {
                return
            }
            self?.label?.text = "\(postalAddress.street), \(postalAddress.city), \(postalAddress.state)"
        }).`catch`(on: DispatchQueue.main) { [weak self] _ in
            guard let gen = self?.gen, gen == currentGen else {
                return
            }
            self?.label?.text = nil
        }
        if let mapCenterDidChange = mapCenterDidChange {
            mapCenterDidChange(self, center)
        }
    }
}
