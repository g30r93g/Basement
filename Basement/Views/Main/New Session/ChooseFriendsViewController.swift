//
//  ChooseFriendsViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 21/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class ChooseFriendsViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var searchField: UITextField!
    @IBOutlet weak private var friendsTable: UITableView!
    
    // MARK: Properties
    var feedbackDelegate: SelectedFriendsFeedback?
    
    var selectedFriends: [Firebase.UserProfile] = []
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.isModalInPresentation = true
    }
    
    // MARK: Methods
    
    // MARK: IBActions
    @IBAction private func doneTapped(_ sender: UIButton) {
        self.feedbackDelegate?.friendsSelected(self.selectedFriends)
        self.dismiss(animated: true, completion: nil)
    }
    
}
