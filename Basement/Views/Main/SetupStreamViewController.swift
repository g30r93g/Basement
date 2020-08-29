//
//  SetupStreamViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 22/08/2020.
//

import UIKit

class SetupStreamViewController: UIViewController {

    // MARK: IBOutlets
    @IBOutlet weak private var streamNameTextField: UITextField!
    @IBOutlet weak private var hostUsernameTextField: UITextField!
    @IBOutlet weak private var maxStreamerCountLabel: UILabel!
    @IBOutlet weak private var maxStreamerStepper: UIStepper!
    @IBOutlet weak private var startBasementSessionButton: RoundButton!
    
    // MARK: Properties
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    // MARK: Methods
    private func setupView() {
        self.maxStreamerStepperValueChanged(self.maxStreamerStepper)
    }
    
    private func showSessionCreationError() {
        let alert = UIAlertController(title: "Failed to create basement.", message: "Please try again.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func startBasementSession(completion: @escaping(Bool) -> Void) {
        guard let basementName = self.streamNameTextField.text,
            let hostUsername = self.hostUsernameTextField.text
        else { return }
        let maximumListeners = Int(self.maxStreamerStepper.value)
        
        SessionManager.current.createBasementSession(name: basementName, hostUsername: hostUsername, maxListeners: maximumListeners) { (result) in
            switch result {
            case .success(let basementSession):
                completion(true)
            case .failure(let error):
                completion(false)
            }
        }
    }
    
    // MARK: IBActions
    @IBAction private func maxStreamerStepperValueChanged(_ sender: UIStepper) {
        self.maxStreamerCountLabel.text = "\(Int(sender.value))"
    }
    
    @IBAction private func startBasementSessionTapped(_ sender: LoadingButton) {
        sender.startLoading()
        
        self.startBasementSession { (didStart) in
            sender.stopLoading()
            
            if didStart {
                self.performSegue(withIdentifier: "Basement Session Created", sender: self)
            } else {
                self.showSessionCreationError()
            }
        }
    }

}
