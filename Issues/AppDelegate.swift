//
//  AppDelegate.swift
//  Reports
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    override init() {
        super.init()
        configureTint()
        NotificationCenter.default
            .addObserver(forName: .UIAccessibilityDarkerSystemColorsStatusDidChange, object: nil, queue: nil) { [weak self] note in
                self?.configureTint()
        }
    }
    func configureTint() {
        if UIAccessibilityDarkerSystemColorsEnabled() {
            UIView.appearance().tintColor = #colorLiteral(red: 0.77734375, green: 0.3650768746, blue: 0, alpha: 1)
        } else {
            UIView.appearance().tintColor = #colorLiteral(red: 1, green: 0.4696466327, blue: 0, alpha: 1)
        }
    }
}
