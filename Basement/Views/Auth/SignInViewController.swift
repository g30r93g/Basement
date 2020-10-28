//
//  SignInViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 26/10/2020.
//

import UIKit

class SignInViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var emailField: UITextField!
    @IBOutlet weak private var passwordField: UITextField!
    @IBOutlet weak private var forgotPasswordButton: UIButton!
    @IBOutlet weak private var signInButton: LoadingButton!
    @IBOutlet weak private var signUpButton: RoundButton!

    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // MARK: Methods
    private func signIn() {
        guard let email = self.emailField.text,
              let password = self.passwordField.text
        else { return }
        
        DispatchQueue.main.async { self.signInButton.startLoading() }
        
        Firebase.auth.signIn(email: email, password: password) { (result) in
            switch result {
            case .success(let userDetails):
                if userDetails.connectedService == nil {
                    self.userRequiresStreamingPlatform()
                } else {
                    self.signInSuccessful()
                }
            case .failure(_):
                DispatchQueue.main.async { self.signInButton.stopLoading() }
            }
        }
    }
    
    private func resetPassword() { }
    
    private func signInSuccessful() {
        self.performSegue(withIdentifier: "Sign In Successful", sender: self)
    }
    
    private func userRequiresStreamingPlatform() {
        self.performSegue(withIdentifier: "Streaming Platform Required", sender: self)
    }
    
    // MARK: IBActions
    @IBAction private func forgotPasswordTapped(_ sender: UIButton) {
        self.resetPassword()
    }
    
    @IBAction private func signInTapped(_ sender: RoundButton) {
        self.signIn()
    }
    
}
