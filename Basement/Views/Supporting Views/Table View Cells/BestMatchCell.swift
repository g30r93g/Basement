//
//  BestMatchCell.swift
//  Basement
//
//  Created by George Nick Gorzynski on 07/07/2020.
//

import UIKit

class BestMatchCell: UITableViewCell {
    
    // MARK: IBOutlets
    @IBOutlet weak private var backgroundArtwork: UIImageView!
    @IBOutlet weak private var artwork: RoundImageView!
    @IBOutlet weak private var title: UILabel!
    @IBOutlet weak private var subtitle: UILabel!
    @IBOutlet weak private var platform: UILabel!
    
    // MARK: Properties
    var musicContent: Music.Content?
    var userProfile: Firebase.UserProfile?
    
    // MARK: Methods
    /// Populator method for `Music.Content`
    public func setupCell(from data: Music.Content) {
        self.musicContent = data
        
        if let song = data as? Music.Song {
            self.setupCell(from: song)
        } else if let playlist = data as? Music.Playlist {
            self.setupCell(from: playlist)
        } else if let album = data as? Music.Album {
            self.setupCell(from: album)
        }
    }
    
    /// Populator method for `Music.Song`
    private func setupCell(from data: Music.Song) {
        self.loadArtwork(from: data.streamingInformation)
        
        self.title.text = data.name
        self.subtitle.text = "Song by \(data.artist)"
        self.platform.text = "Available on \(data.streamingInformation.platform.name)"
    }
    
    /// Populator method for `Music.Playlist`
    private func setupCell(from data: Music.Playlist) {
        self.loadArtwork(from: data.streamingInformation)
        
        self.title.text = data.name
        self.subtitle.text = "Playlist"
        self.platform.text = "Available exclusively on \(data.streamingInformation.platform.name)"
    }
    
    /// Populator method for `Music.Album`
    private func setupCell(from data: Music.Album) {
        self.loadArtwork(from: data.streamingInformation)
        
        self.title.text = data.name
        self.subtitle.text = "Album by \(data.artist)"
        self.platform.text = "Available on \(data.streamingInformation.platform.name)"
    }
    
    private func loadArtwork(from streamingInformation: Music.StreamingInfo) {
        if let artwork = streamingInformation.artwork {
            self.artwork.image = artwork.image
            self.backgroundArtwork.image = artwork.image
        } else if let artworkURL = streamingInformation.artworkURL {
            self.artwork.load(url: artworkURL, shouldNotify: true)
            self.backgroundArtwork.load(url: artworkURL, shouldNotify: true)
        }
    }
    
    /// Populator method for `Firebase.UserProfile`
    func setupCell(from data: Firebase.UserProfile) {
        self.userProfile = data
        
        self.artwork.cornerRadius = self.artwork.frame.width / 2
//        self.artwork.load(url: data.information.userProfileURL, shouldNotify: true)
        
        self.title.text = data.information.name
        self.subtitle.text = "@\(data.information.username)"
        self.platform.text = ""
    }
    
}
