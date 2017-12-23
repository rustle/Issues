//
//  NewIssueTextFieldCell.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit

class NewIssueTextFieldCell : NewIssueCell {
    @IBOutlet var label: UILabel?
    @IBOutlet var textField: UITextField?
    var textFieldValueDidChange: ((UITextField?) -> Void)?
    func configure(text: String?, required: Bool) {
        guard let text = text else {
            return
        }
        if !required {
            label?.text = text
            return
        }
        let required = NSLocalizedString("NewIssueDetailViewController.Required", comment: "")
        let formattedText = NSString(format: NSLocalizedString("NewIssueDetailViewController.Required.Formatter", comment: "") as NSString, text, required)
        let attributedText = NSMutableAttributedString(string: formattedText as String)
        let range = formattedText.range(of: required)
        if range.location != NSNotFound {
            attributedText.setAttributes([NSAttributedStringKey.foregroundColor : UIColor.red], range: range)
        }
        label?.attributedText = attributedText
    }
    override func prepareForReuse() {
        label?.text = nil
        textField?.text = nil
    }
}

extension NewIssueTextFieldCell : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let didChange = textFieldValueDidChange {
            CFRunLoop.main.perform()  {
                didChange(textField)
            }
        }
        return true
    }
}
