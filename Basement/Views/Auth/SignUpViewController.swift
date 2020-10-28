//
//  SignUpViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 26/10/2020.
//

import UIKit

class SignUpViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var usernameField: UITextField!
    @IBOutlet weak private var emailField: UITextField!
    @IBOutlet weak private var passwordField: UITextField!
    @IBOutlet weak private var privacyPolicyButton: UIButton!
    @IBOutlet weak private var termsAndConditionsButton: UIButton!
    @IBOutlet weak private var signUpButton: LoadingButton!
    
    // MARK: View Controller Life Cycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.usernameField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.usernameField.resignFirstResponder()
        self.emailField.resignFirstResponder()
        self.passwordField.resignFirstResponder()
    }
    
    // MARK: Methods
    private func signUp() {
        guard let username = self.usernameField.text,
              let email = self.emailField.text,
              let password = self.passwordField.text
        else { return }
        
        DispatchQueue.main.async { self.signUpButton.startLoading() }
        
        Firebase.auth.signUp(email: email, password: password, userDetails: BasementProfile.UserDetails(username: username, connectedService: nil)) { (result) in
            DispatchQueue.main.async { self.signUpButton.stopLoading() }
            
            switch result {
            case .success(_):
                self.connectStreamingPlatform()
            case .failure(_):
                return
            }
        }
    }
    
    private func connectStreamingPlatform() {
        self.performSegue(withIdentifier: "Sign Up Successful", sender: self)
    }
    
    // MARK: IBActions
    @IBAction private func privacyPolicyTapped(_ sender: UIButton) { }
    
    @IBAction private func termsAndConditionsTapped(_ sender: UIButton) { }
    
    @IBAction private func signUpTapped(_ sender: LoadingButton) {
        self.signUp()
    }

}
