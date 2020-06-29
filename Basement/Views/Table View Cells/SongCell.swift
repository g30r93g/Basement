//
//  SongCell.swift
//  Vibe
//
//  Created by George Nick Gorzynski on 14/06/2020.
//  Copyright © 2020 George Nick Gorzynski. All rights reserved.
//

import UIKit

class SongCell: UITableViewCell {
    
    // MARK: IBOutlet
    @IBOutlet weak private var artwork: UIImageView!
    @IBOutlet weak private var title: UILabel!
    @IBOutlet weak private var subtitle: UILabel!
    @IBOutlet weak private var options: UIButton!
    
    // MARK: Methods
    func setupCell(from song: Music.Song) {
        
        self.title.text = song.name
        self.subtitle.text = "\(song.artist) • \(song.streamingInformation.platform.name)"
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
