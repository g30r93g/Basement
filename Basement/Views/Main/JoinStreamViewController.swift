//
//  JoinStreamViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 22/08/2020.
//

import UIKit
import KeyboardLayoutGuide

class JoinStreamViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var firstChar: UITextField!
    @IBOutlet weak private var secondChar: UITextField!
    @IBOutlet weak private var thirdChar: UITextField!
    @IBOutlet weak private var fourthChar: UITextField!
    @IBOutlet weak private var fifthChar: UITextField!
    @IBOutlet weak private var sixthChar: UITextField!
    @IBOutlet weak private var joinSessionButton: LoadingButton!
    @IBOutlet weak private var startNewSessionButton: RoundButton!
    
    // MARK: Properties
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    // MARK: Methods
    private func setupView() { }
    
    private func joinStream(completion: @escaping(Bool) -> Void) {
        guard let joinCode = self.enteredCode(),
            !joinCode.isEmpty
            else { completion(false); return }
        
        SessionManager.current.joinBasementSession(joinCode: joinCode) { (_) in
            completion(true)
        }
    }
    
    private func enteredCode() -> String? {
        guard let char1 = self.firstChar.text,
            let char2 = self.secondChar.text,
            let char3 = self.thirdChar.text,
            let char4 = self.fourthChar.text,
            let char5 = self.fifthChar.text,
            let char6 = self.sixthChar.text
            else { return nil }
        
        return char1 + char2 + char3 + char4 + char5 + char6
    }
    
    private func showJoinError() {
        let alert = UIAlertController(title: "Failed to join room.", message: "Please try again later.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: IBActions
    @IBAction private func joinSessionTapped(_ sender: LoadingButton) {
        sender.startLoading()
        
        self.joinStream { (didJoin) in
            sender.stopLoading()
            
            if didJoin {
                self.performSegue(withIdentifier: "Basement Session Joined", sender: self)
            } else {
                self.showJoinError()
            }
        }
    }
    
}

extension JoinStreamViewController: UITextFieldDelegate { }
