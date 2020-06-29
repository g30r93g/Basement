//
//  FriendCell.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 16/05/2020.
//  Copyright © 2020 g30r93g. All rights reserved.
//

import UIKit

class FriendCell: UITableViewCell {
    
    // MARK: Properties
    private var username: String!
	
	// MARK: IBOutlets
	@IBOutlet weak private var friendImage: UIImageView!
	@IBOutlet weak private var friendName: UILabel!
	@IBOutlet weak private var friendUsername: UILabel!
	
	// MARK: Methods
	public func setupCell(from friend: Firebase.UserProfile) {
        self.username = friend.username
        
		self.friendName.text = friend.name
        self.friendUsername.text = "@\(friend.username)"
        
//        switch friend.status {
//        case .notFriends, .followsYou:
//            self.addFriendButton.setImage(UIImage(systemName: "plus"), for: .normal)
//        case .friends, .youFollow:
//            self.addFriendButton.setImage(UIImage(systemName: "checkmark"), for: .normal)
//        }
	}
	
}
