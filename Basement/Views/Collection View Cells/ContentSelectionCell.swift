//
//  ContentSelectionCell.swift
//  Basement
//
//  Created by George Nick Gorzynski on 21/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

protocol ContentOptionsPresenter {
    
    func presentOptions(for content: Music.Content, at index: Int)
    
}

class ContentSelectionCell: RoundUICollectionViewCell {
    
    // MARK: IBOutlets
    @IBOutlet weak private var artwork: UIImageView!
    @IBOutlet weak private var title: UILabel!
    @IBOutlet weak private var subtitle: UILabel!
    @IBOutlet weak private var platforms: UILabel!
    @IBOutlet weak private var options: UIButton!
    
    // MARK: Properties
    public var optionsDelegate: ContentOptionsPresenter? = nil
    private var musicContent: Music.Content!
    private var index: Int!
    
    // MARK: Methods
    public func setupCell(from data: Music.Content, index: Int) {
        self.index = index
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
        }
        self.title.text = data.name
        self.subtitle.text = "\(data.artist) • \(data.album)"
        self.platforms.text = "Available on \(data.streamingInformation.platform.name)"
    }
    
    /// Populator method for `Music.Playlist`
    private func setupCell(from data: Music.Playlist) {
        if let artwork = data.streamingInformation.artwork {
            self.artwork.image = artwork.image
        }
        self.title.text = data.name
        self.subtitle.text = data.contentCreator.name
        self.platforms.text = "Available on \(data.streamingInformation.platform.name)"
    }
    
    /// Populator method for `Music.Album`
    private func setupCell(from data: Music.Album) {
        if let artwork = data.streamingInformation.artwork {
            self.artwork.image = artwork.image
        }
        self.title.text = data.name
        self.subtitle.text = data.artist
        self.platforms.text = "Available on \(data.streamingInformation.platform.name)"
    }
    
    @IBAction private func optionsTapped(_ sender: UIButton) {
        self.optionsDelegate?.presentOptions(for: self.musicContent, at: self.index)
    }
    
}
