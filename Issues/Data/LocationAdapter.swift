//
//  LocationAdapter.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import CoreLocation

struct Clients : OptionSet {
    let rawValue: Int
    static let issuesList = Clients(rawValue: 1)
    static let newIssueType = Clients(rawValue: 2)
    static let newIssueReport = Clients(rawValue: 4)
}

struct LocationAdapter {
    private class Delegate : NSObject, CLLocationManagerDelegate {
        var didUpdateLocations: ((CLLocationManager, [CLLocation]) -> Void)?
        public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let didUpdateLocations = didUpdateLocations else {
                return
            }
            didUpdateLocations(manager, locations)
        }
    }
    lazy private var delegate = Delegate()
    lazy private var locationManager: CLLocationManager? = {
        func makeLocationManager() -> CLLocationManager {
            let locationManager = CLLocationManager()
            locationManager.distanceFilter = 10.0
            locationManager.desiredAccuracy = 500.0
            locationManager.delegate = self.delegate
            return locationManager
        }
        switch CLLocationManager.authorizationStatus() {
        case .denied:
            break
        case .notDetermined:
            let locationManager = makeLocationManager()
            locationManager.requestWhenInUseAuthorization()
            return locationManager
        case .restricted:
            break
        case .authorizedAlways:
            // TODO: This shouldn't happen, but isn't an issue per se
            return makeLocationManager()
        case .authorizedWhenInUse:
            return makeLocationManager()
        }
        return nil
    }()
    var clients: Clients = [] {
        didSet {
            // Most to least granular
            if clients.contains(.newIssueReport) {
                locationManager?.desiredAccuracy = 10.0
            } else if clients.contains(.issuesList) || clients.contains(.newIssueType) {
                locationManager?.desiredAccuracy = 500.0
            }
        }
    }
    var didUpdateLocations: ((CLLocationManager, [CLLocation]) -> Void)? {
        mutating get {
            return delegate.didUpdateLocations
        }
        set {
            delegate.didUpdateLocations = newValue
        }
    }
    mutating func start() {
        locationManager?.startUpdatingLocation()
    }
}
