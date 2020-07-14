//
//  FriendCell.swift
//  Basement
//
//  Created by George Nick Gorzynski on 16/05/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import UIKit

class FriendCell: UITableViewCell {
    
    // MARK: Properties
    var userProfile: Firebase.UserProfile?
	
	// MARK: IBOutlets
	@IBOutlet weak private var friendImage: UIImageView!
	@IBOutlet weak private var friendName: UILabel!
	@IBOutlet weak private var friendUsername: UILabel!
	
	// MARK: Methods
	public func setupCell(from friend: Firebase.UserProfile) {
        self.userProfile = friend
        
        self.friendName.text = friend.information.name
        self.friendUsername.text = "@\(friend.information.username)"
        
//        switch friend.status {
//        case .notFriends, .followsYou:
//            self.addFriendButton.setImage(UIImage(systemName: "plus"), for: .normal)
//        case .friends, .youFollow:
//            self.addFriendButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
//        }
	}
	
}
