//
//  SetupVibeConstraintsViewController.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 21/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

protocol SelectedFriendsFeedback {
    func friendsSelected(_ friends: [Firebase.UserProfile])
}

class SetupVibeConstraintsViewController: UIViewController {
    
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
        
        if let setup = VibeManager.current.currentVibeSetup {
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
            self.privacySegmentDescriptor.text = "Anyone who sees your profile is able to join this vibe."
            VibeManager.current.currentVibeSetup?.updatePrivacy(to: .Public)
           
            UIView.animate(withDuration: 0.4) {
                self.friendsCollectionViewHeight.constant = 0
            }
        case 1:
            // Friends
            self.privacySegmentDescriptor.text = "Anyone who is friends with you will be able to join this vibe."
            VibeManager.current.currentVibeSetup?.updatePrivacy(to: .Friends)
            
            UIView.animate(withDuration: 0.4) {
                self.friendsCollectionViewHeight.constant = 200
            }
        case 2:
            // Invite Only
            self.privacySegmentDescriptor.text = "Only people you invite will be able join this vibe."
            VibeManager.current.currentVibeSetup?.updatePrivacy(to: .InviteOnly)
            
            UIView.animate(withDuration: 0.4) {
                self.friendsCollectionViewHeight.constant = 200
            }
        case 3:
            self.privacySegmentDescriptor.text = "Only people you invite will be able to join this vibe. They can also request to add content to the queue."
            VibeManager.current.currentVibeSetup?.updatePrivacy(to: .Party)
            
            UIView.animate(withDuration: 0.4) {
                self.friendsCollectionViewHeight.constant = 200
            }
            break
        default:
            return
        }
    }
    
    private func completeVibeSetup(completion: @escaping(Bool) -> Void) {
        VibeManager.current.createVibe() { (result) in
            switch result {
            case .success(let vibe):
                print("[SetupViewConstraintsVC] Vibe setup complete! (Vibe identifier: \(vibe.details.identifier))")
            case .failure(let error):
                print("[SetupViewConstraintsVC] Vibe setup failed! \(error)")
            }
        }
    }
    
    private func errorCreatingVibe() {
        let alert = UIAlertController(title: "Could not setup vibe", message: "Please check your internet connection and your vibe parameters.", preferredStyle: .alert)
        
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
        if (VibeManager.current.currentVibeSetup?.content.isEmpty ?? false) || (VibeManager.current.currentVibeSetup?.friendsToNotify.isEmpty ?? false) { return }
        
        sender.startLoading()
        
        self.completeVibeSetup { (success) in
            sender.stopLoading()
            success ? self.dismiss(animated: true) : self.errorCreatingVibe()
        }
    }
    
}

extension SetupVibeConstraintsViewController: SelectedFriendsFeedback {
    
    func friendsSelected(_ friends: [Firebase.UserProfile]) {
        friends.forEach({self.selectedFriends.append($0)})
    }
    
}

extension SetupVibeConstraintsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
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
