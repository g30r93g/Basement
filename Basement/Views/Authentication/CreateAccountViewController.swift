//
//  CreateAccountViewController.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 16/05/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import UIKit

class CreateAccountViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var nameField: UITextField!
    @IBOutlet weak private var usernameField: UITextField!
	@IBOutlet weak private var emailField: UITextField!
	@IBOutlet weak private var passwordField: UITextField!
    @IBOutlet weak private var signUpButton: LoadingButton!

	// MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.nameField.becomeFirstResponder()
    }
	
	// MARK: Methods
	private func signUp() {
        // Prevent View Controller Dismissal
        self.isModalInPresentation = true
        
		// Get name, username, email, passwd
		guard let name = self.nameField.text else { fatalError() }
        guard let username = self.usernameField.text else { fatalError() }
		guard let email	= self.emailField.text else { fatalError() }
		guard let password = self.passwordField.text else { fatalError() }
		
		// Pass to firebase auth to create email & passwd account
		// Upon completion, create firestore entry of account with name, username and email
		Firebase.shared.createUser(name: name, username: username, email: email, password: password) { (result) in
            self.signUpButton.stopLoading()
            
			switch result {
			case .success(_):
				self.performSegue(withIdentifier: "Link Music Services", sender: self)
			case .failure(let error):
                print("[CreateAccountVC] Failed to create user :( - \(error.localizedDescription)")
                self.isModalInPresentation = false
			}
		}
	}
	
	// MARK: IBActions
	@IBAction private func signUpTapped(_ sender: LoadingButton) {
        self.signUpButton.startLoading()
        
		self.signUp()
	}

}

extension CreateAccountViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.nameField {
            self.usernameField.becomeFirstResponder()
        } else if textField == self.usernameField {
            self.emailField.becomeFirstResponder()
        } else if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField {
            self.passwordField.resignFirstResponder()
            self.signUp()
            self.signUpButton.startLoading()
        } else {
            return false
        }
        
        return true
    }
    
}
