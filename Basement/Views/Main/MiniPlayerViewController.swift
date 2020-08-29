//
//  MiniPlayerViewController.swift
//  Basement
//
//  Created by George Nick Gorzynski on 22/08/2020.
//

import UIKit

class MiniPlayerViewController: UIViewController {

    // MARK: IBOutlets
    @IBOutlet weak private var artwork: UIImageView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var subtitleLabel: UILabel!
    @IBOutlet weak private var playPauseButton: RoundButton!
    
    // MARK: Properties
    
    // MARK: View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupView()
    }
    
    // MARK: Methods
    private func setupView() {
        
    }
    
    // MARK: IBActions
    @IBAction private func playPauseButtonTapped(_ sender: RoundButton) {
//        PlaybackManager.current.togglePlayPause()
    }

}
