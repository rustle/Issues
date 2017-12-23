//
//  ActivityDimmerViewController.swift
//  Reports
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit

class ActivityDimmerViewController : UIViewController {
    @IBOutlet private var activityView: UIActivityIndicatorView?
    func start() {
        activityView?.startAnimating()
    }
    func stop() {
        activityView?.stopAnimating()
    }
    override var modalTransitionStyle: UIModalTransitionStyle {
        get {
            return .crossDissolve
        }
        set {
            
        }
    }
}
