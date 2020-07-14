//
//  SetupSessionConstraintsViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 21/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

protocol SelectedFriendsFeedback {
    func friendsSelected(_ friends: [Firebase.UserProfile])
}

class SetupSessionConstraintsViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet weak private var numberOfSelectedSongs: UILabel!
    
    @IBOutlet weak private var privacySegment: UISegmentedControl!
    @IBOutlet weak private var privacySegmentDescriptor: UILabel!
    
    @IBOutlet weak private var friendsCollectionView: UICollectionView!
    @IBOutlet weak private var friendsCollectionViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak private var confirm: LoadingButton!
    
    // MARK: Properties
    var selectedContent: [Music.Content]!
    private(set) var selectedFriends: [Firebase.UserProfile] = [] {
        didSet {
            DispatchQueue.main.async {
                self.friendsCollectionView.reloadData()
            }
        }
    }

    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.updateSegment()
        
        if let setup = SessionManager.current.setup {
            self.numberOfSelectedSongs.text = "\(setup.content.count) songs selected"
        } else {
            self.numberOfSelectedSongs.text = ""
        }
    }
    
    // MARK: Methods
    private func updateSegment() {
        switch self.privacySegment.selectedSegmentIndex {
        case 0:
            // Public
            self.privacySegmentDescriptor.text = "Anyone who sees your profile is able to join this session."
            SessionManager.current.setup?.updatePrivacy(to: .public)
           
            UIView.animate(withDuration: 0.4) {
                self.friendsCollectionViewHeight.constant = 0
            }
        case 1:
            // Friends
            self.privacySegmentDescriptor.text = "Anyone who is friends with you will be able to join this session."
            SessionManager.current.setup?.updatePrivacy(to: .friends)
            
            UIView.animate(withDuration: 0.4) {
                self.friendsCollectionViewHeight.constant = 200
            }
        case 2:
            // Invite Only
            self.privacySegmentDescriptor.text = "Only people you invite will be able join this session."
            SessionManager.current.setup?.updatePrivacy(to: .inviteOnly)
            
            UIView.animate(withDuration: 0.4) {
                self.friendsCollectionViewHeight.constant = 200
            }
        case 3:
            self.privacySegmentDescriptor.text = "Only people you invite will be able to join this session. They can also request to add content to the queue."
            SessionManager.current.setup?.updatePrivacy(to: .party)
            
            UIView.animate(withDuration: 0.4) {
                self.friendsCollectionViewHeight.constant = 200
            }
            break
        default:
            return
        }
    }
    
    private func completeVibeSetup(completion: @escaping(Bool) -> Void) {
        SessionManager.current.createSession() { (result) in
            switch result {
            case .success(let vibe):
                print("[SetupSessionConstraintsVC] Session setup complete! (Identifier: \(vibe.details.identifier))")
                completion(true)
            case .failure(let error):
                print("[SetupSessionConstraintsVC] Session setup failed! \(error)")
                completion(false)
            }
        }
    }
    
    private func errorCreatingVibe() {
        let alert = UIAlertController(title: "Could not setup session", message: "Please check your internet connection and content availability.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Choose Friends" {
            let destVC = segue.destination as! ChooseFriendsViewController
            
            destVC.feedbackDelegate = self
        }
    }
    
    // MARK: IBActions
    @IBAction private func backTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func privacySegmentValueChanged(_ sender: UIButton) {
        self.updateSegment()
    }
    
    @IBAction private func confirmButtonTapped(_ sender: LoadingButton) {
        guard let setup = SessionManager.current.setup else { return }
        if setup.content.isEmpty || (setup.friendsToNotify.isEmpty && setup.privacy != .public) { return }
        
        sender.startLoading()
        
        self.completeVibeSetup { (success) in
            sender.stopLoading()
            success ? self.dismiss(animated: true) : self.errorCreatingVibe()
        }
    }
    
}

extension SetupSessionConstraintsViewController: SelectedFriendsFeedback {
    
    func friendsSelected(_ friends: [Firebase.UserProfile]) {
        friends.forEach({self.selectedFriends.append($0)})
    }
    
}

extension SetupSessionConstraintsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedFriends.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == self.selectedFriends.count {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Add Friend", for: indexPath) as! AddContentCell
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Friend", for: indexPath) as! FriendCollectionCell
            let data = self.selectedFriends[indexPath.item]
            
            cell.setupCell(from: data)
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if indexPath.item == self.selectedFriends.count {
            self.performSegue(withIdentifier: "Choose Friends", sender: self)
        }
    }
    
}
