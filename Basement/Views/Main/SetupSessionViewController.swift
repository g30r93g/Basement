//
//  SetupSessionViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 26/10/2020.
//

import UIKit

class SetupSessionViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var sessionNameField: UITextField!
    @IBOutlet weak private var sessionVisibilityControl: UISegmentedControl!
    @IBOutlet weak private var sessionVisibilityDescription: UILabel!
    @IBOutlet weak private var nextButton: RoundButton!
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.updateSessionVisibilityDescription()
    }
    
    // MARK: Methods
    private func updateSessionVisibilityDescription() {
        switch self.sessionVisibilityControl.selectedSegmentIndex {
        case 0:
            self.sessionVisibilityDescription.text = "Anyone who sees your session can join."
        case 1:
            self.sessionVisibilityDescription.text = "Only users with the session code can join your session."
        default:
            break
        }
    }
    
    private func transitionToTrackSelector() {
        self.performSegue(withIdentifier: "Transition to Track Selector", sender: self)
    }
    
    // MARK: Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Transition to Track Selector" {
            guard let destination = segue.destination as? TrackListViewController else { fatalError() }
            let sessionName = self.sessionNameField.text
            let sessionVisibility = self.sessionVisibilityControl.selectedSegmentIndex
            
            destination.sessionName = sessionName
            destination.sessionVisibility = sessionVisibility == 0 ? .public : .byInvite
        }
    }
    
    // MARK: IBActions
    @IBAction private func sessionVisibilityControlValueChanged(_ sender: UISegmentedControl) {
        self.updateSessionVisibilityDescription()
    }
    
    @IBAction private func nextTapped(_ sender: RoundButton) {
        self.transitionToTrackSelector()
    }
    
}
