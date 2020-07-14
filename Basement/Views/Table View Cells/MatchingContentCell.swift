//
//  MatchingContentCell.swift
//  Basement
//
//  Created by George Nick Gorzynski on 21/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class MatchingContentCell: UITableViewCell {
    
    // MARK: IBOutlets
    @IBOutlet weak private var artwork: UIImageView!
    @IBOutlet weak private var title: UILabel!
    @IBOutlet weak private var subtitle: UILabel!
    @IBOutlet weak private var platform: UILabel!
    
    // MARK: Properties
    var content: Music.Content!

    // MARK: Methods
    public func setupCell(from data: Music.Content) {
        self.content = data
        
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
        if let artwork = data.streamingInformation.artwork {
            self.artwork.image = artwork.image
        }
        self.title.text = data.name
        self.subtitle.text = "\(data.artist) • \(data.album)"
        self.platform.text = "Found on \(data.streamingInformation.platform.name)"
    }
    
    /// Populator method for `Music.Playlist`
    private func setupCell(from data: Music.Playlist) {
        if let artwork = data.streamingInformation.artwork {
            self.artwork.image = artwork.image
        }
        self.title.text = data.name
        self.subtitle.text = data.contentCreator.name
        self.platform.text = "Found on \(data.streamingInformation.platform.name)"
    }
    
    /// Populator method for `Music.Album`
    private func setupCell(from data: Music.Album) {
        if let artwork = data.streamingInformation.artwork {
            self.artwork.image = artwork.image
        }
        self.title.text = data.name
        self.subtitle.text = data.artist
        self.platform.text = "Found on \(data.streamingInformation.platform.name)"
    }
    
}
