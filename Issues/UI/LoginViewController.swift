//
//  LoginViewController.swift
//  Reports
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit
import SeeClickFix

class LoginViewController : UIViewController {
    @IBOutlet private var userName: UITextField?
    @IBOutlet private var password: UITextField?
    @IBOutlet private var login: UIButton?
    @IBOutlet private var showPasswordLabel: UILabel?
    @IBOutlet private var showPasswordSwitch: UISwitch?
    override func viewDidLoad() {
        super.viewDidLoad()
        userName?.placeholder = NSLocalizedString("LoginViewController.Email", comment: "")
        password?.placeholder = NSLocalizedString("LoginViewController.Password", comment: "")
        login?.setTitle(NSLocalizedString("LoginViewController.Login", comment: ""), for: .normal)
        showPasswordLabel?.text = NSLocalizedString("LoginViewController.ShowPassword", comment: "")
    }
    @IBAction private func login(sender: Any) {
        guard let userName = userName?.text,
              let password = password?.text else {
            return
        }
        // TODO: better input validation preflight nonsense
        // Min count for passwords, etc
        guard userName.count > 0, password.count > 0 else {
            return
        }
        let dimmer = storyboard?.instantiateViewController(withIdentifier: "Dimmer")
        if let dimmer = dimmer {
            present(dimmer, animated: true, completion: nil)
        }
        let network = NetworkController.shared
        network.login(user: userName, password: password).then(on: DispatchQueue.main, { [weak self] data in
            dimmer?.dismiss(animated: true) {
                self?.dismiss(animated: true, completion: nil)
            }
        }).`catch`() { error in
            dimmer?.dismiss(animated: true, completion: nil)
        }
    }
    @IBAction private func showPassword(sender: Any) {
        guard let password = password,
              let showPasswordSwitch = showPasswordSwitch else {
            return
        }
        password.isSecureTextEntry = !showPasswordSwitch.isOn
    }
    @IBAction private func cancel(sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
