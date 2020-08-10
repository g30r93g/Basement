//
//  ProfileEditorViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 18/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class ProfileEditorViewController: UIViewController {
    
    // MARK: IBOutlets
    
    // MARK: Properties

    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // MARK: Methods
    
    // MARK: IBActions
    @IBAction private func signOut() {
        Firebase.shared.signOut() { (success) in
            if success {
                self.performSegue(withIdentifier: "Sign Out", sender: self)
            }
        }
    }

}
