//
//  ContentCell.swift
//  Basement
//
//  Created by George Nick Gorzynski on 14/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit
import SDWebImage

class ContentCell: UITableViewCell {
    
    // MARK: IBOutlet
    @IBOutlet weak private var artwork: UIImageView!
    @IBOutlet weak private var title: UILabel!
    @IBOutlet weak private var subtitle: UILabel!
    
    
    // MARK: Properties
    var musicContent: Music.Content?
    
    // MARK: Override Methods
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.artwork.image = nil
        self.deselect()
    }
    
    // MARK: Methods
    public func setupCell(from data: Music.Content) {
        self.musicContent = data
        
        self.artwork.sd_setImage(with: data.streamingInformation.artworkURL, placeholderImage: nil, options: [])
        self.title.text = data.name
        
        if let song = data as? Music.Song {
            self.subtitle.text = "\(song.artist) • \(song.album)"
        } else if let album = data as? Music.Album {
            self.subtitle.text = "\(album.artist)"
        }
    }
    
    public func select() {
        self.accessoryType = .checkmark
    }
    
    public func deselect() {
        self.accessoryType = .none
    }
    
}
