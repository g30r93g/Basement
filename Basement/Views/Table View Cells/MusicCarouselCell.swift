//
//  MusicCarouselCell.swift
//  Basement
//
//  Created by George Nick Gorzynski on 24/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class MusicCarouselCell: UITableViewCell {
    
    // MARK: Properties
    private(set) var displayType: CarouselDisplayType!
    private(set) var friends: [Firebase.UserProfile] = []
    private(set) var recentSessions: [SessionManager.MusicSession] = []
    private(set) var streamableContent: [Music.Content] = []
    public var delegate: Presentable?
    
    // MARK: IBOutlets
    @IBOutlet weak private var sectionHeaderLabel: UILabel!
    @IBOutlet weak private var carouselCollection: UICollectionView!
    
    // MARK: Methods
    public func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCollectionView), name: .imageDidLoad, object: nil)
    }
    
    public func removeNotifications() {
        NotificationCenter.default.removeObserver(self, name: .imageDidLoad, object: nil)
    }
    
    public func setupCollectionView() {
        self.carouselCollection.delegate = self
        self.carouselCollection.dataSource = self
        
        self.setupNotifications()
    }
    
     @objc public func reloadCollectionView() {
        self.carouselCollection.reloadData()
    }
    
    public func setupCellWithFriends(from data: [Firebase.UserProfile], withHeader header: String) {
        self.sectionHeaderLabel.text = header
        self.displayType = .friends
        self.friends = data
        
        self.setupCollectionView()
    }
    
    public func setupCellWithSessions(from data: [SessionManager.MusicSession], withHeader header: String) {
        self.sectionHeaderLabel.text = header
        self.displayType = .recents
        self.recentSessions = data
        
        self.setupCollectionView()
    }
    
    public func setupCellWithLibraryContent(from data: [Music.Content], withHeader header: String) {
        self.sectionHeaderLabel.text = header
        self.displayType = .streamableContent
        self.streamableContent = data
        
        self.setupCollectionView()
    }
    
//    public func setupCellWithShowcase(from data: Music.Showcase)
    
    // MARK: Enums
    public enum CarouselDisplayType {
        case friends
        case recents
        case streamableContent
    }
    
}

extension MusicCarouselCell: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch self.displayType {
        case .friends:
            return self.friends.count
        case .recents:
            return self.recentSessions.count
        case .streamableContent:
            return self.streamableContent.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch self.displayType {
        case .friends:
            // Setup friends cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "User", for: indexPath) as! FriendCollectionCell
            
            let data = self.friends[indexPath.item]
            cell.setupCell(from: data)
            
            return cell
        case .recents:
            // Setup recentSession cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MusicContent", for: indexPath) as! MusicContentCell
            
            let data = self.recentSessions[indexPath.item]
            cell.setupCell(from: data)
            
            return cell
        case .streamableContent:
            // Setup streamingLibrary cell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MusicContent", for: indexPath) as! MusicContentCell
            
            let playlist = self.streamableContent[indexPath.item]
            cell.setupCell(from: playlist)
            
            
            return cell
        default:
            break
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        switch self.displayType {
        case .friends:
            let selectedUser = self.friends[indexPath.item]
            delegate?.presentUserVC(selectedUser)
        case .recents:
            let recentSession = self.recentSessions[indexPath.item]
            
        case .streamableContent:
            if let content = self.streamableContent[indexPath.item] as? Music.ContentContainer {
                delegate?.presentContentVC(content)
            }
        default:
            break
        }
    }
    
}
