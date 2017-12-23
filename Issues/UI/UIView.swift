//
//  UIView.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit

extension UIView {
    func issues_fill(view: UIView) {
        let width = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1.0, constant: 0.0)
        let height = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1.0, constant: 0.0)
        let leading = NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0.0)
        let trailing = NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        view.addConstraints([width, height, leading, trailing])
    }
    func issues_logAutolayoutTraceIfAmbigous() {
        var views = [UIView]()
        views.append(self)
        while views.count > 0 {
            let view = views.remove(at: 0)
            if view.hasAmbiguousLayout {
                let sel = NSSelectorFromString("_autolayoutTrace")
                if view.responds(to: sel) {
                    print(view.perform(sel).takeUnretainedValue() as? String ?? "")
                }
                break
            }
            views.append(contentsOf: view.subviews)
        }
    }
}
