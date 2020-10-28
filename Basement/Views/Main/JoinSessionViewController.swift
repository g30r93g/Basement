//
//  JoinSessionViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 26/10/2020.
//

import UIKit

class JoinSessionViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var joinCodeField: UITextField!
    @IBOutlet weak private var joinButton: LoadingButton!
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.joinCodeField.becomeFirstResponder()
    }
    
    // MARK: Methods
    private func joinSession() {
        guard let joinCode = self.joinCodeField.text,
              joinCode.count == 6 else { return }
        
        DispatchQueue.main.async { self.joinButton.startLoading() }
        
        SessionManager.current.joinSession(joinCode: joinCode) { (result) in
            switch result {
            case .success(let session):
                self.transitionToSession()
            case .failure(_):
                break
            }
            
            DispatchQueue.main.async { self.joinButton.stopLoading() }
        }
    }
    
    private func transitionToSession() {
        self.performSegue(withIdentifier: "Join Session", sender: self)
    }
    
    // MARK: IBActions
    @IBAction private func joinButtonTapped(_ sender: LoadingButton) {
        self.joinSession()
    }
    
}
