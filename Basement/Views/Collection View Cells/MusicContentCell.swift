//
//  MusicContentCell.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 24/05/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class MusicContentCell: RoundUICollectionViewCell {
    
    // MARK: IBOutlets
    @IBOutlet weak private var artwork: UIImageView!
    @IBOutlet weak private var header: UILabel!
    @IBOutlet weak private var subtext: UILabel!
    
    // MARK: Methods
    public func setupCell(from data: Music.Content) {
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
        self.header.text = data.name
        self.subtext.text = "\(data.artist) • \(data.album)"
    }
    
    /// Populator method for `Music.Playlist`
    private func setupCell(from data: Music.Playlist) {
        if let artwork = data.streamingInformation.artwork {
            self.artwork.image = artwork.image
        }
        self.header.text = data.name
        self.subtext.text = ""
    }
    
    /// Populator method for `Music.Album`
    private func setupCell(from data: Music.Album) {
        if let artwork = data.streamingInformation.artwork {
            self.artwork.image = artwork.image
        }
        self.header.text = data.name
        self.subtext.text = data.artist
    }
    
    /// Populator method for `Account.Vibe `
    public func setupCell(from data: VibeManager.Vibe) {
//        if let artworkURL = data.artwork {
//            self.artwork.load(url: artworkURL)
//        }
//        self.header.text = data.name
//        self.subtext.text = data.startTime.stringFormat()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.artwork.image = nil
    }
    
}
