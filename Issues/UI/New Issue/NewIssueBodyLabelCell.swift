//
//  NewIssueBodyLabelCell.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit

class NewIssueBodyLabelCell : NewIssueCell {
    @IBOutlet var label: UILabel?
    override func awakeFromNib() {
        guard let label = label else {
            preconditionFailure()
        }
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UILayoutPriority.defaultHigh.rawValue + 1), for: .horizontal)
    }
}
