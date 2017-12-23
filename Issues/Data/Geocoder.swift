//
//  Geocoder.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import CoreLocation
import SeeClickFix

extension CLGeocoder {
    func issues_reverseGeocode(location: CLLocation) -> Promise<[CLPlacemark]> {
        let promise = Promise<[CLPlacemark]>()
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                promise.reject(error)
            } else if let placemarks = placemarks {
                promise.fulfill(placemarks)
            } else {
                preconditionFailure()
            }
        }
        return promise
    }
}
