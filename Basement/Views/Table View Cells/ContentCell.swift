//
//  ContentCell.swift
//  Basement
//
//  Created by George Nick Gorzynski on 14/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class ContentCell: UITableViewCell {
    
    // MARK: IBOutlet
    @IBOutlet weak private var artwork: UIImageView!
    @IBOutlet weak private var title: UILabel!
    @IBOutlet weak private var subtitle: UILabel!
    @IBOutlet weak private var options: UIButton?
    
    // MARK: Properties
    var optionsPresentationDelegate: PresentableOptions? = nil
    var musicContent: Music.Content?
    
    // MARK: Methods
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
        if let artwork = data.streamingInformation.artwork {
            self.artwork.image = artwork.image
        } else if let artworkURL = data.streamingInformation.artworkURL {
            self.artwork.load(url: artworkURL, shouldNotify: true)
        }
        
        self.title.text = data.name
        self.subtitle.text = "\(data.artist) • \(data.streamingInformation.platform.name)"
    }
    
    /// Populator method for `Music.Playlist`
    private func setupCell(from data: Music.Playlist) {
        if let artwork = data.streamingInformation.artwork {
            self.artwork.image = artwork.image
        } else if let artworkURL = data.streamingInformation.artworkURL {
            self.artwork.load(url: artworkURL, shouldNotify: true)
        }
        
        self.title.text = data.name
        self.subtitle.text = "Playlist from \(data.streamingInformation.platform.name)"
    }
    
    /// Populator method for `Music.Album`
    private func setupCell(from data: Music.Album) {
        if let artwork = data.streamingInformation.artwork {
            self.artwork.image = artwork.image
        } else if let artworkURL = data.streamingInformation.artworkURL {
            self.artwork.load(url: artworkURL, shouldNotify: true)
        }
        
        self.title.text = data.name
        self.subtitle.text = "\(data.artist) • Album from \(data.streamingInformation.platform.name)"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.artwork.image = nil
    }
    
    // MARK: IBActions
    @IBAction private func optionsTapped(_ sender: UIButton) {
        // TOOD: Present options to user
        
    }
    
}
