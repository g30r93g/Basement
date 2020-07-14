//
//  SignInViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 16/05/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var emailField: UITextField!
	@IBOutlet weak private var passwordField: UITextField!
    @IBOutlet weak private var forgotPasswordButton: UIButton!
	@IBOutlet weak private var signInButton: LoadingButton!
	@IBOutlet weak private var signUpButton: UIButton!

	// MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
	
	// MARK: Methods
	private func signIn() {
		// Get email & passwd
		guard let email = self.emailField.text else { return }
		guard let password = self.passwordField.text else { return }
		
		// Pass email and passwd to firebase auth
        Firebase.shared.signIn(email: email, password: password) { (result) in
            switch result {
            case .success(_):
                print("[SignInVC] User Signed In Successfully)")
                self.performSegue(withIdentifier: "Sign In Successful", sender: self)
            case .failure(let error):
                print("[SignInVC] Error signing in: \(error.localizedDescription)")
                break
            }
            
            self.signInButton.stopLoading()
        }
	}
	
	// MARK: IBActions
	@IBAction private func signInTapped(_ sender: UIButton) {
        self.signInButton.startLoading()
        
		self.signIn()
	}

}

extension SignInViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField {
            self.passwordField.resignFirstResponder()
            self.signIn()
        } else {
            return false
        }
        
        return true
    }
    
}
