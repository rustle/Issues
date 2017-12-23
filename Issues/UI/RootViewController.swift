//
//  RootViewController.swift
//  Reports
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit

class RootViewController : UIViewController {
    override func awakeFromNib() {
        super.awakeFromNib()
        _ = Coordinator.shared
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem?.accessibilityLabel = NSLocalizedString("RootViewController.NewIssue.Accessibility", comment: "")
    }
}
