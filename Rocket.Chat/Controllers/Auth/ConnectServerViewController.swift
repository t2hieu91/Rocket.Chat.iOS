//
//  ConnectServerViewController.swift
//  Rocket.Chat
//
//  Created by Rafael K. Streit on 7/6/16.
//  Copyright © 2016 Rocket.Chat. All rights reserved.
//

import Foundation
import UIKit

class ConnectServerViewController: BaseViewController {

    internal let defaultURL = "https://demo.rocket.chat"
    internal var connecting = false
    internal var serverURL: URL!
    
    @IBOutlet weak var visibleViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textFieldServerURL: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nav = navigationController as! BaseNavigationController
        nav.setTransparentTheme()
        nav.navigationBar.barStyle = .black

        textFieldServerURL.placeholder = defaultURL
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: NSNotification.Name.UIKeyboardWillShow,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: NSNotification.Name.UIKeyboardWillHide,
            object: nil
        )
        
        textFieldServerURL.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Auth" {
            let controller = segue.destination as! AuthViewController
            controller.serverURL = serverURL
        }
    }
    
    
    // MARK: Keyboard Handlers
    
    func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = ((notification as NSNotification).userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            visibleViewBottomConstraint.constant = keyboardSize.height
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        visibleViewBottomConstraint.constant = 0
    }
    
    
    // MARK: IBAction
    
    func alertInvalidURL() {
        let alert = UIAlertController(
            title: localizedString("alert.connection.invalid_url.title"),
            message: localizedString("alert.connection.invalid_url.message"),
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: localizedString("global.ok"), style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func connect() {
        var text = textFieldServerURL.text!
        if text.characters.count == 0 {
            text = defaultURL
        }
        
        guard let url = URL(string: text) else { return alertInvalidURL() }
        guard let socketURL = url.socketURL() else { return alertInvalidURL() }
        
        connecting = true
        textFieldServerURL.alpha = 0.5
        activityIndicator.startAnimating()
        
        serverURL = socketURL
        
        SocketManager.connect(socketURL) { [unowned self] (socket, connected) in
            if connected {
                self.performSegue(withIdentifier: "Auth", sender: nil)
            }
        
            self.connecting = false
            self.textFieldServerURL.alpha = 1
            self.activityIndicator.stopAnimating()
        }
    }
    
}


extension ConnectServerViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return !connecting
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        connect()
        return true
    }
    
}
