//
//  NewIssuePickerCell.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit

class NewIssuePickerCell : NewIssueCell {
    @IBOutlet var label: UILabel?
    @IBOutlet var pickerView: UIPickerView?
    var values: [QuestionSelectValue]? {
        didSet {
            pickerView?.reloadAllComponents()
        }
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        values = []
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        if let layer = self.pickerView?.layer {
            layer.cornerRadius = 8.0
            layer.borderColor = #colorLiteral(red: 0.8312992454, green: 0.8314195275, blue: 0.8312730193, alpha: 1)
            layer.borderWidth = 1.0
        }
    }
}

extension NewIssuePickerCell : UIPickerViewDelegate {
    
}

extension NewIssuePickerCell : UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let values = values else {
            return 0
        }
        return values.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let values = values, values.count > row else {
            return nil
        }
        return values[row].name;
    }
}
