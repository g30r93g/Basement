//
//  AddFriendsViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 16/05/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import UIKit

class AddFriendsViewController: UIViewController {
	
	// MARK: IBOutlets
    @IBOutlet weak private var usernameSearchField: UITextField!
	@IBOutlet weak private var friendsTable: UITableView!
	@IBOutlet weak private var startVibingButton: UIButton!
	
	// MARK: Properties
    private var matchingFriends: [Firebase.UserProfile] = []
	
	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
        
        self.addTextFieldEvents()
	}
    
    override func viewDidDisappear(_ animated: Bool) {
        self.removeTextFieldEvents()
    }
	
	// MARK: Methods
    /// Adds an event listener for when text is edited
    private func addTextFieldEvents() {
        self.usernameSearchField.addTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
        self.usernameSearchField.addTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
    }
    
    /// Removes event listeners for when text is edited
    private func removeTextFieldEvents() {
        self.usernameSearchField.removeTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
        self.usernameSearchField.removeTarget(self, action: #selector(textFieldDidEdit), for: .editingChanged)
    }
    
	private func finishSignUp() {
		self.performSegue(withIdentifier: "Finish Sign Up", sender: nil)
	}

	// MARK: IBActions
	@IBAction private func startVibingTapped(_ sender: UIButton) {
		self.finishSignUp()
	}
	
}

extension AddFriendsViewController: UITableViewDelegate, UITableViewDataSource {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.matchingFriends.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Friend", for: indexPath) as! FriendCell
        let data = self.matchingFriends[indexPath.row]
        
		cell.setupCell(from: data)
		
		return cell
	}
	
}

extension AddFriendsViewController: UITextFieldDelegate {
    
    @objc private func textFieldDidEdit(_ textField: UITextField) {
        guard let usernameSearchValue = textField.text else { return }
        
        Firebase.shared.searchUsers(by: usernameSearchValue) { (result) in [self]
            switch result {
            case .success(let profiles):
                guard usernameSearchValue == self.usernameSearchField.text else { return }
                self.matchingFriends = profiles
                
                DispatchQueue.main.async {
                    self.friendsTable.reloadData()
                }
            case .failure(_):
                return
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.usernameSearchField {
            self.usernameSearchField.resignFirstResponder()
        }
        
        return true
    }
    
}
