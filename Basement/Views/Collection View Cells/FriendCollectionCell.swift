//
//  FriendCollectionCell.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 24/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class FriendCollectionCell: RoundUICollectionViewCell {
    
    // MARK: IBOutlets
    @IBOutlet weak private var activeVibeIcon: UIImageView!
    @IBOutlet weak private var profilePicture: UIImageView!
    @IBOutlet weak private var username: UILabel!
    @IBOutlet weak private var vibeDetails: UILabel!
    
    // MARK: Methods
    public func setupCell(from data: Firebase.UserProfile) {
        self.username.text = "@\(data.username)"
        
//        self.activeVibeIcon.alpha = data.currentVibe != nil ? 1 : 0
//        if let currentVibe = data.currentVibe {
//            self.vibeDetails.text = "\(currentVibe.songName) • \(currentVibe.artist)"
//        }
    }
    
}
