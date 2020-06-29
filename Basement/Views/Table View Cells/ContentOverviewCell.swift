//
//  ContentOverviewCell.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 16/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class ContentOverviewCell: UITableViewCell {
    
    // MARK: IBOutlets
    @IBOutlet weak private var artworkBackground: UIImageView!
    @IBOutlet weak private var artwork: UIImageView!
    @IBOutlet weak private var title: UILabel!
    @IBOutlet weak private var subtitle: UILabel!
    @IBOutlet weak private var playContent: UIButton!
    @IBOutlet weak private var addToLibrary: UIButton!
    
    // MARK: Properties
    private var content: Music.Content? = nil
    
    // MARK: Methods
    func setupCell(from data: Music.ContentContainer) {
        self.content = data
        
        self.artworkBackground.image = data.streamingInformation.artwork?.image
        self.artwork.image = data.streamingInformation.artwork?.image
        self.title.text = data.name
        
        if let album = data as? Music.Album {
            self.subtitle.text = "\(album.artist) • \(data.streamingInformation.platform.name)"
        } else if let playlist = data as? Music.Playlist {
            let isLibrary = playlist.contentCreator.isLibrary
            let isUserCreated = playlist.contentCreator != .me
            
            self.subtitle.text = "Playlist\(isUserCreated ? " by \(playlist.contentCreator.name)" : "") from \(data.streamingInformation.platform.name) \(isLibrary ? "Library" : "")".trimmingCharacters(in: .whitespaces)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.content = nil
    }
    
    // MARK: IBActions
    @IBAction private func playContentTapped(_ sender: UIButton) {
        
    }
    
    @IBAction private func addToLibraryTapped(_ sender: UIButton) {
        
    }
    
}
