//
//  CreateAccountViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 16/05/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import UIKit

class CreateAccountViewController: UIViewController {
	
	// MARK: IBOutlets
	@IBOutlet weak private var nameField: UITextField!
    @IBOutlet weak private var usernameField: UITextField!
    @IBOutlet weak private var usernameAvailabilityStatus: UIImageView!
    @IBOutlet weak private var usernameAvailabilityLoadingIndicator: UIActivityIndicatorView!
	@IBOutlet weak private var emailField: UITextField!
	@IBOutlet weak private var passwordField: UITextField!
    @IBOutlet weak private var signUpButton: LoadingButton!

	// MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.nameField.becomeFirstResponder()
        self.addTextFieldEvents()
        self.usernameAvailabilityLoadingIndicator.stopAnimating()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.removeTextFieldEvents()
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
        Firebase.shared.createUser(name: name, email: email, username: username, password: password) { (result) in
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
    
    private func checkIfUsernameIsAvailable() {
        guard let username = self.usernameField.text else { return }
        
        self.setUsernameActivityVisibility(to: true)
        
        Firebase.shared.determineUsernameAvailability(username) { (result) in
            self.setUsernameActivityVisibility(to: false)
            
            switch result {
            case .success(let isAvailable):
                guard let currentUsernameEntered = self.usernameField.text,
                      username == currentUsernameEntered
                else { return }
                
                self.setUsernameAvailabilityState(to: isAvailable)
            case .failure(_):
                return
            }
        }
    }
    
    private func setUsernameActivityVisibility(to state: Bool) {
        DispatchQueue.main.async {
            state ? self.usernameAvailabilityLoadingIndicator.startAnimating() : self.usernameAvailabilityLoadingIndicator.stopAnimating()
            self.usernameAvailabilityStatus.tintColor = .clear
        }
    }
    
    private func setUsernameAvailabilityState(to state: Bool) {
        DispatchQueue.main.async {
            self.usernameAvailabilityStatus.alpha = 1
            self.usernameAvailabilityStatus.image = UIImage(systemName: state ? "checkmark.circle.fill" : "xmark.circle.fill")
            self.usernameAvailabilityStatus.tintColor = state ? .systemGreen : .systemRed
        }
    }
    
    private func addTextFieldEvents() {
        self.usernameField.addTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
    }
    
    private func removeTextFieldEvents() {
        self.usernameField.removeTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
    }
    
    @objc private func textFieldDidEdit(textField: UITextField) {
        self.checkIfUsernameIsAvailable()
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
