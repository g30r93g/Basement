//
//  ProfileViewController.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var navigationBar: UIView!
    @IBOutlet weak private var navigationTitle: UILabel!
    
    @IBOutlet weak private var editProfileButton: UIButton!
    @IBOutlet weak private var friendsButton: UIButton!
    @IBOutlet weak private var profileImage: UIImageView!
    @IBOutlet weak private var profileNameLabel: UILabel!
    @IBOutlet weak private var profileUsernameLabel: UILabel!
    @IBOutlet weak private var contentTableView: UITableView!
    
    // MARK: Properties
    var user: Firebase.UserProfile?
    
    // MARK: View Controller Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setupView()
    }
    
    // MARK: Methods
    private func setupView() {
        if self.navigationController?.viewControllers.first == self {
            // This means that we're viewing our own profile
            self.navigationBar.alpha = 0
            self.navigationBar.isUserInteractionEnabled = false
            
            self.editProfileButton.alpha = 1
            self.editProfileButton.isUserInteractionEnabled = true
            
            self.friendsButton.alpha = 1
            self.friendsButton.isUserInteractionEnabled = true
            
            Firebase.shared.getCurrentUserProfile() { (currentUser) in
                if let currentUser = currentUser {
                    DispatchQueue.main.async {
                        self.profileNameLabel.text = currentUser.profile.name
                        self.profileUsernameLabel.text = "@\(currentUser.profile.username)"
                    }
                }
            }
        } else {
            self.navigationBar.alpha = 1
            self.navigationBar.isUserInteractionEnabled = true
            
            self.editProfileButton.alpha = 0
            self.editProfileButton.isUserInteractionEnabled = false
            
            self.friendsButton.alpha = 0
            self.friendsButton.isUserInteractionEnabled = false
            
            if let user = self.user {
                self.profileNameLabel.text = user.name
                self.profileUsernameLabel.text = "@\(user.username)"
            }
//            Firebase.shared.findUser(matching: user.username) { (user) in
//                self.user = user
//            }
        }
        
        // Add extra scroll
        self.contentTableView.contentInset.bottom = self.view.safeAreaInsets.bottom + 80
        
    }
    
    // MARK: IBActions
    @IBAction private func dismissTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    /* THREE SECTIONS
            SECTION 1 - Showcase
            SECTION 2 - Recent Activity
            SECTION 3 - Friends (Icons Only)
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Music Carousel Cell", for: indexPath) as! MusicCarouselCell
        
        switch indexPath.row {
        case 0:
//            cell.setupCellWithShowcase(from: [], withHeader: "Your Music Showcase")
            cell.setupCellWithRecents(from: [], withHeader: "Your Music Showcase")
        case 1:
            cell.setupCellWithRecents(from: [], withHeader: "Your Recent Vibes")
        case 2:
            cell.setupCellWithFriends(from: [], withHeader: "Your Friend Activity")
        default:
            break
        }
        
        return cell
    }
    
}
