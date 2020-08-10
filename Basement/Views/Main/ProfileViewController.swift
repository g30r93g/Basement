//
//  ProfileViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 23/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var navigationBar: UIView!
    @IBOutlet weak private var navigationTitle: UILabel!
    
    @IBOutlet weak private var profileImage: UIImageView!
    @IBOutlet weak private var profileNameLabel: UILabel!
    @IBOutlet weak private var profileUsernameLabel: UILabel!
    @IBOutlet weak private var streamCountLabel: UILabel!
    @IBOutlet weak private var followerCountLabel: UILabel!
    @IBOutlet weak private var followingCountLabel: UILabel!
    @IBOutlet weak private var friendshipButton: LoadingButton!
    
    @IBOutlet weak private var contentTableView: UITableView!
    
    // MARK: Properties
    var user: Firebase.UserProfile? = nil
    
    // MARK: View Controller Life Cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setupView()
    }
    
    // MARK: Methods
    private func setupView() {
        if let user = self.user {
            // Viewing an external profile
            self.navigationBar.alpha = 1
            self.navigationBar.isUserInteractionEnabled = true
            
            self.profileNameLabel.text = user.information.name
            self.profileUsernameLabel.text = "@\(user.information.username)"
            
            DispatchQueue.global(qos: .userInitiated).async {
                user.fetchSessions { (sessions) in
                    self.streamCountLabel.text = "\(sessions.count)"
                    self.contentTableView.reloadData()
                }
            }
            
            let friends = user.friends
            let followerCount = friends.filter({$0.relationship == .friends || $0.relationship == .followsMe}).count
            let followingCount = friends.filter({$0.relationship == .friends || $0.relationship == .followsThem}).count
            
            self.followerCountLabel.text = "\(followerCount)"
            self.followingCountLabel.text = "\(followingCount)"
            
            self.determineFriendshipStatus() { (relationship) in
                guard let relationship = relationship else { return }
                switch relationship {
                case .notFriends:
                    self.friendshipButton.setTitle("Follow", for: .normal)
                case .followsMe:
                    self.friendshipButton.setTitle("Follow Back", for: .normal)
                case .followsThem:
                    self.friendshipButton.setTitle("Following", for: .normal)
                case .friends:
                    self.friendshipButton.setTitle("Friends", for: .normal)
                case .blocked:
                    self.friendshipButton.setTitle("User Blocked", for: .normal)
                }
            }
        } else {
            // Viewing own profile
            self.navigationBar.alpha = 0
            self.navigationBar.isUserInteractionEnabled = false
            
            self.friendshipButton.setTitle("Edit Profile", for: .normal)
            
            Firebase.shared.currentUser() { (result) in
                switch result {
                case .success(let user):
                    DispatchQueue.main.async {
                        self.profileNameLabel.text = user.publicProfile.information.name
                        self.profileUsernameLabel.text = "@\(user.publicProfile.information.username)"
                        
                        DispatchQueue.global(qos: .userInitiated).async {
                            user.publicProfile.fetchSessions { (sessions) in
                                self.streamCountLabel.text = "\(sessions.count)"
                                self.contentTableView.reloadData()
                            }
                        }
                        
                        let friends = user.publicProfile.friends
                        let followerCount = friends.filter({$0.relationship == .friends || $0.relationship == .followsMe}).count
                        let followingCount = friends.filter({$0.relationship == .friends || $0.relationship == .followsThem}).count
                        
                        self.followerCountLabel.text = "\(followerCount)"
                        self.followingCountLabel.text = "\(followingCount)"
                    }
                case .failure(let error):
                    print("[ProfileVC] Failed to fetch current user: \(error.localizedDescription)")
                }
            }
        }
        
        // Add extra scroll for mini player
        self.contentTableView.contentInset.bottom = self.view.safeAreaInsets.bottom + 80
    }
    
    private func determineFriendshipStatus(completion: @escaping(Firebase.UserRelationship.Relationship?) -> Void) {
        Firebase.shared.currentUser { (result) in
            switch result {
            case .success(let currentUser):
                
                guard let friendUser = self.user else { return }
                let currentUserFriends = currentUser.publicProfile.friends
                
                let isMyFriend = currentUserFriends.contains(where: {$0.relatedUser.identifier == friendUser.information.identifier})
                let isTheirFriend = friendUser.friends.contains(where: {$0.relatedUser.identifier == currentUser.publicProfile.information.identifier})
                
                if isMyFriend && isTheirFriend {
                    completion(.friends)
                } else if isMyFriend {
                    completion(.followsThem)
                } else if isTheirFriend {
                    completion(.followsMe)
                } else {
                    completion(.notFriends)
                }
            case .failure(_):
                return
            }
        }
    }
    
    private func updateFriendStatus() {
        self.determineFriendshipStatus { (relationship) in
            guard let relationship = relationship else { return }
            
            Firebase.shared.currentUser { (currentUserResult) in
                switch currentUserResult {
                case .success(let currentUserProfile):
                    let currentUserPublicProfile = currentUserProfile.publicProfile
                    guard let relationUserPublicProfile = self.user else { return }
                    
                    switch relationship {
                    case .notFriends, .followsThem, .followsMe:
                        // Send Friend Request / Send Again / Send Back
                        Firebase.shared.sendFriendRequest(from: currentUserPublicProfile.information, to: relationUserPublicProfile.information) { (result) in
                            switch result {
                            case .success(let newRelationship):
                                break
                            case .failure(_):
                                break
                            }
                        }
                    case .friends:
                        // Remove Friend
                        Firebase.shared.removeRelationship(between: currentUserPublicProfile.information, and: relationUserPublicProfile.information) { (result) in
                            switch result {
                            case .success(let newRelationship):
                                break
                            case .failure(_):
                                break
                            }
                        }
                        break
                    case .blocked:
                        // Block User
                        fatalError("NOT IMPLEMENTED")
                        break
                    }
                    
                case.failure(_):
                    return
                }
                
                self.friendshipButton.stopLoading()
            }
        }
    }
    
    // MARK: IBActions
    @IBAction private func dismissTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func friendshipButtonTapped(_ sender: LoadingButton) {
        if self.user != nil {
            sender.startLoading()
            self.updateFriendStatus()
        } else {
            // Edit profile
            self.performSegue(withIdentifier: "Edit Profile", sender: self)
        }
    }
    
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    /* THREE SECTIONS
     SECTION 1 - Showcase
     SECTION 2 - Recent Activity
     SECTION 3 - Friends (Icons Only)
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // TODO: Add Friend Request Row
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Music Carousel Cell", for: indexPath) as! MusicCarouselCell
        
        switch indexPath.row {
        case 0:
//            cell.setupCellWithShowcase(from: [], withHeader: "\(self.user == nil ? "Your" : "Their") Music Showcase")
            cell.setupCellWithLibraryContent(from: self.user == nil ? AppleMusicAPI.currentSession.userLibrary.recentlyPlayed : [],
                                             withHeader: "\(self.user == nil ? "Your" : "Their") Music Showcase")
        case 1:
            cell.setupCellWithSessions(from: self.user == nil ? SessionManager.current.sessionHistory : self.user?.streams ?? [],
                                       withHeader: "\(self.user == nil ? "Your" : "Their") Sessions")
        case 2:
            cell.setupCellWithFriends(from: [],
                                      withHeader: self.user == nil ? "Your Friend Activity" : "Their Friends")
        default:
            break
        }
        
        return cell
    }
    
}
