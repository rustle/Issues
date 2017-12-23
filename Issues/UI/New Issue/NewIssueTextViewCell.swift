//
//  NewIssueTextViewCell.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit

class NewIssueTextViewCell : NewIssueCell {
    @IBOutlet var label: UILabel?
    @IBOutlet var textView: UITextView?
    override func awakeFromNib() {
        super.awakeFromNib()
        if let layer = textView?.layer {
            layer.cornerRadius = 8.0
            layer.borderColor = #colorLiteral(red: 0.8312992454, green: 0.8314195275, blue: 0.8312730193, alpha: 1)
            layer.borderWidth = 1.0
        }
    }
    @IBAction func done(sender: Any?) {
        textView?.resignFirstResponder()
    }
}

extension NewIssueTextViewCell : UITextViewDelegate {
    
}
