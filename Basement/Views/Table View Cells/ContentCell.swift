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
    
    // MARK: Override Methods
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.artwork.image = nil
    }
    
    // MARK: Methods
    public func setupCell(from data: [Music.Content]) {
        
    }
    
    // MARK: IBActions
    @IBAction private func optionsTapped(_ sender: UIButton) {
        // TOOD: Present options to user
        self.optionsPresentationDelegate?.presentOptions()
    }
    
}
